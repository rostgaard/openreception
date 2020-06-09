part of orf.api;

class ChangeType {
  /// The underlying value of this enum member.
  final String value;

  const ChangeType._internal(this.value);

  static const ChangeType add_ = const ChangeType._internal("add");
  static const ChangeType delete_ = const ChangeType._internal("delete");
  static const ChangeType modify_ = const ChangeType._internal("modify");

  static ChangeType fromJson(String value) {
    return new ChangeTypeTypeTransformer().decode(value);
  }
}

class ChangeTypeTypeTransformer {

  dynamic encode(ChangeType data) {
    return data.value;
  }

  ChangeType decode(dynamic data) {
    switch (data) {
      case "add": return ChangeType.add_;
      case "delete": return ChangeType.delete_;
      case "modify": return ChangeType.modify_;
      default: throw('Unknown enum value to decode: $data');
    }
  }
}

