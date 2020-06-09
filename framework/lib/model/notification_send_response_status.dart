part of orf.api;

class NotificationSendResponseStatus {
  
  int success = null;
  
  int failed = null;
  NotificationSendResponseStatus();

  @override
  String toString() {
    return 'NotificationSendResponseStatus[success=$success, failed=$failed, ]';
  }

  NotificationSendResponseStatus.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    success = json['success'];
    failed = json['failed'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (success != null)
      json['success'] = success;
    if (failed != null)
      json['failed'] = failed;
    return json;
  }

  static List<NotificationSendResponseStatus> listFromJson(List<dynamic> json) {
    return json == null ? List<NotificationSendResponseStatus>() : json.map((value) => NotificationSendResponseStatus.fromJson(value)).toList();
  }

  static Map<String, NotificationSendResponseStatus> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, NotificationSendResponseStatus>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = NotificationSendResponseStatus.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of NotificationSendResponseStatus-objects as value to a dart map
  static Map<String, List<NotificationSendResponseStatus>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<NotificationSendResponseStatus>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = NotificationSendResponseStatus.listFromJson(value);
       });
     }
     return map;
  }
}

