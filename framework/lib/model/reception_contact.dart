part of orf.api;

class ReceptionContact {
  
  BaseContact contact = null;
  
  ReceptionAttributes attr = null;
  ReceptionContact();

  @override
  String toString() {
    return 'ReceptionContact[contact=$contact, attr=$attr, ]';
  }

  ReceptionContact.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    contact = (json['contact'] == null) ?
      null :
      BaseContact.fromJson(json['contact']);
    attr = (json['attr'] == null) ?
      null :
      ReceptionAttributes.fromJson(json['attr']);
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (contact != null)
      json['contact'] = contact;
    if (attr != null)
      json['attr'] = attr;
    return json;
  }

  static List<ReceptionContact> listFromJson(List<dynamic> json) {
    return json == null ? List<ReceptionContact>() : json.map((value) => ReceptionContact.fromJson(value)).toList();
  }

  static Map<String, ReceptionContact> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, ReceptionContact>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = ReceptionContact.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of ReceptionContact-objects as value to a dart map
  static Map<String, List<ReceptionContact>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<ReceptionContact>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = ReceptionContact.listFromJson(value);
       });
     }
     return map;
  }
}

