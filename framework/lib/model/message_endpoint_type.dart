part of orf.api;

class MessageEndpointType {
  /// The underlying value of this enum member.
  final String value;

  const MessageEndpointType._internal(this.value);

  static const MessageEndpointType sms_ = const MessageEndpointType._internal("sms");
  static const MessageEndpointType emailTo_ = const MessageEndpointType._internal("email-to");
  static const MessageEndpointType emailCc_ = const MessageEndpointType._internal("email-cc");
  static const MessageEndpointType emailBcc_ = const MessageEndpointType._internal("email-bcc");

  static MessageEndpointType fromJson(String value) {
    return new MessageEndpointTypeTypeTransformer().decode(value);
  }
}

class MessageEndpointTypeTypeTransformer {

  dynamic encode(MessageEndpointType data) {
    return data.value;
  }

  MessageEndpointType decode(dynamic data) {
    switch (data) {
      case "sms": return MessageEndpointType.sms_;
      case "email-to": return MessageEndpointType.emailTo_;
      case "email-cc": return MessageEndpointType.emailCc_;
      case "email-bcc": return MessageEndpointType.emailBcc_;
      default: throw('Unknown enum value to decode: $data');
    }
  }
}

