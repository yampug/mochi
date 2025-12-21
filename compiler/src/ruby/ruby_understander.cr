require "./ruby_var"
require "./ruby_def"
require "./ruby_endable_statement"
require "./ruby_script_engine"
require "../tree-sitter/class_extractor"
require "../tree-sitter/property_extractor"
require "../tree-sitter/imports_extractor"
require "../tree-sitter/method_body_extractor"

class RubyUnderstander

  def self.extract_raw_string_from_def_body(body : Array(String), name : String) : String?
    inner_body = body[1...body.size - 1]
    .join("\n")
    .strip
    .gsub("\t", "")
    .gsub("  ", " ")

    if inner_body.starts_with?("%Q{") && inner_body.ends_with?("}")
      return inner_body[3, inner_body.size - 4].strip
    elsif inner_body.starts_with?("%q{") && inner_body.ends_with?("}")
      return inner_body[3, inner_body.size - 4].strip
    elsif inner_body.starts_with?("\"") && inner_body.ends_with?("\"")
      return inner_body[1, inner_body.size - 2].strip
    elsif inner_body.starts_with?("'") && inner_body.ends_with?("'")
      return inner_body[1, inner_body.size - 2].strip
    end
    return inner_body
  end

  def self.class_name(code : String) : String
    return TreeSitter::ClassExtractor.class_name(code)
  end

  def self.get_imports(rb_file : String) : Array(String)
    return TreeSitter::ImportsExtractor.extract_imports(rb_file)
  end

  def self.extract_method_bodies(rb_file : String, cls_name : String) : Hash(String, RubyDef)
    return TreeSitter::MethodBodyExtractor.extract_method_bodies(rb_file, cls_name)
  end

  def self.get_cmp_name(rb_file : String, cls_name : String) : String?
    TreeSitter::PropertyExtractor.extract_property(rb_file, "@tag_name")
  end

end
