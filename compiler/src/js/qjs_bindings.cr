@[Link(ldflags: "-L#{__DIR__}/../../../fragments/libs -lqjs -rpath #{__DIR__}/../../../fragments/libs")]
lib LibQuickJS
  # Opaque types
  type JSRuntime = Void*
  type JSContext = Void*
  type JSObject = Void*
  type JSClass = Void*
  type JSModuleDef = Void*
  type JSGCObjectHeader = Void*

  alias JSClassID = UInt32
  alias JSAtom = UInt32

  # JSValue representation
  # On 64-bit platforms without NAN boxing, JSValue is a struct
  # containing a union and a tag
  struct JSValue
    u_int32 : Int32      # int32 value (also used for bool)
    u_float64_low : Int32  # low 32 bits of float64 or pointer
    tag : Int64          # type tag
  end

  # Constants for JSValue tags
  JS_TAG_FIRST          =  -9
  JS_TAG_BIG_INT        =  -9
  JS_TAG_SYMBOL         =  -8
  JS_TAG_STRING         =  -7
  JS_TAG_MODULE         =  -3
  JS_TAG_FUNCTION_BYTECODE = -2
  JS_TAG_OBJECT         =  -1
  JS_TAG_INT            =   0
  JS_TAG_BOOL           =   1
  JS_TAG_NULL           =   2
  JS_TAG_UNDEFINED      =   3
  JS_TAG_UNINITIALIZED  =   4
  JS_TAG_CATCH_OFFSET   =   5
  JS_TAG_EXCEPTION      =   6
  JS_TAG_SHORT_BIG_INT  =   7
  JS_TAG_FLOAT64        =   8

  # Property flags
  JS_PROP_CONFIGURABLE  = 1 << 0
  JS_PROP_WRITABLE      = 1 << 1
  JS_PROP_ENUMERABLE    = 1 << 2
  JS_PROP_C_W_E         = JS_PROP_CONFIGURABLE | JS_PROP_WRITABLE | JS_PROP_ENUMERABLE

  # Eval flags
  JS_EVAL_TYPE_GLOBAL   = 0 << 0
  JS_EVAL_TYPE_MODULE   = 1 << 0
  JS_EVAL_FLAG_STRICT   = 1 << 3
  JS_EVAL_FLAG_COMPILE_ONLY = 1 << 5
  JS_EVAL_FLAG_BACKTRACE_BARRIER = 1 << 6
  JS_EVAL_FLAG_ASYNC    = 1 << 7

  # Call flags
  JS_CALL_FLAG_CONSTRUCTOR = 1 << 0

  # Invalid class ID
  JS_INVALID_CLASS_ID = 0_u32

  # Atom constants
  JS_ATOM_NULL = 0_u32

  # Runtime management
  fun js_newruntime = JS_NewRuntime : JSRuntime
  fun js_freeruntime = JS_FreeRuntime(rt : JSRuntime) : Void
  fun js_setruntimeinfo = JS_SetRuntimeInfo(rt : JSRuntime, info : UInt8*) : Void
  fun js_setmemorylimit = JS_SetMemoryLimit(rt : JSRuntime, limit : LibC::SizeT) : Void
  fun js_setdumpflags = JS_SetDumpFlags(rt : JSRuntime, flags : UInt64) : Void
  fun js_getdumpflags = JS_GetDumpFlags(rt : JSRuntime) : UInt64
  fun js_setgcthreshold = JS_SetGCThreshold(rt : JSRuntime, gc_threshold : LibC::SizeT) : Void
  fun js_getgcthreshold = JS_GetGCThreshold(rt : JSRuntime) : LibC::SizeT
  fun js_setmaxstacksize = JS_SetMaxStackSize(rt : JSRuntime, stack_size : LibC::SizeT) : Void
  fun js_updatestacktop = JS_UpdateStackTop(rt : JSRuntime) : Void
  fun js_rungc = JS_RunGC(rt : JSRuntime) : Void
  fun js_isliveobject = JS_IsLiveObject(rt : JSRuntime, obj : JSValue) : Bool
  fun js_getruntimeopaque = JS_GetRuntimeOpaque(rt : JSRuntime) : Void*
  fun js_setruntimeopaque = JS_SetRuntimeOpaque(rt : JSRuntime, opaque : Void*) : Void

  # Context management
  fun js_newcontext = JS_NewContext(rt : JSRuntime) : JSContext
  fun js_freecontext = JS_FreeContext(ctx : JSContext) : Void
  fun js_dupcontext = JS_DupContext(ctx : JSContext) : JSContext
  fun js_getcontextopaque = JS_GetContextOpaque(ctx : JSContext) : Void*
  fun js_setcontextopaque = JS_SetContextOpaque(ctx : JSContext, opaque : Void*) : Void
  fun js_getruntime = JS_GetRuntime(ctx : JSContext) : JSRuntime
  fun js_setclassproto = JS_SetClassProto(ctx : JSContext, class_id : JSClassID, obj : JSValue) : Void
  fun js_getclassproto = JS_GetClassProto(ctx : JSContext, class_id : JSClassID) : JSValue
  fun js_getfunctionproto = JS_GetFunctionProto(ctx : JSContext) : JSValue

  # Context with intrinsics
  fun js_newcontextraw = JS_NewContextRaw(rt : JSRuntime) : JSContext
  fun js_addintrinsicbaseobjects = JS_AddIntrinsicBaseObjects(ctx : JSContext) : Void
  fun js_addintrinsicdate = JS_AddIntrinsicDate(ctx : JSContext) : Void
  fun js_addintrinsiceval = JS_AddIntrinsicEval(ctx : JSContext) : Void
  fun js_addintrinsicregexpcompiler = JS_AddIntrinsicRegExpCompiler(ctx : JSContext) : Void
  fun js_addintrinsicregexp = JS_AddIntrinsicRegExp(ctx : JSContext) : Void
  fun js_addintrinsicjson = JS_AddIntrinsicJSON(ctx : JSContext) : Void
  fun js_addintrinsicproxy = JS_AddIntrinsicProxy(ctx : JSContext) : Void
  fun js_addintrinsicmapset = JS_AddIntrinsicMapSet(ctx : JSContext) : Void
  fun js_addintrinsictypedarrays = JS_AddIntrinsicTypedArrays(ctx : JSContext) : Void
  fun js_addintrinsicpromise = JS_AddIntrinsicPromise(ctx : JSContext) : Void
  fun js_addintrinsicbigint = JS_AddIntrinsicBigInt(ctx : JSContext) : Void
  fun js_addintrinsicweakref = JS_AddIntrinsicWeakRef(ctx : JSContext) : Void
  fun js_addperformance = JS_AddPerformance(ctx : JSContext) : Void
  fun js_addintrinsicdomexception = JS_AddIntrinsicDOMException(ctx : JSContext) : Void

  # Value creation
  fun js_newnumber = JS_NewNumber(ctx : JSContext, d : Float64) : JSValue
  fun js_newbigint64 = JS_NewBigInt64(ctx : JSContext, v : Int64) : JSValue
  fun js_newbiguint64 = JS_NewBigUint64(ctx : JSContext, v : UInt64) : JSValue
  fun js_newstringlen = JS_NewStringLen(ctx : JSContext, str : UInt8*, len : LibC::SizeT) : JSValue
  fun js_newstring_utf16 = JS_NewStringUTF16(ctx : JSContext, buf : UInt16*, len : LibC::SizeT) : JSValue
  fun js_newatomstring = JS_NewAtomString(ctx : JSContext, str : UInt8*) : JSValue

  # Value conversion
  fun js_tostring = JS_ToString(ctx : JSContext, val : JSValue) : JSValue
  fun js_tonumber = JS_ToNumber(ctx : JSContext, val : JSValue) : JSValue
  fun js_topropertykey = JS_ToPropertyKey(ctx : JSContext, val : JSValue) : JSValue
  fun js_tobool = JS_ToBool(ctx : JSContext, val : JSValue) : Int32
  fun js_toint32 = JS_ToInt32(ctx : JSContext, pres : Int32*, val : JSValue) : Int32
  fun js_toint64 = JS_ToInt64(ctx : JSContext, pres : Int64*, val : JSValue) : Int32
  fun js_toint64ext = JS_ToInt64Ext(ctx : JSContext, pres : Int64*, val : JSValue) : Int32
  fun js_toindex = JS_ToIndex(ctx : JSContext, plen : UInt64*, val : JSValue) : Int32
  fun js_tofloat64 = JS_ToFloat64(ctx : JSContext, pres : Float64*, val : JSValue) : Int32
  fun js_tobigint64 = JS_ToBigInt64(ctx : JSContext, pres : Int64*, val : JSValue) : Int32
  fun js_tobiguint64 = JS_ToBigUint64(ctx : JSContext, pres : UInt64*, val : JSValue) : Int32
  fun js_tocstringlen2 = JS_ToCStringLen2(ctx : JSContext, plen : LibC::SizeT*, val : JSValue, cesu8 : Bool) : UInt8*
  fun js_tocstringlen_utf16 = JS_ToCStringLenUTF16(ctx : JSContext, plen : LibC::SizeT*, val : JSValue) : UInt16*

  # String handling
  fun js_freecstring = JS_FreeCString(ctx : JSContext, ptr : UInt8*) : Void
  fun js_freecstringrt = JS_FreeCStringRT(rt : JSRuntime, ptr : UInt8*) : Void
  fun js_freecstring_utf16 = JS_FreeCStringUTF16(ctx : JSContext, ptr : UInt16*) : Void
  fun js_freecstringrt_utf16 = JS_FreeCStringRT_UTF16(rt : JSRuntime, ptr : UInt16*) : Void

  # Memory management
  fun js_freevalue = JS_FreeValue(ctx : JSContext, v : JSValue) : Void
  fun js_freevaluert = JS_FreeValueRT(rt : JSRuntime, v : JSValue) : Void
  fun js_dupvalue = JS_DupValue(ctx : JSContext, v : JSValue) : JSValue
  fun js_dupvaluert = JS_DupValueRT(rt : JSRuntime, v : JSValue) : JSValue

  # Object creation
  fun js_newobjectprotoclass = JS_NewObjectProtoClass(ctx : JSContext, proto : JSValue, class_id : JSClassID) : JSValue
  fun js_newobjectclass = JS_NewObjectClass(ctx : JSContext, class_id : JSClassID) : JSValue
  fun js_newobjectproto = JS_NewObjectProto(ctx : JSContext, proto : JSValue) : JSValue
  fun js_newobject = JS_NewObject(ctx : JSContext) : JSValue
  fun js_toobject = JS_ToObject(ctx : JSContext, val : JSValue) : JSValue

  # Array creation
  fun js_newarray = JS_NewArray(ctx : JSContext) : JSValue
  fun js_newarrayfrom = JS_NewArrayFrom(ctx : JSContext, count : Int32, values : JSValue*) : JSValue

  # Property access
  fun js_getproperty = JS_GetProperty(ctx : JSContext, this_obj : JSValue, prop : JSAtom) : JSValue
  fun js_getpropertyuint32 = JS_GetPropertyUint32(ctx : JSContext, this_obj : JSValue, idx : UInt32) : JSValue
  fun js_getpropertyint64 = JS_GetPropertyInt64(ctx : JSContext, this_obj : JSValue, idx : Int64) : JSValue
  fun js_getpropertystr = JS_GetPropertyStr(ctx : JSContext, this_obj : JSValue, prop : UInt8*) : JSValue
  fun js_setproperty = JS_SetProperty(ctx : JSContext, this_obj : JSValue, prop : JSAtom, val : JSValue) : Int32
  fun js_setpropertyuint32 = JS_SetPropertyUint32(ctx : JSContext, this_obj : JSValue, idx : UInt32, val : JSValue) : Int32
  fun js_setpropertyint64 = JS_SetPropertyInt64(ctx : JSContext, this_obj : JSValue, idx : Int64, val : JSValue) : Int32
  fun js_setpropertystr = JS_SetPropertyStr(ctx : JSContext, this_obj : JSValue, prop : UInt8*, val : JSValue) : Int32
  fun js_hasproperty = JS_HasProperty(ctx : JSContext, this_obj : JSValue, prop : JSAtom) : Int32
  fun js_deleteproperty = JS_DeleteProperty(ctx : JSContext, obj : JSValue, prop : JSAtom, flags : Int32) : Int32
  fun js_defineproperty = JS_DefineProperty(ctx : JSContext, this_obj : JSValue, prop : JSAtom, val : JSValue, getter : JSValue, setter : JSValue, flags : Int32) : Int32
  fun js_definepropertyvalue = JS_DefinePropertyValue(ctx : JSContext, this_obj : JSValue, prop : JSAtom, val : JSValue, flags : Int32) : Int32
  fun js_definepropertyvalueuint32 = JS_DefinePropertyValueUint32(ctx : JSContext, this_obj : JSValue, idx : UInt32, val : JSValue, flags : Int32) : Int32
  fun js_definepropertyvaluestr = JS_DefinePropertyValueStr(ctx : JSContext, this_obj : JSValue, prop : UInt8*, val : JSValue, flags : Int32) : Int32
  fun js_definepropertygetset = JS_DefinePropertyGetSet(ctx : JSContext, this_obj : JSValue, prop : JSAtom, getter : JSValue, setter : JSValue, flags : Int32) : Int32

  # Prototype handling
  fun js_setprototype = JS_SetPrototype(ctx : JSContext, obj : JSValue, proto_val : JSValue) : Int32
  fun js_getprototype = JS_GetPrototype(ctx : JSContext, val : JSValue) : JSValue

  # Function calls
  fun js_call = JS_Call(ctx : JSContext, func_obj : JSValue, this_obj : JSValue, argc : Int32, argv : JSValue*) : JSValue
  fun js_invoke = JS_Invoke(ctx : JSContext, this_val : JSValue, atom : JSAtom, argc : Int32, argv : JSValue*) : JSValue
  fun js_callconstructor = JS_CallConstructor(ctx : JSContext, func_obj : JSValue, argc : Int32, argv : JSValue*) : JSValue
  fun js_callconstructor2 = JS_CallConstructor2(ctx : JSContext, func_obj : JSValue, new_target : JSValue, argc : Int32, argv : JSValue*) : JSValue

  # Code evaluation
  fun js_detectmodule = JS_DetectModule(input : UInt8*, input_len : LibC::SizeT) : Bool
  fun js_eval = JS_Eval(ctx : JSContext, input : UInt8*, input_len : LibC::SizeT, filename : UInt8*, eval_flags : Int32) : JSValue
  fun js_evalthis = JS_EvalThis(ctx : JSContext, this_obj : JSValue, input : UInt8*, input_len : LibC::SizeT, filename : UInt8*, eval_flags : Int32) : JSValue
  fun js_evalfunction = JS_EvalFunction(ctx : JSContext, fun_obj : JSValue) : JSValue
  fun js_getglobalobject = JS_GetGlobalObject(ctx : JSContext) : JSValue

  # Error handling
  fun js_throw = JS_Throw(ctx : JSContext, obj : JSValue) : JSValue
  fun js_getexception = JS_GetException(ctx : JSContext) : JSValue
  fun js_hasexception = JS_HasException(ctx : JSContext) : Bool
  fun js_iserror = JS_IsError(val : JSValue) : Bool
  fun js_isuncatchableerror = JS_IsUncatchableError(val : JSValue) : Bool
  fun js_setuncatchableerror = JS_SetUncatchableError(ctx : JSContext, val : JSValue) : Void
  fun js_clearuncatchableerror = JS_ClearUncatchableError(ctx : JSContext, val : JSValue) : Void
  fun js_resetuncatchableerror = JS_ResetUncatchableError(ctx : JSContext) : Void
  fun js_newerror = JS_NewError(ctx : JSContext) : JSValue
  fun js_throwtypeerror = JS_ThrowTypeError(ctx : JSContext, fmt : UInt8*, ...) : JSValue
  fun js_throwsyntaxerror = JS_ThrowSyntaxError(ctx : JSContext, fmt : UInt8*, ...) : JSValue
  fun js_throwreferenceerror = JS_ThrowReferenceError(ctx : JSContext, fmt : UInt8*, ...) : JSValue
  fun js_throwrangeerror = JS_ThrowRangeError(ctx : JSContext, fmt : UInt8*, ...) : JSValue
  fun js_throwinternalerror = JS_ThrowInternalError(ctx : JSContext, fmt : UInt8*, ...) : JSValue
  fun js_throwoutofmemory = JS_ThrowOutOfMemory(ctx : JSContext) : JSValue

  # Atom handling
  fun js_newatomlen = JS_NewAtomLen(ctx : JSContext, str : UInt8*, len : LibC::SizeT) : JSAtom
  fun js_newatom = JS_NewAtom(ctx : JSContext, str : UInt8*) : JSAtom
  fun js_newatomuint32 = JS_NewAtomUInt32(ctx : JSContext, n : UInt32) : JSAtom
  fun js_dupatom = JS_DupAtom(ctx : JSContext, v : JSAtom) : JSAtom
  fun js_dupatomrt = JS_DupAtomRT(rt : JSRuntime, v : JSAtom) : JSAtom
  fun js_freeatom = JS_FreeAtom(ctx : JSContext, v : JSAtom) : Void
  fun js_freeatomrt = JS_FreeAtomRT(rt : JSRuntime, v : JSAtom) : Void
  fun js_atomtovalue = JS_AtomToValue(ctx : JSContext, atom : JSAtom) : JSValue
  fun js_atomtostring = JS_AtomToString(ctx : JSContext, atom : JSAtom) : JSValue
  fun js_atomtocstringlen = JS_AtomToCStringLen(ctx : JSContext, plen : LibC::SizeT*, atom : JSAtom) : UInt8*
  fun js_valuetoatom = JS_ValueToAtom(ctx : JSContext, val : JSValue) : JSAtom

  # Type checking
  fun js_isfunction = JS_IsFunction(ctx : JSContext, val : JSValue) : Bool
  fun js_isconstructor = JS_IsConstructor(ctx : JSContext, val : JSValue) : Bool
  fun js_isarray = JS_IsArray(val : JSValue) : Bool
  fun js_isregexp = JS_IsRegExp(val : JSValue) : Bool
  fun js_ismap = JS_IsMap(val : JSValue) : Bool
  fun js_isset = JS_IsSet(val : JSValue) : Bool
  fun js_isweakref = JS_IsWeakRef(val : JSValue) : Bool
  fun js_isweakset = JS_IsWeakSet(val : JSValue) : Bool
  fun js_isweakmap = JS_IsWeakMap(val : JSValue) : Bool
  fun js_isdataview = JS_IsDataView(val : JSValue) : Bool
  fun js_isdate = JS_IsDate(val : JSValue) : Bool
  fun js_isproxy = JS_IsProxy(val : JSValue) : Bool
  fun js_ispromise = JS_IsPromise(val : JSValue) : Bool
  fun js_isarraybuffer = JS_IsArrayBuffer(obj : JSValue) : Bool

  # ArrayBuffer and TypedArray
  fun js_newarraybuffer = JS_NewArrayBuffer(ctx : JSContext, buf : UInt8*, len : LibC::SizeT, free_func : Void*, opaque : Void*, is_shared : Bool) : JSValue
  fun js_newarraybuffercopy = JS_NewArrayBufferCopy(ctx : JSContext, buf : UInt8*, len : LibC::SizeT) : JSValue
  fun js_detacharraybuffer = JS_DetachArrayBuffer(ctx : JSContext, obj : JSValue) : Void
  fun js_getarraybuffer = JS_GetArrayBuffer(ctx : JSContext, psize : LibC::SizeT*, obj : JSValue) : UInt8*
  fun js_getuint8array = JS_GetUint8Array(ctx : JSContext, psize : LibC::SizeT*, obj : JSValue) : UInt8*
  fun js_newuint8array = JS_NewUint8Array(ctx : JSContext, buf : UInt8*, len : LibC::SizeT, free_func : Void*, opaque : Void*, is_shared : Bool) : JSValue
  fun js_newuint8arraycopy = JS_NewUint8ArrayCopy(ctx : JSContext, buf : UInt8*, len : LibC::SizeT) : JSValue
  fun js_gettypedarraytype = JS_GetTypedArrayType(obj : JSValue) : Int32

  # Promise
  enum JSPromiseStateEnum
    NotAPromise = -1
    Pending     =  0
    Fulfilled   =  1
    Rejected    =  2
  end

  fun js_newpromisecapability = JS_NewPromiseCapability(ctx : JSContext, resolving_funcs : JSValue*) : JSValue
  fun js_promisestate = JS_PromiseState(ctx : JSContext, promise : JSValue) : JSPromiseStateEnum
  fun js_promiseresult = JS_PromiseResult(ctx : JSContext, promise : JSValue) : JSValue

  # Symbol
  fun js_newsymbol = JS_NewSymbol(ctx : JSContext, description : UInt8*, is_global : Bool) : JSValue

  # Class support
  fun js_newclassid = JS_NewClassID(rt : JSRuntime, pclass_id : JSClassID*) : JSClassID
  fun js_getclassid = JS_GetClassID(v : JSValue) : JSClassID
  fun js_isregisteredclass = JS_IsRegisteredClass(rt : JSRuntime, class_id : JSClassID) : Bool
  fun js_getclassname = JS_GetClassName(rt : JSRuntime, class_id : JSClassID) : JSAtom
  fun js_setopaque = JS_SetOpaque(obj : JSValue, opaque : Void*) : Int32
  fun js_getopaque = JS_GetOpaque(obj : JSValue, class_id : JSClassID) : Void*
  fun js_getopaque2 = JS_GetOpaque2(ctx : JSContext, obj : JSValue, class_id : JSClassID) : Void*
  fun js_getanyopaque = JS_GetAnyOpaque(obj : JSValue, class_id : JSClassID*) : Void*

  # JSON
  fun js_parsejson = JS_ParseJSON(ctx : JSContext, buf : UInt8*, buf_len : LibC::SizeT, filename : UInt8*) : JSValue
  fun js_jsonstringify = JS_JSONStringify(ctx : JSContext, obj : JSValue, replacer : JSValue, space0 : JSValue) : JSValue

  # Comparison
  fun js_isequal = JS_IsEqual(ctx : JSContext, op1 : JSValue, op2 : JSValue) : Int32
  fun js_isstrictequal = JS_IsStrictEqual(ctx : JSContext, op1 : JSValue, op2 : JSValue) : Bool
  fun js_issamevalue = JS_IsSameValue(ctx : JSContext, op1 : JSValue, op2 : JSValue) : Bool
  fun js_issamevaluezero = JS_IsSameValueZero(ctx : JSContext, op1 : JSValue, op2 : JSValue) : Bool

  # Job queue
  fun js_isjobpending = JS_IsJobPending(rt : JSRuntime) : Bool
  fun js_executependingjob = JS_ExecutePendingJob(rt : JSRuntime, pctx : JSContext*) : Int32

  # Module support
  fun js_getimportmeta = JS_GetImportMeta(ctx : JSContext, m : JSModuleDef) : JSValue
  fun js_getmodulename = JS_GetModuleName(ctx : JSContext, m : JSModuleDef) : JSAtom
  fun js_getmodulenamespace = JS_GetModuleNamespace(ctx : JSContext, m : JSModuleDef) : JSValue
  fun js_resolvemodule = JS_ResolveModule(ctx : JSContext, obj : JSValue) : Int32

  # Proxy
  fun js_getproxytarget = JS_GetProxyTarget(ctx : JSContext, proxy : JSValue) : JSValue
  fun js_getproxyhandler = JS_GetProxyHandler(ctx : JSContext, proxy : JSValue) : JSValue
  fun js_newproxy = JS_NewProxy(ctx : JSContext, target : JSValue, handler : JSValue) : JSValue

  # Date
  fun js_newdate = JS_NewDate(ctx : JSContext, epoch_ms : Float64) : JSValue

  # Object utilities
  fun js_isinstanceof = JS_IsInstanceOf(ctx : JSContext, val : JSValue, obj : JSValue) : Int32
  fun js_isextensible = JS_IsExtensible(ctx : JSContext, obj : JSValue) : Int32
  fun js_preventextensions = JS_PreventExtensions(ctx : JSContext, obj : JSValue) : Int32
  fun js_getlength = JS_GetLength(ctx : JSContext, obj : JSValue, pres : Int64*) : Int32
  fun js_setlength = JS_SetLength(ctx : JSContext, obj : JSValue, len : Int64) : Int32
  fun js_sealobject = JS_SealObject(ctx : JSContext, obj : JSValue) : Int32
  fun js_freezeobject = JS_FreezeObject(ctx : JSContext, obj : JSValue) : Int32

  # Bytecode serialization
  JS_WRITE_OBJ_BYTECODE  = 1 << 0
  JS_WRITE_OBJ_SAB       = 1 << 2
  JS_WRITE_OBJ_REFERENCE = 1 << 3
  JS_WRITE_OBJ_STRIP_SOURCE = 1 << 4
  JS_WRITE_OBJ_STRIP_DEBUG = 1 << 5

  JS_READ_OBJ_BYTECODE  = 1 << 0
  JS_READ_OBJ_SAB       = 1 << 2
  JS_READ_OBJ_REFERENCE = 1 << 3

  fun js_writeobject = JS_WriteObject(ctx : JSContext, psize : LibC::SizeT*, obj : JSValue, flags : Int32) : UInt8*
  fun js_readobject = JS_ReadObject(ctx : JSContext, buf : UInt8*, buf_len : LibC::SizeT, flags : Int32) : JSValue

  # Version
  fun js_getversion = JS_GetVersion : UInt8*
