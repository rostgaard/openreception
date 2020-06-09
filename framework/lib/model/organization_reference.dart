part of orf.api;

class OrganizationReference {
  
  int id = 0;
  
  String name = null;
  OrganizationReference();

  @override
  String toString() {
    return 'OrganizationReference[id=$id, name=$name, ]';
  }

  OrganizationReference.fromJson(Map<String, dynamic> json) {
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

  static List<OrganizationReference> listFromJson(List<dynamic> json) {
    return json == null ? List<OrganizationReference>() : json.map((value) => OrganizationReference.fromJson(value)).toList();
  }

  static Map<String, OrganizationReference> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, OrganizationReference>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = OrganizationReference.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of OrganizationReference-objects as value to a dart map
  static Map<String, List<OrganizationReference>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<OrganizationReference>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = OrganizationReference.listFromJson(value);
       });
     }
     return map;
  }
}

