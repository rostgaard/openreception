part of orf.api;

class OriginationContext {
  
  int contactId = 0;
  
  int receptionId = 0;
  
  String dialplan = "";
  
  String callId = "";
  OriginationContext();

  @override
  String toString() {
    return 'OriginationContext[contactId=$contactId, receptionId=$receptionId, dialplan=$dialplan, callId=$callId, ]';
  }

  OriginationContext.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    contactId = json['contactId'];
    receptionId = json['receptionId'];
    dialplan = json['dialplan'];
    callId = json['callId'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (contactId != null)
      json['contactId'] = contactId;
    if (receptionId != null)
      json['receptionId'] = receptionId;
    if (dialplan != null)
      json['dialplan'] = dialplan;
    if (callId != null)
      json['callId'] = callId;
    return json;
  }

  static List<OriginationContext> listFromJson(List<dynamic> json) {
    return json == null ? List<OriginationContext>() : json.map((value) => OriginationContext.fromJson(value)).toList();
  }

  static Map<String, OriginationContext> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, OriginationContext>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = OriginationContext.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of OriginationContext-objects as value to a dart map
  static Map<String, List<OriginationContext>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<OriginationContext>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = OriginationContext.listFromJson(value);
       });
     }
     return map;
  }
}

