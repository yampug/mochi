require "./ruby_var"
require "./ruby_script_engine"

class RubyUnderstander

    def self.extract_raw_string_from_def_body(body : Array(String), name : String) : String?
        # remove first line (def ...) and last line (end)
        inner_body = body[1...body.size - 1]
          .join("\n")
          .strip
          .gsub("\t", "")
          .gsub("  ", " ")
      
          #puts "inner:'#{inner_body}'"
        if inner_body.starts_with?("%Q{") && inner_body.ends_with?("}")
          #puts "case 1 #{name}"
          return inner_body[3, inner_body.size - 4].strip
        elsif inner_body.starts_with?("%q{") && inner_body.ends_with?("}")
          #puts "case 2"
          return inner_body[3, inner_body.size - 4].strip
        elsif inner_body.starts_with?("\"") && inner_body.ends_with?("\"")
         # puts "case 3"
          return inner_body[1, inner_body.size - 1].strip
        elsif inner_body.starts_with?("'") && inner_body.ends_with?("'")
          #puts "case 4"
          return inner_body[1, inner_body.size - 1].strip
        end
        return inner_body
    end
      
    def self.class_name(rb_file : String) : String
        result = ""
        rb_file.each_line do |line|
            if line.includes?("class ")
                split = line.strip.split(" ")
                result = split[1] if split.size > 1
            end
        end
        result
    end
        
    def self.get_def_name(line : String) : String?
        opt_def_index = line.index("def")
        return nil unless def_index = opt_def_index
        
        name_start_pos = def_index + 4
        return nil unless line.size > name_start_pos
        
        opt_parenthesis_index = line.index("(")
        if parenthesis_index = opt_parenthesis_index
            if name_start_pos > parenthesis_index
            return nil
            end
            return line[name_start_pos...parenthesis_index].strip
        else
            # no paranthesis -> take the rest starting from name pos
            return line[name_start_pos...].strip
        end
    end
    
    def self.get_parameters(line : String) : Array(String)
        parenth_open = line.index("(")
        parenth_closed = line.index(")")
        
        if parenth_open && parenth_closed && parenth_open < parenth_closed && parenth_closed > 0
            params = line[(parenth_open.not_nil! + 1)...parenth_closed.not_nil!]
        
            #puts "params:'#{params}'"
            result = [] of String 
            params.split(",").each do |param|
            result << param.strip
        end

        return result
    end
        return [] of String
    end
    
    def self.extract_method_bodies(rb_file : String, cls_name : String) : Hash(String, RubyDef)
        result = {} of String => RubyDef
        in_method = false
        def_name : String? = nil
        parameters = [] of String
        lines_since_def = [] of String
        end_stat_counter = 0
        end_index_at_def = -1
        
        # puts "extracting methods from class '#{cls_name}'"
        
        rb_file.each_line do |line|
            trim = line.strip
            #puts "trim:'#{trim}'"
        
            opt_endable = RubyEndableStatement.get_endable(trim)
            if opt_endable != nil && opt_endable.not_nil!.id.size > 0
                #puts "endable:'#{opt_endable.not_nil!}'"
            
                if RubyEndableStatement::DEF == opt_endable
                    #puts "def stat"
                    in_method = true
                    def_name = get_def_name(trim)
                    #puts "def_name:#{def_name}"
                    parameters = get_parameters(trim)
            
                    #puts "params:#{parameters}"
                    end_index_at_def = end_stat_counter
                else
                    end_stat_counter += 1
                end
            end
        
            if in_method
                lines_since_def << line
            end
        
            #puts "here:#{trim}"
            if trim.starts_with?("end")
                if end_stat_counter != end_index_at_def
                    #puts "endable statement within method closed"
                    end_stat_counter -= 1 # reset
                else
                    # method finished
                    current_def_name = def_name
                    #puts "method finished:'#{current_def_name}'"
                    if current_def_name && in_method
                        actual_def_name = current_def_name.as(String)
                        tmp = RubyDef.new(
                            actual_def_name,
                            "/todo",
                            cls_name,
                            lines_since_def.dup,
                            parameters.dup
                        )
                        result[actual_def_name] = tmp
                    end
            
                    
                    def_name = nil
                    end_index_at_def = -1
                    lines_since_def = [] of String
                    in_method = false
                end
            end
        end
        result
    end

    def self.get_cmp_name(rb_file : String, cls_name : String) : String?
        # puts "get variables"
        
        rb_file.each_line do |line|

          trim = line.strip
          if trim.starts_with?("@cmp_name")
            
            #puts "got cmp_name line #{trim}"
            index_eq = trim.index("=")
            if index_eq
              cmp_name = trim[index_eq + 1...].strip.gsub("\"", "")
              #puts "cmp_name is '#{cmp_name}'"
              return cmp_name
            end
          end
        end
        return nil
    end

end