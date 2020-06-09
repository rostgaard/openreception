part of orf.api;

class NotificationSendRequest {
  
  List<int> recipients = [];
  
  NotificationSendPayload message = null;
  NotificationSendRequest();

  @override
  String toString() {
    return 'NotificationSendRequest[recipients=$recipients, message=$message, ]';
  }

  NotificationSendRequest.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    recipients = (json['recipients'] == null) ?
      null :
      (json['recipients'] as List).cast<int>();
    message = (json['message'] == null) ?
      null :
      NotificationSendPayload.fromJson(json['message']);
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (recipients != null)
      json['recipients'] = recipients;
    if (message != null)
      json['message'] = message;
    return json;
  }

  static List<NotificationSendRequest> listFromJson(List<dynamic> json) {
    return json == null ? List<NotificationSendRequest>() : json.map((value) => NotificationSendRequest.fromJson(value)).toList();
  }

  static Map<String, NotificationSendRequest> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, NotificationSendRequest>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = NotificationSendRequest.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of NotificationSendRequest-objects as value to a dart map
  static Map<String, List<NotificationSendRequest>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<NotificationSendRequest>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = NotificationSendRequest.listFromJson(value);
       });
     }
     return map;
  }
}

