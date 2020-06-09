part of orf.api;

class BaseContact {
  
  int id = 0;
  
  String name = "";
  
  String type = "";
  
  bool enabled = true;
  BaseContact();

  @override
  String toString() {
    return 'BaseContact[id=$id, name=$name, type=$type, enabled=$enabled, ]';
  }

  BaseContact.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    id = json['id'];
    name = json['name'];
    type = json['type'];
    enabled = json['enabled'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (id != null)
      json['id'] = id;
    if (name != null)
      json['name'] = name;
    if (type != null)
      json['type'] = type;
    if (enabled != null)
      json['enabled'] = enabled;
    return json;
  }

  static List<BaseContact> listFromJson(List<dynamic> json) {
    return json == null ? List<BaseContact>() : json.map((value) => BaseContact.fromJson(value)).toList();
  }

  static Map<String, BaseContact> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, BaseContact>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = BaseContact.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of BaseContact-objects as value to a dart map
  static Map<String, List<BaseContact>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<BaseContact>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = BaseContact.listFromJson(value);
       });
     }
     return map;
  }
}

