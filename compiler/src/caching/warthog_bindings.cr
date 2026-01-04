@[Link(ldflags: "-L#{__DIR__}/../../../fragments/libs -lwarthogdb")]
lib LibWarthog
  alias WarthogHandle = Void*
  alias SnapshotHandle = Void*
  alias IteratorHandle = Void*

  fun warthog_open(
    path : UInt8*,
    max_file_size : UInt32,
    compaction_threshold : Float64,
    number_of_records : UInt32
  ) : WarthogHandle

  fun warthog_close(handle : WarthogHandle) : Void

  fun warthog_put(
    handle : WarthogHandle,
    key : UInt8*,
    key_len : LibC::SizeT,
    val : UInt8*,
    val_len : LibC::SizeT
  ) : Int32

  fun warthog_get(
    handle : WarthogHandle,
    key : UInt8*,
    key_len : LibC::SizeT,
    out_val : UInt8*,
    out_cap : LibC::SizeT,
    out_len : LibC::SizeT*
  ) : Int32

  fun warthog_delete(
    handle : WarthogHandle,
    key : UInt8*,
    key_len : LibC::SizeT
  ) : Int32

  fun warthog_snapshot_open(handle : WarthogHandle) : SnapshotHandle

  fun warthog_snapshot_close(handle : WarthogHandle, snap : SnapshotHandle) : Void

  fun warthog_snapshot_get(
    handle : WarthogHandle,
    snap : SnapshotHandle,
    key : UInt8*,
    key_len : LibC::SizeT,
    out_val : UInt8*,
    out_cap : LibC::SizeT,
    out_len : LibC::SizeT*
  ) : Int32

  fun warthog_iter_open(handle : WarthogHandle) : IteratorHandle

  fun warthog_snapshot_iter_open(
    handle : WarthogHandle,
    snap : SnapshotHandle
  ) : IteratorHandle

  fun warthog_iter_next(
    iter : IteratorHandle,
    key_out : UInt8*,
    key_cap : LibC::SizeT,
    key_len : LibC::SizeT*,
    val_out : UInt8*,
    val_cap : LibC::SizeT,
    val_len : LibC::SizeT*
  ) : Int32

  fun warthog_iter_close(iter : IteratorHandle) : Void
end
