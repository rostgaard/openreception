part of orf.api;

class DeleteResponseCode {
  /// The underlying value of this enum member.
  final String value;

  const DeleteResponseCode._internal(this.value);

  static const DeleteResponseCode ok_ = const DeleteResponseCode._internal("ok");
  static const DeleteResponseCode error_ = const DeleteResponseCode._internal("error");

  static DeleteResponseCode fromJson(String value) {
    return new DeleteResponseCodeTypeTransformer().decode(value);
  }
}

class DeleteResponseCodeTypeTransformer {

  dynamic encode(DeleteResponseCode data) {
    return data.value;
  }

  DeleteResponseCode decode(dynamic data) {
    switch (data) {
      case "ok": return DeleteResponseCode.ok_;
      case "error": return DeleteResponseCode.error_;
      default: throw('Unknown enum value to decode: $data');
    }
  }
}

