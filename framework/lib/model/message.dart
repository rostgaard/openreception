part of orf.api;

class Message {
  
  List<MessageEndpoint> recipients = [];
  
  int id = 0;
  
  MessageContext context = null;
  
  MessageFlag flag = null;
  
  MessageState state = null;
  //enum stateEnum {  unknown,  draft,  sent,  closed,  };{
  
  CallerInfo callerInfo = null;
  
  DateTime createdAt = null;
  
  String body = "";
  
  String callId = "";
  
  User sender = null;
  Message();

  @override
  String toString() {
    return 'Message[recipients=$recipients, id=$id, context=$context, flag=$flag, state=$state, callerInfo=$callerInfo, createdAt=$createdAt, body=$body, callId=$callId, sender=$sender, ]';
  }

  Message.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    recipients = (json['recipients'] == null) ?
      null :
      MessageEndpoint.listFromJson(json['recipients']);
    id = json['id'];
    context = (json['context'] == null) ?
      null :
      MessageContext.fromJson(json['context']);
    flag = (json['flag'] == null) ?
      null :
      MessageFlag.fromJson(json['flag']);
    state = (json['state'] == null) ?
      null :
      MessageState.fromJson(json['state']);
    callerInfo = (json['callerInfo'] == null) ?
      null :
      CallerInfo.fromJson(json['callerInfo']);
    createdAt = (json['createdAt'] == null) ?
      null :
      DateTime.parse(json['createdAt']);
    body = json['body'];
    callId = json['callId'];
    sender = (json['sender'] == null) ?
      null :
      User.fromJson(json['sender']);
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (recipients != null)
      json['recipients'] = recipients;
    if (id != null)
      json['id'] = id;
    if (context != null)
      json['context'] = context;
    if (flag != null)
      json['flag'] = flag;
    if (state != null)
      json['state'] = state;
    if (callerInfo != null)
      json['callerInfo'] = callerInfo;
    if (createdAt != null)
      json['createdAt'] = createdAt == null ? null : createdAt.toUtc().toIso8601String();
    if (body != null)
      json['body'] = body;
    if (callId != null)
      json['callId'] = callId;
    if (sender != null)
      json['sender'] = sender;
    return json;
  }

  static List<Message> listFromJson(List<dynamic> json) {
    return json == null ? List<Message>() : json.map((value) => Message.fromJson(value)).toList();
  }

  static Map<String, Message> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, Message>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = Message.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of Message-objects as value to a dart map
  static Map<String, List<Message>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<Message>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = Message.listFromJson(value);
       });
     }
     return map;
  }
}

