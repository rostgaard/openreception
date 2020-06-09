part of orf.api;

class MessageQueueEntry {
  
  DateTime createdAt = null;
  
  List<MessageEndpoint> handledRecipients = [];
  
  List<MessageEndpoint> unhandledRecipients = [];
  
  int id = null;
  
  int tries = null;
  
  Message message = null;
  MessageQueueEntry();

  @override
  String toString() {
    return 'MessageQueueEntry[createdAt=$createdAt, handledRecipients=$handledRecipients, unhandledRecipients=$unhandledRecipients, id=$id, tries=$tries, message=$message, ]';
  }

  MessageQueueEntry.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    createdAt = (json['createdAt'] == null) ?
      null :
      DateTime.parse(json['createdAt']);
    handledRecipients = (json['handledRecipients'] == null) ?
      null :
      MessageEndpoint.listFromJson(json['handledRecipients']);
    unhandledRecipients = (json['unhandledRecipients'] == null) ?
      null :
      MessageEndpoint.listFromJson(json['unhandledRecipients']);
    id = json['id'];
    tries = json['tries'];
    message = (json['message'] == null) ?
      null :
      Message.fromJson(json['message']);
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (createdAt != null)
      json['createdAt'] = createdAt == null ? null : createdAt.toUtc().toIso8601String();
    if (handledRecipients != null)
      json['handledRecipients'] = handledRecipients;
    if (unhandledRecipients != null)
      json['unhandledRecipients'] = unhandledRecipients;
    if (id != null)
      json['id'] = id;
    if (tries != null)
      json['tries'] = tries;
    if (message != null)
      json['message'] = message;
    return json;
  }

  static List<MessageQueueEntry> listFromJson(List<dynamic> json) {
    return json == null ? List<MessageQueueEntry>() : json.map((value) => MessageQueueEntry.fromJson(value)).toList();
  }

  static Map<String, MessageQueueEntry> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, MessageQueueEntry>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = MessageQueueEntry.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of MessageQueueEntry-objects as value to a dart map
  static Map<String, List<MessageQueueEntry>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<MessageQueueEntry>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = MessageQueueEntry.listFromJson(value);
       });
     }
     return map;
  }
}

