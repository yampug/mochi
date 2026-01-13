require "spec"
require "../../fragments/vendor/libpftrace/bindings/crystal/src/pftrace"

describe "Pftrace Integration" do
  it "creates a comprehensive trace file with all features" do
    trace_file = "mochi_trace_test.pftrace"
    File.delete(trace_file) if File.exists?(trace_file)

    Pftrace.open(trace_file) do |trace|
      trace.write_clock_snapshot(1_000_000_000_u64)

      trace.write_process_descriptor(pid: 1234, name: "MochiCompiler", uuid: 100_u64)
      trace.write_thread_descriptor(pid: 1234, tid: 5678, name: "ParserThread", uuid: 101_u64, parent_uuid: 100_u64)
      trace.write_thread_descriptor(pid: 1234, tid: 5679, name: "CodegenThread", uuid: 102_u64, parent_uuid: 100_u64)

      trace.trace("CompilePhase", type: Pftrace::EventType::SliceBegin, track_uuid: 101_u64, timestamp: 1_000_001_000_u64, trusted_packet_sequence_id: 1_u32) do |ev|
        ev.category = "compilation"
        ev.arg("file", "main.rb")
        ev.arg("lines", 1250)
        ev.arg("optimized", true)
        ev.arg("parse_time_ms", 45.67)
        ev.flow_begin(99_u64)
        ev.task_execution("compiler.cr", "compile_file", 42)
      end

      trace.trace("ParseAST", type: Pftrace::EventType::SliceBegin, track_uuid: 101_u64, timestamp: 1_000_002_000_u64, trusted_packet_sequence_id: 1_u32) do |ev|
        ev.category = "parser"
        ev.log_message = "Starting AST parsing"
        ev.arg("node_count", 0)
      end

      trace.trace("ParseAST", type: Pftrace::EventType::SliceEnd, track_uuid: 101_u64, timestamp: 1_000_015_000_u64, trusted_packet_sequence_id: 1_u32) do |ev|
        ev.arg("node_count", 347)
      end

      trace.trace("MemoryUsage", type: Pftrace::EventType::Counter, track_uuid: 101_u64, timestamp: 1_000_020_000_u64, trusted_packet_sequence_id: 1_u32) do |ev|
        ev.counter = 1024_i64 * 1024 * 128
      end

      trace.trace("CodegenPhase", type: Pftrace::EventType::SliceBegin, track_uuid: 102_u64, timestamp: 1_000_025_000_u64, trusted_packet_sequence_id: 2_u32) do |ev|
        ev.category = "codegen"
        ev.flow_end(99_u64)
        ev.arg("target", "quickjs")
        ev.arg("output_size_kb", 256)
      end

      trace.trace("CodegenPhase", type: Pftrace::EventType::SliceEnd, track_uuid: 102_u64, timestamp: 1_000_045_000_u64, trusted_packet_sequence_id: 2_u32) do |ev|
      end

      trace.trace("Checkpoint", type: Pftrace::EventType::Instant, track_uuid: 101_u64, timestamp: 1_000_050_000_u64, trusted_packet_sequence_id: 1_u32) do |ev|
        ev.category = "milestone"
        ev.log_message = "Compilation complete"
      end

      trace.trace("CompilePhase", type: Pftrace::EventType::SliceEnd, track_uuid: 101_u64, timestamp: 1_000_055_000_u64, trusted_packet_sequence_id: 1_u32) do |ev|
      end
    end

    File.exists?(trace_file).should be_true
    File.size(trace_file).should be > 0

    puts "Generated #{trace_file} (#{File.size(trace_file)} bytes)"
    puts "Trace includes:"
    puts "  - Process and thread descriptors"
    puts "  - Slice events with begin/end"
    puts "  - Counter events"
    puts "  - Instant events"
    puts "  - Flow tracking across threads"
    puts "  - Arguments (string, int, bool, double)"
    puts "  - Task execution metadata"
    puts "  - Log messages"
  end

  it "handles multiple trace contexts correctly" do
    trace1 = "trace1.pftrace"
    trace2 = "trace2.pftrace"

    File.delete(trace1) if File.exists?(trace1)
    File.delete(trace2) if File.exists?(trace2)

    Pftrace.open(trace1) do |t1|
      t1.write_clock_snapshot(1_000_000_000_u64)
      t1.write_process_descriptor(100, "Process1")
      t1.trace("Event1", type: Pftrace::EventType::Instant, track_uuid: 100_u64, timestamp: 1_000_001_000_u64, trusted_packet_sequence_id: 1_u32) do |ev|
        ev.arg("source", "trace1")
      end
    end

    Pftrace.open(trace2) do |t2|
      t2.write_clock_snapshot(1_000_000_000_u64)
      t2.write_process_descriptor(200, "Process2")
      t2.trace("Event2", type: Pftrace::EventType::Instant, track_uuid: 200_u64, timestamp: 1_000_001_000_u64, trusted_packet_sequence_id: 1_u32) do |ev|
        ev.arg("source", "trace2")
      end
    end

    File.exists?(trace1).should be_true
    File.exists?(trace2).should be_true
    File.size(trace1).should be > 0
    File.size(trace2).should be > 0
  end

  it "properly handles all argument types" do
    trace_file = "args_test.pftrace"
    File.delete(trace_file) if File.exists?(trace_file)

    Pftrace.open(trace_file) do |trace|
      trace.write_clock_snapshot(1_000_000_000_u64)
      trace.write_process_descriptor(100, "ArgTest")

      trace.trace("AllArgs", type: Pftrace::EventType::Instant, track_uuid: 100_u64, timestamp: 1_000_001_000_u64, trusted_packet_sequence_id: 1_u32) do |ev|
        ev.arg("string_arg", "hello world")
        ev.arg("int_arg", 42_i64)
        ev.arg("uint_arg", 18446744073709551615_u64)
        ev.arg("float_arg", 3.14159)
        ev.arg("bool_true", true)
        ev.arg("bool_false", false)
        ev.arg_ptr("ptr_arg", 0xDEADBEEF_u64)
      end
    end

    File.exists?(trace_file).should be_true
  end
end
