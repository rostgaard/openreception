part of orf.api;

class UserReference {
  /* ID of the user (uid) */
  int id = null;
  /* Name of the user */
  String name = null;
  UserReference();

  @override
  String toString() {
    return 'UserReference[id=$id, name=$name, ]';
  }

  UserReference.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (id != null)
      json['id'] = id;
    if (name != null)
      json['name'] = name;
    return json;
  }

  static List<UserReference> listFromJson(List<dynamic> json) {
    return json == null ? List<UserReference>() : json.map((value) => UserReference.fromJson(value)).toList();
  }

  static Map<String, UserReference> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, UserReference>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = UserReference.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of UserReference-objects as value to a dart map
  static Map<String, List<UserReference>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<UserReference>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = UserReference.listFromJson(value);
       });
     }
     return map;
  }
}

