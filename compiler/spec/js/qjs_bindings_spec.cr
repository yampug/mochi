require "spec"
require "../spec_data_loader"
require "../../src/js/qjs_bindings"

describe "QuickJS Bindings" do
  describe "Runtime and Context Management" do
    it "creates and frees a runtime" do
      runtime = LibQuickJS.js_newruntime
      runtime.should_not be_nil
      runtime.null?.should be_false
      LibQuickJS.js_freeruntime(runtime)
    end

    it "creates and frees a context" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)
      ctx.should_not be_nil
      ctx.null?.should be_false
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "gets runtime from context" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)
      retrieved_runtime = LibQuickJS.js_getruntime(ctx)
      retrieved_runtime.should eq(runtime)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "sets and gets runtime opaque data" do
      runtime = LibQuickJS.js_newruntime
      test_data = Box.box(42)
      LibQuickJS.js_setruntimeopaque(runtime, test_data)
      retrieved = LibQuickJS.js_getruntimeopaque(runtime)
      retrieved.should eq(test_data)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "sets and gets context opaque data" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)
      test_data = Box.box("test")
      LibQuickJS.js_setcontextopaque(ctx, test_data)
      retrieved = LibQuickJS.js_getcontextopaque(ctx)
      retrieved.should eq(test_data)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "gets QuickJS version" do
      version_ptr = LibQuickJS.js_getversion
      version = String.new(version_ptr)
      version.should_not be_empty
      version.should match(/\d+\.\d+\.\d+/)
    end
  end

  describe "Basic Value Creation and Conversion" do
    it "creates and converts integer values" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      code = "42"
      result = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "test.js".to_unsafe, 0)

      result_int = 0_i32
      LibQuickJS.js_toint32(ctx, pointerof(result_int), result).should eq(0)
      result_int.should eq(42)

      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "creates and converts float values" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      code = "3.14159"
      result = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "test.js".to_unsafe, 0)

      result_float = 0.0
      LibQuickJS.js_tofloat64(ctx, pointerof(result_float), result).should eq(0)
      result_float.should be_close(3.14159, 0.00001)

      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "creates and converts string values" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      code = "'Hello, World!'"
      result = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "test.js".to_unsafe, 0)

      str_ptr = LibQuickJS.js_tocstringlen2(ctx, nil, result, false)
      str_ptr.null?.should be_false
      result_str = String.new(str_ptr)
      result_str.should eq("Hello, World!")

      LibQuickJS.js_freecstring(ctx, str_ptr)
      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "creates and converts boolean values" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Test true
      code_true = "true"
      result_true = LibQuickJS.js_eval(ctx, code_true.to_unsafe, code_true.bytesize.to_u64, "test.js".to_unsafe, 0)
      LibQuickJS.js_tobool(ctx, result_true).should eq(1)
      LibQuickJS.js_freevalue(ctx, result_true)

      # Test false
      code_false = "false"
      result_false = LibQuickJS.js_eval(ctx, code_false.to_unsafe, code_false.bytesize.to_u64, "test.js".to_unsafe, 0)
      LibQuickJS.js_tobool(ctx, result_false).should eq(0)
      LibQuickJS.js_freevalue(ctx, result_false)

      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "handles null and undefined" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Test null
      code_null = "null"
      result_null = LibQuickJS.js_eval(ctx, code_null.to_unsafe, code_null.bytesize.to_u64, "test.js".to_unsafe, 0)
      QuickJS.is_null?(result_null).should be_true
      LibQuickJS.js_freevalue(ctx, result_null)

      # Test undefined
      code_undefined = "undefined"
      result_undefined = LibQuickJS.js_eval(ctx, code_undefined.to_unsafe, code_undefined.bytesize.to_u64, "test.js".to_unsafe, 0)
      QuickJS.is_undefined?(result_undefined).should be_true
      LibQuickJS.js_freevalue(ctx, result_undefined)

      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "Code Evaluation" do
    it "evaluates simple arithmetic expressions" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      code = "2 + 2 * 3"
      result = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "test.js".to_unsafe, 0)

      result_int = 0_i32
      LibQuickJS.js_toint32(ctx, pointerof(result_int), result).should eq(0)
      result_int.should eq(8)

      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "evaluates string operations" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      code = "'Hello' + ' ' + 'World'"
      result = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "test.js".to_unsafe, 0)

      str_ptr = LibQuickJS.js_tocstringlen2(ctx, nil, result, false)
      result_str = String.new(str_ptr)
      result_str.should eq("Hello World")

      LibQuickJS.js_freecstring(ctx, str_ptr)
      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "evaluates function definitions and calls" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      code = SpecDataLoader.load("js/simple_function.js")
      result = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "simple_function.js".to_unsafe, 0)

      str_ptr = LibQuickJS.js_tocstringlen2(ctx, nil, result, false)
      result_str = String.new(str_ptr)
      result_str.should eq("Hello, QuickJS!")

      LibQuickJS.js_freecstring(ctx, str_ptr)
      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "evaluates array operations" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      code = "[1, 2, 3, 4, 5].length"
      result = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "test.js".to_unsafe, 0)

      result_int = 0_i32
      LibQuickJS.js_toint32(ctx, pointerof(result_int), result).should eq(0)
      result_int.should eq(5)

      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "evaluates class definitions and instantiation" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      code = SpecDataLoader.load("js/class_example.js")
      result = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "class_example.js".to_unsafe, 0)

      result_int = 0_i32
      LibQuickJS.js_toint32(ctx, pointerof(result_int), result).should eq(0)
      result_int.should eq(17)  # (5 * 3) + 2 = 17

      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "Property Access" do
    it "sets and gets properties using string names" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Get global object
      global = LibQuickJS.js_getglobalobject(ctx)

      # Create and set a string property
      test_str = "test value"
      str_val = LibQuickJS.js_newstringlen(ctx, test_str.to_unsafe, test_str.bytesize.to_u64)
      LibQuickJS.js_setpropertystr(ctx, global, "testProp".to_unsafe, str_val)

      # Read it back
      result = LibQuickJS.js_getpropertystr(ctx, global, "testProp".to_unsafe)

      str_ptr = LibQuickJS.js_tocstringlen2(ctx, nil, result, false)
      result_str = String.new(str_ptr)
      result_str.should eq("test value")

      LibQuickJS.js_freecstring(ctx, str_ptr)
      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freevalue(ctx, global)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "sets and gets array properties using indices" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Create an array
      arr = LibQuickJS.js_newarray(ctx)

      # Set array elements
      val1 = LibQuickJS.js_newnumber(ctx, 10.0)
      val2 = LibQuickJS.js_newnumber(ctx, 20.0)
      val3 = LibQuickJS.js_newnumber(ctx, 30.0)

      LibQuickJS.js_setpropertyuint32(ctx, arr, 0_u32, val1)
      LibQuickJS.js_setpropertyuint32(ctx, arr, 1_u32, val2)
      LibQuickJS.js_setpropertyuint32(ctx, arr, 2_u32, val3)

      # Get array element
      result = LibQuickJS.js_getpropertyuint32(ctx, arr, 1_u32)

      result_float = 0.0
      LibQuickJS.js_tofloat64(ctx, pointerof(result_float), result).should eq(0)
      result_float.should eq(20.0)

      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freevalue(ctx, arr)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "checks if properties exist" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      global = LibQuickJS.js_getglobalobject(ctx)

      # Create an atom for property name
      prop_atom = LibQuickJS.js_newatom(ctx, "Math".to_unsafe)

      # Check if Math exists (should be true)
      has_math = LibQuickJS.js_hasproperty(ctx, global, prop_atom)
      has_math.should eq(1)

      LibQuickJS.js_freeatom(ctx, prop_atom)

      # Check non-existent property
      nonexist_atom = LibQuickJS.js_newatom(ctx, "NonExistentProperty".to_unsafe)
      has_nonexist = LibQuickJS.js_hasproperty(ctx, global, nonexist_atom)
      has_nonexist.should eq(0)

      LibQuickJS.js_freeatom(ctx, nonexist_atom)
      LibQuickJS.js_freevalue(ctx, global)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "Error Handling" do
    it "detects exceptions from evaluation" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      code = SpecDataLoader.load("js/reference_error.js")
      result = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "error.js".to_unsafe, 0)

      QuickJS.is_exception?(result).should be_true
      LibQuickJS.js_hasexception(ctx).should be_true

      # Get the exception
      exception = LibQuickJS.js_getexception(ctx)

      # Convert to string
      exc_str_val = LibQuickJS.js_tostring(ctx, exception)
      exc_str_ptr = LibQuickJS.js_tocstringlen2(ctx, nil, exc_str_val, false)
      exc_str = String.new(exc_str_ptr)

      exc_str.should contain("ReferenceError")
      exc_str.should contain("undefinedVariable")

      LibQuickJS.js_freecstring(ctx, exc_str_ptr)
      LibQuickJS.js_freevalue(ctx, exc_str_val)
      LibQuickJS.js_freevalue(ctx, exception)
      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "handles thrown errors" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      code = SpecDataLoader.load("js/error_example.js")
      result = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "error.js".to_unsafe, 0)

      QuickJS.is_exception?(result).should be_true

      exception = LibQuickJS.js_getexception(ctx)
      exc_str_val = LibQuickJS.js_tostring(ctx, exception)
      exc_str_ptr = LibQuickJS.js_tocstringlen2(ctx, nil, exc_str_val, false)
      exc_str = String.new(exc_str_ptr)

      exc_str.should contain("TypeError")
      exc_str.should contain("test error")

      LibQuickJS.js_freecstring(ctx, exc_str_ptr)
      LibQuickJS.js_freevalue(ctx, exc_str_val)
      LibQuickJS.js_freevalue(ctx, exception)
      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "Type Checking" do
    it "identifies different JavaScript types" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Test integer
      int_result = LibQuickJS.js_eval(ctx, "42".to_unsafe, 2_u64, "test.js".to_unsafe, 0)
      QuickJS.is_int?(int_result).should be_true
      QuickJS.is_number?(int_result).should be_true
      LibQuickJS.js_freevalue(ctx, int_result)

      # Test string
      str_result = LibQuickJS.js_eval(ctx, "'hello'".to_unsafe, 7_u64, "test.js".to_unsafe, 0)
      QuickJS.is_string?(str_result).should be_true
      LibQuickJS.js_freevalue(ctx, str_result)

      # Test boolean
      bool_result = LibQuickJS.js_eval(ctx, "true".to_unsafe, 4_u64, "test.js".to_unsafe, 0)
      QuickJS.is_bool?(bool_result).should be_true
      LibQuickJS.js_freevalue(ctx, bool_result)

      # Test object
      obj_result = LibQuickJS.js_eval(ctx, "({})".to_unsafe, 4_u64, "test.js".to_unsafe, 0)
      QuickJS.is_object?(obj_result).should be_true
      LibQuickJS.js_isarray(obj_result).should be_false
      LibQuickJS.js_freevalue(ctx, obj_result)

      # Test array
      arr_result = LibQuickJS.js_eval(ctx, "[]".to_unsafe, 2_u64, "test.js".to_unsafe, 0)
      LibQuickJS.js_isarray(arr_result).should be_true
      LibQuickJS.js_freevalue(ctx, arr_result)

      # Test function
      fn_result = LibQuickJS.js_eval(ctx, "(function() {})".to_unsafe, 15_u64, "test.js".to_unsafe, 0)
      LibQuickJS.js_isfunction(ctx, fn_result).should be_true
      LibQuickJS.js_freevalue(ctx, fn_result)

      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "uses typeof operator correctly" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      tests = {
        "typeof 42"        => "number",
        "typeof 'hello'"   => "string",
        "typeof true"      => "boolean",
        "typeof {}"        => "object",
        "typeof []"        => "object",
        "typeof null"      => "object",
        "typeof undefined" => "undefined",
        "typeof function(){}" => "function",
      }

      tests.each do |code, expected_type|
        result = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "test.js".to_unsafe, 0)
        str_ptr = LibQuickJS.js_tocstringlen2(ctx, nil, result, false)
        type_str = String.new(str_ptr)
        type_str.should eq(expected_type)
        LibQuickJS.js_freecstring(ctx, str_ptr)
        LibQuickJS.js_freevalue(ctx, result)
      end

      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "Atoms" do
    it "creates and frees atoms" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      atom = LibQuickJS.js_newatom(ctx, "testAtom".to_unsafe)
      atom.should_not eq(LibQuickJS::JS_ATOM_NULL)

      # Convert atom to string
      atom_val = LibQuickJS.js_atomtostring(ctx, atom)
      str_ptr = LibQuickJS.js_tocstringlen2(ctx, nil, atom_val, false)
      str = String.new(str_ptr)
      str.should eq("testAtom")

      LibQuickJS.js_freecstring(ctx, str_ptr)
      LibQuickJS.js_freevalue(ctx, atom_val)
      LibQuickJS.js_freeatom(ctx, atom)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "creates atoms from uint32" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      atom = LibQuickJS.js_newatomuint32(ctx, 42_u32)
      atom.should_not eq(LibQuickJS::JS_ATOM_NULL)

      # Convert to string should give "42"
      atom_val = LibQuickJS.js_atomtostring(ctx, atom)
      str_ptr = LibQuickJS.js_tocstringlen2(ctx, nil, atom_val, false)
      str = String.new(str_ptr)
      str.should eq("42")

      LibQuickJS.js_freecstring(ctx, str_ptr)
      LibQuickJS.js_freevalue(ctx, atom_val)
      LibQuickJS.js_freeatom(ctx, atom)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "Object and Array Creation" do
    it "creates empty objects" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      obj = LibQuickJS.js_newobject(ctx)
      QuickJS.is_object?(obj).should be_true

      LibQuickJS.js_freevalue(ctx, obj)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "creates empty arrays" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      arr = LibQuickJS.js_newarray(ctx)
      LibQuickJS.js_isarray(arr).should be_true

      # Check length is 0
      len_result = LibQuickJS.js_getpropertystr(ctx, arr, "length".to_unsafe)
      len_int = 0_i32
      LibQuickJS.js_toint32(ctx, pointerof(len_int), len_result).should eq(0)
      len_int.should eq(0)

      LibQuickJS.js_freevalue(ctx, len_result)
      LibQuickJS.js_freevalue(ctx, arr)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "QuickJS Helper Module" do
    it "creates constant values" do
      QuickJS::NULL.tag.should eq(LibQuickJS::JS_TAG_NULL)
      QuickJS::UNDEFINED.tag.should eq(LibQuickJS::JS_TAG_UNDEFINED)
      QuickJS::TRUE.tag.should eq(LibQuickJS::JS_TAG_BOOL)
      QuickJS::TRUE.u_int32.should eq(1)
      QuickJS::FALSE.tag.should eq(LibQuickJS::JS_TAG_BOOL)
      QuickJS::FALSE.u_int32.should eq(0)
    end

    it "creates integer values" do
      val = QuickJS.mkval(LibQuickJS::JS_TAG_INT, 42)
      val.tag.should eq(LibQuickJS::JS_TAG_INT)
      val.u_int32.should eq(42)
      QuickJS.get_int(val).should eq(42)
    end

    it "creates boolean values" do
      true_val = QuickJS.mkval(LibQuickJS::JS_TAG_BOOL, 1)
      QuickJS.get_bool(true_val).should be_true

      false_val = QuickJS.mkval(LibQuickJS::JS_TAG_BOOL, 0)
      QuickJS.get_bool(false_val).should be_false
    end

    it "type checks values correctly" do
      int_val = QuickJS.mkval(LibQuickJS::JS_TAG_INT, 42)
      QuickJS.is_int?(int_val).should be_true
      QuickJS.is_bool?(int_val).should be_false
      QuickJS.is_null?(int_val).should be_false

      QuickJS.is_null?(QuickJS::NULL).should be_true
      QuickJS.is_undefined?(QuickJS::UNDEFINED).should be_true
      QuickJS.is_exception?(QuickJS::EXCEPTION).should be_true
    end
  end

  describe "Memory Management" do
    it "duplicates and frees values" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Create a value
      test_str = "test"
      val = LibQuickJS.js_newstringlen(ctx, test_str.to_unsafe, test_str.bytesize.to_u64)

      # Duplicate it
      dup_val = LibQuickJS.js_dupvalue(ctx, val)

      # Both should be usable
      str_ptr1 = LibQuickJS.js_tocstringlen2(ctx, nil, val, false)
      str_ptr2 = LibQuickJS.js_tocstringlen2(ctx, nil, dup_val, false)

      String.new(str_ptr1).should eq("test")
      String.new(str_ptr2).should eq("test")

      LibQuickJS.js_freecstring(ctx, str_ptr1)
      LibQuickJS.js_freecstring(ctx, str_ptr2)
      LibQuickJS.js_freevalue(ctx, val)
      LibQuickJS.js_freevalue(ctx, dup_val)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "runs garbage collection" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Create some objects
      100.times do
        obj = LibQuickJS.js_newobject(ctx)
        LibQuickJS.js_freevalue(ctx, obj)
      end

      # Run GC (should not crash)
      LibQuickJS.js_rungc(runtime)

      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end

  describe "JSON Support" do
    it "parses JSON strings" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      json = "{\"name\":\"Alice\",\"age\":30}"
      result = LibQuickJS.js_parsejson(ctx, json.to_unsafe, json.bytesize.to_u64, "test.json".to_unsafe)

      QuickJS.is_exception?(result).should be_false

      # Get name property
      name_prop = LibQuickJS.js_getpropertystr(ctx, result, "name".to_unsafe)
      name_ptr = LibQuickJS.js_tocstringlen2(ctx, nil, name_prop, false)
      String.new(name_ptr).should eq("Alice")

      LibQuickJS.js_freecstring(ctx, name_ptr)
      LibQuickJS.js_freevalue(ctx, name_prop)
      LibQuickJS.js_freevalue(ctx, result)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end

    it "stringifies objects to JSON" do
      runtime = LibQuickJS.js_newruntime
      ctx = LibQuickJS.js_newcontext(runtime)

      # Create an object via eval
      code = "({name: 'Bob', age: 25})"
      obj = LibQuickJS.js_eval(ctx, code.to_unsafe, code.bytesize.to_u64, "test.js".to_unsafe, 0)

      # Stringify it
      json_val = LibQuickJS.js_jsonstringify(ctx, obj, QuickJS::UNDEFINED, QuickJS::UNDEFINED)

      json_ptr = LibQuickJS.js_tocstringlen2(ctx, nil, json_val, false)
      json_str = String.new(json_ptr)
      json_str.should eq("{\"name\":\"Bob\",\"age\":25}")

      LibQuickJS.js_freecstring(ctx, json_ptr)
      LibQuickJS.js_freevalue(ctx, json_val)
      LibQuickJS.js_freevalue(ctx, obj)
      LibQuickJS.js_freecontext(ctx)
      LibQuickJS.js_freeruntime(runtime)
    end
  end
end
