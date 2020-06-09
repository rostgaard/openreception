part of orf.api;

class ObjectType {
  /// The underlying value of this enum member.
  final String value;

  const ObjectType._internal(this.value);

  static const ObjectType user_ = const ObjectType._internal("user");
  static const ObjectType calendar_ = const ObjectType._internal("calendar");
  static const ObjectType reception_ = const ObjectType._internal("reception");
  static const ObjectType organization_ = const ObjectType._internal("organization");
  static const ObjectType contact_ = const ObjectType._internal("contact");
  static const ObjectType receptionAttribute_ = const ObjectType._internal("receptionAttribute");
  static const ObjectType dialplan_ = const ObjectType._internal("dialplan");
  static const ObjectType ivrMenu_ = const ObjectType._internal("ivrMenu");
  static const ObjectType message_ = const ObjectType._internal("message");

  static ObjectType fromJson(String value) {
    return new ObjectTypeTypeTransformer().decode(value);
  }
}

class ObjectTypeTypeTransformer {

  dynamic encode(ObjectType data) {
    return data.value;
  }

  ObjectType decode(dynamic data) {
    switch (data) {
      case "user": return ObjectType.user_;
      case "calendar": return ObjectType.calendar_;
      case "reception": return ObjectType.reception_;
      case "organization": return ObjectType.organization_;
      case "contact": return ObjectType.contact_;
      case "receptionAttribute": return ObjectType.receptionAttribute_;
      case "dialplan": return ObjectType.dialplan_;
      case "ivrMenu": return ObjectType.ivrMenu_;
      case "message": return ObjectType.message_;
      default: throw('Unknown enum value to decode: $data');
    }
  }
}

