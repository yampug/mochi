#require "../lib/lexbor/src/lexbor"
require "lexbor"

class BindResult
    property html : String?
    property bindings : Hash(String, String)
    
    def initialize(@html, @bindings)
    end
 end

class BindExtractor

    def self.extract(html : String) : BindResult

        # puts "Calling lexbor"
        # puts "Lexbor.version:#{Lexbor.version}"
        cleaned_html_no_skeleton = ""
        bindings = {} of String => String

        time = Time.measure do
            
          doc = Lexbor.new(html)
  
          tags = doc.css("*")
          #puts tags
          tags.each do |tag|
              attrs_to_remove = [] of String
              attrs_to_add = {} of String => String
              #puts tag.attributes
              tag.attributes.each do |key, val|
                  #puts key
                  if key.starts_with?("bind:")
                      #puts "Found bind"
                      # remember for later
                      attrs_to_remove << key
                      key_no_prefix = key[5..-1]
                      # remove bind: prefix
                      attrs_to_add[key_no_prefix] = val
                      bindings[val[1..-2]] = key_no_prefix
                  end
              end
              # remove all attributes with bind:
              attrs_to_remove.each do |attr_name_to_remove|
                  tag.attribute_remove(attr_name_to_remove)
              end
              # add non bind: version
              attrs_to_add.each do |new_key, new_value|
                  tag.attribute_add(new_key, new_value)
              end
          end
  
          cleaned_html_full = doc.to_html
  
          body_open_tag = "<body>"
          body_close_tag = "</body>"
          body_open_index = cleaned_html_full.index(body_open_tag)
          body_end_index = cleaned_html_full.index(body_close_tag)
  
          cleaned_html_no_skeleton = if body_open_index && body_end_index && body_open_index < body_end_index
              cleaned_html_full[(body_open_index + body_open_tag.size)...body_end_index].strip
          else
              puts "no body found"
          end
      end

      #puts cleaned_html_no_skeleton
      puts "> Binding Extraction took #{time.total_milliseconds.to_i}ms"
      BindResult.new(html: cleaned_html_no_skeleton, bindings: bindings)
    end

end
