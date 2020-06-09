part of orf.api;

class NotificationSendPayload {
  
  String type = null;
  NotificationSendPayload();

  @override
  String toString() {
    return 'NotificationSendPayload[type=$type, ]';
  }

  NotificationSendPayload.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (type != null)
      json['type'] = type;
    return json;
  }

  static List<NotificationSendPayload> listFromJson(List<dynamic> json) {
    return json == null ? List<NotificationSendPayload>() : json.map((value) => NotificationSendPayload.fromJson(value)).toList();
  }

  static Map<String, NotificationSendPayload> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, NotificationSendPayload>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = NotificationSendPayload.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of NotificationSendPayload-objects as value to a dart map
  static Map<String, List<NotificationSendPayload>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<NotificationSendPayload>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = NotificationSendPayload.listFromJson(value);
       });
     }
     return map;
  }
}

