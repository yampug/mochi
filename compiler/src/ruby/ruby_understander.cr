require "./ruby_var"
require "./ruby_def"
require "./ruby_endable_statement"
require "./ruby_script_engine"
require "../tree-sitter/class_extractor"
require "../tree-sitter/property_extractor"
require "../tree-sitter/imports_extractor"
require "../tree-sitter/method_body_extractor"
require "../tree-sitter/string_extractor"

class RubyUnderstander

  def self.extract_raw_string_from_def_body(body : Array(String), name : String) : String
    return TreeSitter::StringExtractor.extract_raw_string_from_def_body(body, name)
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
