part of orf.api;

class UserState {
  
  bool paused = null;
  
  int userId = null;
  UserState();

  @override
  String toString() {
    return 'UserState[paused=$paused, userId=$userId, ]';
  }

  UserState.fromJson(Map<String, dynamic> json) {
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

  static List<UserState> listFromJson(List<dynamic> json) {
    return json == null ? List<UserState>() : json.map((value) => UserState.fromJson(value)).toList();
  }

  static Map<String, UserState> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, UserState>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = UserState.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of UserState-objects as value to a dart map
  static Map<String, List<UserState>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<UserState>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = UserState.listFromJson(value);
       });
     }
     return map;
  }
}

