require "../../../../fragments/vendor/libpftrace/bindings/crystal/src/pftrace"

module TraceHelper
  def trace_slice(trace : Pftrace::Trace?, name : String, sequence_id : UInt32, category : String = "transpile")
    trace.try do |t|
      t.trace(name, type: Pftrace::EventType::SliceBegin, track_uuid: 101_u64, timestamp: Time.monotonic.total_nanoseconds.to_u64, trusted_packet_sequence_id: sequence_id) do |ev|
        ev.category = category
      end
    end

    result = yield

    trace.try do |t|
      t.trace(name, type: Pftrace::EventType::SliceEnd, track_uuid: 101_u64, timestamp: Time.monotonic.total_nanoseconds.to_u64, trusted_packet_sequence_id: sequence_id) do |ev|
      end
    end

    result
  end
end
