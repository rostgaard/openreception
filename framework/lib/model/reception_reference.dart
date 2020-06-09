part of orf.api;

class ReceptionReference {
  
  int id = 0;
  
  String name = "";
  
  int oid = 0;
  ReceptionReference();

  @override
  String toString() {
    return 'ReceptionReference[id=$id, name=$name, oid=$oid, ]';
  }

  ReceptionReference.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    id = json['id'];
    name = json['name'];
    oid = json['oid'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (id != null)
      json['id'] = id;
    if (name != null)
      json['name'] = name;
    if (oid != null)
      json['oid'] = oid;
    return json;
  }

  static List<ReceptionReference> listFromJson(List<dynamic> json) {
    return json == null ? List<ReceptionReference>() : json.map((value) => ReceptionReference.fromJson(value)).toList();
  }

  static Map<String, ReceptionReference> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, ReceptionReference>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = ReceptionReference.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of ReceptionReference-objects as value to a dart map
  static Map<String, List<ReceptionReference>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<ReceptionReference>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = ReceptionReference.listFromJson(value);
       });
     }
     return map;
  }
}

