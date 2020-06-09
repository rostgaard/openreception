part of orf.api;

class ClientConnection {
  
  int userId = null;
  
  int connectionCount = null;
  ClientConnection();

  @override
  String toString() {
    return 'ClientConnection[userId=$userId, connectionCount=$connectionCount, ]';
  }

  ClientConnection.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    userId = json['userId'];
    connectionCount = json['connectionCount'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (userId != null)
      json['userId'] = userId;
    if (connectionCount != null)
      json['connectionCount'] = connectionCount;
    return json;
  }

  static List<ClientConnection> listFromJson(List<dynamic> json) {
    return json == null ? List<ClientConnection>() : json.map((value) => ClientConnection.fromJson(value)).toList();
  }

  static Map<String, ClientConnection> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, ClientConnection>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = ClientConnection.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of ClientConnection-objects as value to a dart map
  static Map<String, List<ClientConnection>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<ClientConnection>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = ClientConnection.listFromJson(value);
       });
     }
     return map;
  }
}