end

# Helper module for JSValue construction and manipulation
# On 64-bit platforms, JSValue is a struct with separate tag and value fields
module QuickJS
  extend self

  # JSValue constructors
  def mkval(tag : Int32, val : Int32) : LibQuickJS::JSValue
    LibQuickJS::JSValue.new(u_int32: val, u_float64_low: 0, tag: tag.to_i64)
  end

  def mkptr(tag : Int32, ptr : Pointer) : LibQuickJS::JSValue
    addr = ptr.address
    LibQuickJS::JSValue.new(
      u_int32: (addr & 0xFFFFFFFF).to_i32,
      u_float64_low: (addr >> 32).to_i32,
      tag: tag.to_i64
    )
  end

  def mkfloat(val : Float64) : LibQuickJS::JSValue
    # For float64, we need to split the bits across the union
    bits = val.unsafe_as(UInt64)
    LibQuickJS::JSValue.new(
      u_int32: (bits & 0xFFFFFFFF).to_i32,
      u_float64_low: (bits >> 32).to_i32,
      tag: LibQuickJS::JS_TAG_FLOAT64.to_i64
    )
  end

  # JSValue accessors
  def get_tag(v : LibQuickJS::JSValue) : Int32
    v.tag.to_i32
  end

  def get_int(v : LibQuickJS::JSValue) : Int32
    v.u_int32
  end

  def get_bool(v : LibQuickJS::JSValue) : Bool
    v.u_int32 != 0
  end

  def get_float(v : LibQuickJS::JSValue) : Float64
    bits = (v.u_float64_low.to_u64 << 32) | v.u_int32.to_u32
    bits.unsafe_as(Float64)
  end

  def get_ptr(v : LibQuickJS::JSValue) : Pointer(Void)
    addr = (v.u_float64_low.to_u64 << 32) | v.u_int32.to_u32
    Pointer(Void).new(addr)
  end

  # Constant JSValue instances
  NULL          = mkval(LibQuickJS::JS_TAG_NULL, 0)
  UNDEFINED     = mkval(LibQuickJS::JS_TAG_UNDEFINED, 0)
  FALSE         = mkval(LibQuickJS::JS_TAG_BOOL, 0)
  TRUE          = mkval(LibQuickJS::JS_TAG_BOOL, 1)
  EXCEPTION     = mkval(LibQuickJS::JS_TAG_EXCEPTION, 0)
  UNINITIALIZED = mkval(LibQuickJS::JS_TAG_UNINITIALIZED, 0)

  # Type checking helpers
  def is_exception?(v : LibQuickJS::JSValue) : Bool
    v.tag == LibQuickJS::JS_TAG_EXCEPTION
  end

  def is_undefined?(v : LibQuickJS::JSValue) : Bool
    v.tag == LibQuickJS::JS_TAG_UNDEFINED
  end

  def is_null?(v : LibQuickJS::JSValue) : Bool
    v.tag == LibQuickJS::JS_TAG_NULL
  end

  def is_bool?(v : LibQuickJS::JSValue) : Bool
    v.tag == LibQuickJS::JS_TAG_BOOL
  end

  def is_int?(v : LibQuickJS::JSValue) : Bool
    v.tag == LibQuickJS::JS_TAG_INT
  end

  def is_float?(v : LibQuickJS::JSValue) : Bool
    v.tag == LibQuickJS::JS_TAG_FLOAT64
  end

  def is_number?(v : LibQuickJS::JSValue) : Bool
    v.tag == LibQuickJS::JS_TAG_INT || v.tag == LibQuickJS::JS_TAG_FLOAT64
  end

  def is_object?(v : LibQuickJS::JSValue) : Bool
    v.tag == LibQuickJS::JS_TAG_OBJECT
  end

  def is_string?(v : LibQuickJS::JSValue) : Bool
    v.tag == LibQuickJS::JS_TAG_STRING
  end

  def is_symbol?(v : LibQuickJS::JSValue) : Bool
    v.tag == LibQuickJS::JS_TAG_SYMBOL
  end
end
