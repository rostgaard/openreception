part of orf.api;

class ResponseCode {
  /// The underlying value of this enum member.
  final String value;

  const ResponseCode._internal(this.value);

  static const ResponseCode ok_ = const ResponseCode._internal("ok");
  static const ResponseCode error_ = const ResponseCode._internal("error");

  static ResponseCode fromJson(String value) {
    return new ResponseCodeTypeTransformer().decode(value);
  }
}

class ResponseCodeTypeTransformer {

  dynamic encode(ResponseCode data) {
    return data.value;
  }

  ResponseCode decode(dynamic data) {
    switch (data) {
      case "ok": return ResponseCode.ok_;
      case "error": return ResponseCode.error_;
      default: throw('Unknown enum value to decode: $data');
    }
  }
}

