part of orf.api;

class MessageState {
  /// The underlying value of this enum member.
  final String value;

  const MessageState._internal(this.value);

  /// Message State:  * &#x60;unknown&#x60; - Default initialized state, without anything other specified.  * &#x60;draft&#x60; - Message is current a draft in composition.  * &#x60;sent&#x60; - Message has been sent.  * &#x60;closed&#x60; - Message has been closed manually 
  static const MessageState unknown_ = const MessageState._internal("unknown");
  /// Message State:  * &#x60;unknown&#x60; - Default initialized state, without anything other specified.  * &#x60;draft&#x60; - Message is current a draft in composition.  * &#x60;sent&#x60; - Message has been sent.  * &#x60;closed&#x60; - Message has been closed manually 
  static const MessageState draft_ = const MessageState._internal("draft");
  /// Message State:  * &#x60;unknown&#x60; - Default initialized state, without anything other specified.  * &#x60;draft&#x60; - Message is current a draft in composition.  * &#x60;sent&#x60; - Message has been sent.  * &#x60;closed&#x60; - Message has been closed manually 
  static const MessageState sent_ = const MessageState._internal("sent");
  /// Message State:  * &#x60;unknown&#x60; - Default initialized state, without anything other specified.  * &#x60;draft&#x60; - Message is current a draft in composition.  * &#x60;sent&#x60; - Message has been sent.  * &#x60;closed&#x60; - Message has been closed manually 
  static const MessageState closed_ = const MessageState._internal("closed");

  static MessageState fromJson(String value) {
    return new MessageStateTypeTransformer().decode(value);
  }
}

class MessageStateTypeTransformer {

  dynamic encode(MessageState data) {
    return data.value;
  }

  MessageState decode(dynamic data) {
    switch (data) {
      case "unknown": return MessageState.unknown_;
      case "draft": return MessageState.draft_;
      case "sent": return MessageState.sent_;
      case "closed": return MessageState.closed_;
      default: throw('Unknown enum value to decode: $data');
    }
  }
}

