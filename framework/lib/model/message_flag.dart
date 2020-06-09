part of orf.api;

class MessageFlag {
  
  bool pleaseCall = false;
  
  bool willCallBack = false;
  
  bool called = false;
  
  bool urgent = false;
  MessageFlag();

  @override
  String toString() {
    return 'MessageFlag[pleaseCall=$pleaseCall, willCallBack=$willCallBack, called=$called, urgent=$urgent, ]';
  }

  MessageFlag.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    pleaseCall = json['pleaseCall'];
    willCallBack = json['willCallBack'];
    called = json['called'];
    urgent = json['urgent'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (pleaseCall != null)
      json['pleaseCall'] = pleaseCall;
    if (willCallBack != null)
      json['willCallBack'] = willCallBack;
    if (called != null)
      json['called'] = called;
    if (urgent != null)
      json['urgent'] = urgent;
    return json;
  }

  static List<MessageFlag> listFromJson(List<dynamic> json) {
    return json == null ? List<MessageFlag>() : json.map((value) => MessageFlag.fromJson(value)).toList();
  }

  static Map<String, MessageFlag> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, MessageFlag>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = MessageFlag.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of MessageFlag-objects as value to a dart map
  static Map<String, List<MessageFlag>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<MessageFlag>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = MessageFlag.listFromJson(value);
       });
     }
     return map;
  }
}

