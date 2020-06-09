part of orf.api;

class Organization {
  
  int id = 0;
  
  String name = null;
  
  List<String> notes = [];
  Organization();

  @override
  String toString() {
    return 'Organization[id=$id, name=$name, notes=$notes, ]';
  }

  Organization.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    id = json['id'];
    name = json['name'];
    notes = (json['notes'] == null) ?
      null :
      (json['notes'] as List).cast<String>();
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (id != null)
      json['id'] = id;
    if (name != null)
      json['name'] = name;
    if (notes != null)
      json['notes'] = notes;
    return json;
  }

  static List<Organization> listFromJson(List<dynamic> json) {
    return json == null ? List<Organization>() : json.map((value) => Organization.fromJson(value)).toList();
  }

  static Map<String, Organization> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, Organization>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = Organization.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of Organization-objects as value to a dart map
  static Map<String, List<Organization>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<Organization>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = Organization.listFromJson(value);
       });
     }
     return map;
  }
}

