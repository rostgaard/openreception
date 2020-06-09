part of orf.api;

class MessageContext {
  
  int cid = 0;
  
  int rid = 0;
  
  String contactName = "";
  
  String receptionName = "";
  MessageContext();

  @override
  String toString() {
    return 'MessageContext[cid=$cid, rid=$rid, contactName=$contactName, receptionName=$receptionName, ]';
  }

  MessageContext.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    cid = json['cid'];
    rid = json['rid'];
    contactName = json['contactName'];
    receptionName = json['receptionName'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (cid != null)
      json['cid'] = cid;
    if (rid != null)
      json['rid'] = rid;
    if (contactName != null)
      json['contactName'] = contactName;
    if (receptionName != null)
      json['receptionName'] = receptionName;
    return json;
  }

  static List<MessageContext> listFromJson(List<dynamic> json) {
    return json == null ? List<MessageContext>() : json.map((value) => MessageContext.fromJson(value)).toList();
  }

  static Map<String, MessageContext> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, MessageContext>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = MessageContext.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of MessageContext-objects as value to a dart map
  static Map<String, List<MessageContext>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<MessageContext>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = MessageContext.listFromJson(value);
       });
     }
     return map;
  }
}

