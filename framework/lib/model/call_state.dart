part of orf.api;

class CallState {
  /// The underlying value of this enum member.
  final String value;

  const CallState._internal(this.value);

  static const CallState unknown_ = const CallState._internal("unknown");
  static const CallState created_ = const CallState._internal("created");
  static const CallState ringing_ = const CallState._internal("ringing");
  static const CallState queued_ = const CallState._internal("queued");
  static const CallState unparked_ = const CallState._internal("unparked");
  static const CallState hungup_ = const CallState._internal("hungup");
  static const CallState transferring_ = const CallState._internal("transferring");
  static const CallState transferred_ = const CallState._internal("transferred");
  static const CallState speaking_ = const CallState._internal("speaking");
  static const CallState parked_ = const CallState._internal("parked");

  static CallState fromJson(String value) {
    return new CallStateTypeTransformer().decode(value);
  }
}

class CallStateTypeTransformer {

  dynamic encode(CallState data) {
    return data.value;
  }

  CallState decode(dynamic data) {
    switch (data) {
      case "unknown": return CallState.unknown_;
      case "created": return CallState.created_;
      case "ringing": return CallState.ringing_;
      case "queued": return CallState.queued_;
      case "unparked": return CallState.unparked_;
      case "hungup": return CallState.hungup_;
      case "transferring": return CallState.transferring_;
      case "transferred": return CallState.transferred_;
      case "speaking": return CallState.speaking_;
      case "parked": return CallState.parked_;
      default: throw('Unknown enum value to decode: $data');
    }
  }
}

