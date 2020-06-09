part of orf.api;

class User {
  /* Primary email address */
  String address = null;
  /* ID of the user (uid) */
  int id = null;
  /* Name of the user */
  String name = null;
  /* The current phone extension */
  String extension_ = null;
  /* User portrait URI */
  String portrait = null;
  /* The current groups that the user is member of */
  List<String> groups = [];
  /* Authentication identities */
  List<String> identities = [];
  User();

  @override
  String toString() {
    return 'User[address=$address, id=$id, name=$name, extension_=$extension_, portrait=$portrait, groups=$groups, identities=$identities, ]';
  }

  User.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    address = json['address'];
    id = json['id'];
    name = json['name'];
    extension_ = json['extension'];
    portrait = json['portrait'];
    groups = (json['groups'] == null) ?
      null :
      (json['groups'] as List).cast<String>();
    identities = (json['identities'] == null) ?
      null :
      (json['identities'] as List).cast<String>();
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (address != null)
      json['address'] = address;
    if (id != null)
      json['id'] = id;
    if (name != null)
      json['name'] = name;
    if (extension_ != null)
      json['extension'] = extension_;
    if (portrait != null)
      json['portrait'] = portrait;
    if (groups != null)
      json['groups'] = groups;
    if (identities != null)
      json['identities'] = identities;
    return json;
  }

  static List<User> listFromJson(List<dynamic> json) {
    return json == null ? List<User>() : json.map((value) => User.fromJson(value)).toList();
  }

  static Map<String, User> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, User>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = User.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of User-objects as value to a dart map
  static Map<String, List<User>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<User>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = User.listFromJson(value);
       });
     }
     return map;
  }
}

