part of orf.api;

class UserStatus {
  
  bool paused = null;
  
  int userId = null;
  UserStatus();

  @override
  String toString() {
    return 'UserStatus[paused=$paused, userId=$userId, ]';
  }

  UserStatus.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    paused = json['paused'];
    userId = json['userId'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (paused != null)
      json['paused'] = paused;
    if (userId != null)
      json['userId'] = userId;
    return json;
  }

  static List<UserStatus> listFromJson(List<dynamic> json) {
    return json == null ? List<UserStatus>() : json.map((value) => UserStatus.fromJson(value)).toList();
  }

  static Map<String, UserStatus> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, UserStatus>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = UserStatus.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of UserStatus-objects as value to a dart map
  static Map<String, List<UserStatus>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<UserStatus>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = UserStatus.listFromJson(value);
       });
     }
     return map;
  }
}

