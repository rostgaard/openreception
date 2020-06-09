part of orf.api;

class ServerConfiguration {
  
  String auth = null;
  
  String calendar = null;
  
  String callflow = null;
  
  String cdr = null;
  
  String notification = null;
  
  String contact = null;
  
  String dialplan = null;
  
  String message = null;
  
  String notificationSocket = null;
  
  String reception = null;
  
  String user = null;
  ServerConfiguration();

  @override
  String toString() {
    return 'ServerConfiguration[auth=$auth, calendar=$calendar, callflow=$callflow, cdr=$cdr, notification=$notification, contact=$contact, dialplan=$dialplan, message=$message, notificationSocket=$notificationSocket, reception=$reception, user=$user, ]';
  }

  ServerConfiguration.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    auth = json['auth'];
    calendar = json['calendar'];
    callflow = json['callflow'];
    cdr = json['cdr'];
    notification = json['notification'];
    contact = json['contact'];
    dialplan = json['dialplan'];
    message = json['message'];
    notificationSocket = json['notificationSocket'];
    reception = json['reception'];
    user = json['user'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (auth != null)
      json['auth'] = auth;
    if (calendar != null)
      json['calendar'] = calendar;
    if (callflow != null)
      json['callflow'] = callflow;
    if (cdr != null)
      json['cdr'] = cdr;
    if (notification != null)
      json['notification'] = notification;
    if (contact != null)
      json['contact'] = contact;
    if (dialplan != null)
      json['dialplan'] = dialplan;
    if (message != null)
      json['message'] = message;
    if (notificationSocket != null)
      json['notificationSocket'] = notificationSocket;
    if (reception != null)
      json['reception'] = reception;
    if (user != null)
      json['user'] = user;
    return json;
  }

  static List<ServerConfiguration> listFromJson(List<dynamic> json) {
    return json == null ? List<ServerConfiguration>() : json.map((value) => ServerConfiguration.fromJson(value)).toList();
  }

  static Map<String, ServerConfiguration> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, ServerConfiguration>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = ServerConfiguration.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of ServerConfiguration-objects as value to a dart map
  static Map<String, List<ServerConfiguration>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<ServerConfiguration>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = ServerConfiguration.listFromJson(value);
       });
     }
     return map;
  }
}

