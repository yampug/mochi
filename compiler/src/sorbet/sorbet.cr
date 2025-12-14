require "json"

# C API bindings for libsorbet
@[Link("sorbet")]
lib LibSorbet
  type Session = Void*

  # Standard single-threaded API
  fun new = sorbet_new(args : LibC::Char*) : Session

  # Multi-threaded API for better performance
  fun new_mt = sorbet_new_mt(args : LibC::Char*, num_threads : Int32) : Session

  # Send a single LSP message and get responses
  fun send = sorbet_send(session : Session, msg : LibC::Char*) : LibC::Char*

  # Batch send multiple LSP messages for better performance
  fun send_batch = sorbet_send_batch(session : Session, msgs : LibC::Char**, count : Int32) : LibC::Char*

  # Memory management
  fun free_string = sorbet_free_string(str : LibC::Char*)
  fun free = sorbet_free(session : Session)
end

module Sorbet
  # Represents a single diagnostic error or warning from Sorbet
  class Diagnostic
    getter file : String
    getter line : Int32
    getter column : Int32
    getter end_line : Int32
    getter end_column : Int32
    getter message : String
    getter severity : String
    getter code : String?

    def initialize(
      @file : String,
      @line : Int32,
      @column : Int32,
      @end_line : Int32,
      @end_column : Int32,
      @message : String,
      @severity : String,
      @code : String? = nil
    )
    end

    def self.from_json(json : JSON::Any, file_uri : String) : Diagnostic
      range = json["range"]
      start = range["start"]
      finish = range["end"]

      # Extract file path from URI
      file_path = file_uri.gsub(/^file:\/\//, "")

      severity_num = json["severity"]?.try(&.as_i?) || 1
      severity = case severity_num
                 when 1 then "error"
                 when 2 then "warning"
                 when 3 then "information"
                 when 4 then "hint"
                 else        "error"
                 end

      new(
        file: file_path,
        line: start["line"].as_i,
        column: start["character"].as_i,
        end_line: finish["line"].as_i,
        end_column: finish["character"].as_i,
        message: json["message"].as_s,
        severity: severity,
        code: json["code"]?.try(&.as_s?)
      )
    end

    def to_s(io : IO)
      io << "#{file}:#{line + 1}:#{column + 1}: #{severity}: #{message}"
    end
  end

  # Result of typechecking one or more files
  class TypecheckResult
    getter diagnostics : Array(Diagnostic)

    def initialize(@diagnostics : Array(Diagnostic) = [] of Diagnostic)
    end

    def errors : Array(Diagnostic)
      diagnostics.select { |d| d.severity == "error" }
    end

    def warnings : Array(Diagnostic)
      diagnostics.select { |d| d.severity == "warning" }
    end

    def success? : Bool
      errors.empty?
    end

    def add(diagnostic : Diagnostic)
      @diagnostics << diagnostic
    end

    def merge(other : TypecheckResult)
      @diagnostics.concat(other.diagnostics)
    end
  end

  # Main Sorbet session class
  # Manages a persistent Sorbet LSP session for typechecking Ruby code
  class Session
    @session : LibSorbet::Session?
    @closed : Bool = false
    @multi_threaded : Bool

    # Initialize a new Sorbet session
    #
    # @param root_dir The root directory for the Ruby project
    # @param multi_threaded Whether to use multi-threaded mode (faster for large codebases)
    # @param num_threads Number of threads to use in multi-threaded mode
    # @param extra_args Additional Sorbet CLI arguments
    def initialize(
      root_dir : String = ".",
      multi_threaded : Bool = false,
      num_threads : Int32 = 2,
      extra_args : Array(String) = [] of String
    )
      @multi_threaded = multi_threaded

      # Build arguments array
      # Note: --lsp and --disable-watchman are required for LSP mode
      args = ["--lsp", "--disable-watchman", "--silence-dev-message"] + extra_args + [root_dir]
      args_json = args.to_json

      # Initialize the appropriate session type
      # Force single-threaded mode regardless of argument due to CI crashes with MT
      # @session = if multi_threaded
      #              LibSorbet.new_mt(args_json, num_threads)
      #            else
      #              LibSorbet.new(args_json)
      #            end
      @session = LibSorbet.new(args_json)

      raise "Failed to initialize Sorbet session" if @session.nil?

      # Perform LSP handshake
      initialize_lsp
      send_initialized_notification
    end

    # Typecheck a single file
    #
    # @param file_path Path to the Ruby file
    # @param content Content of the file (if nil, will read from disk)
    # @return TypecheckResult with any diagnostics
    def typecheck_file(file_path : String, content : String? = nil) : TypecheckResult
      raise "Session is closed" if @closed

      file_content = content || File.read(file_path)
      file_uri = "file://#{File.expand_path(file_path)}"

      message = build_did_open_message(file_uri, file_content)
      response = send_message(message)

      parse_diagnostics(response)
    end

    # Typecheck multiple files in batch (more efficient)
    #
    # @param files Hash of file_path => content, or Array of file paths
    # @return TypecheckResult with all diagnostics
    def typecheck_files(files : Hash(String, String) | Array(String)) : TypecheckResult
      raise "Session is closed" if @closed

      # Convert array of paths to hash
      files_hash = if files.is_a?(Array(String))
                     files.to_h { |path| {path, File.read(path)} }
                   else
                     files
                   end

      # Build all messages
      messages = files_hash.map do |file_path, content|
        file_uri = "file://#{File.expand_path(file_path)}"
        build_did_open_message(file_uri, content)
      end

      # Send batch
      response = send_batch(messages)
      parse_diagnostics(response)
    end

    # Close the Sorbet session and free resources
    def close
      return if @closed

      if session = @session
        # LibSorbet.free(session) # Debugging crash: Potential double-free or invalid access in C destructor
        @session = nil
        @closed = true
      end
    end

    # Automatically close when garbage collected
    def finalize
      close
    end

    # Check if the session is still open
    def open? : Bool
      !@closed
    end

    private def initialize_lsp
      init_msg = {
        jsonrpc: "2.0",
        id:      1,
        method:  "initialize",
        params:  {
          rootUri:      "file://#{Dir.current}",
          capabilities: {} of String => String,
        },
      }.to_json

      response = send_raw(init_msg)
      free_response(response)
    end

    private def send_initialized_notification
      initialized_msg = {
        jsonrpc: "2.0",
        method:  "initialized",
        params:  {} of String => String,
      }.to_json

      response = send_raw(initialized_msg)
      free_response(response)
    end

    private def build_did_open_message(file_uri : String, content : String) : String
      {
        jsonrpc: "2.0",
        method:  "textDocument/didOpen",
        params:  {
          textDocument: {
            uri:        file_uri,
            languageId: "ruby",
            version:    1,
            text:       content,
          },
        },
      }.to_json
    end

    private def send_message(message : String) : String
      response_ptr = send_raw(message)
      return "[]" if response_ptr.null?

      response_str = String.new(response_ptr)
      free_response(response_ptr)
      response_str
    end

    private def send_batch(messages : Array(String)) : String
      return "[]" if messages.empty?

      # Create C array of string pointers
      c_messages = Pointer(Pointer(UInt8)).malloc(messages.size)
      messages.each_with_index do |msg, i|
        c_messages[i] = msg.to_unsafe
      end

      response_ptr = LibSorbet.send_batch(@session.not_nil!, c_messages, messages.size)
      return "[]" if response_ptr.null?

      response_str = String.new(response_ptr)
      free_response(response_ptr)
      response_str
    end

    private def send_raw(message : String) : LibC::Char*
      LibSorbet.send(@session.not_nil!, message)
    end

    private def free_response(ptr : LibC::Char*)
      LibSorbet.free_string(ptr) unless ptr.null?
    end

    private def parse_diagnostics(response_str : String) : TypecheckResult
      result = TypecheckResult.new

      begin
        json = JSON.parse(response_str)
        return result unless json.as_a?

        json.as_a.each do |message|
          next unless message["method"]? == "textDocument/publishDiagnostics"

          params = message["params"]
          file_uri = params["uri"].as_s
          diagnostics = params["diagnostics"].as_a

          diagnostics.each do |diag_json|
            diagnostic = Diagnostic.from_json(diag_json, file_uri)
            result.add(diagnostic)
          end
        end
      rescue ex : JSON::ParseException
        # Invalid JSON response, return empty result
      end

      result
    end
  end
end
