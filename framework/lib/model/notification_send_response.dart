part of orf.api;

class NotificationSendResponse {
  
  NotificationSendResponseStatus status = null;
  NotificationSendResponse();

  @override
  String toString() {
    return 'NotificationSendResponse[status=$status, ]';
  }

  NotificationSendResponse.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    status = (json['status'] == null) ?
      null :
      NotificationSendResponseStatus.fromJson(json['status']);
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (status != null)
      json['status'] = status;
    return json;
  }

  static List<NotificationSendResponse> listFromJson(List<dynamic> json) {
    return json == null ? List<NotificationSendResponse>() : json.map((value) => NotificationSendResponse.fromJson(value)).toList();
  }

  static Map<String, NotificationSendResponse> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, NotificationSendResponse>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = NotificationSendResponse.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of NotificationSendResponse-objects as value to a dart map
  static Map<String, List<NotificationSendResponse>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<NotificationSendResponse>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = NotificationSendResponse.listFromJson(value);
       });
     }
     return map;
  }
}

