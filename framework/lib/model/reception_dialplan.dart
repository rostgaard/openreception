part of orf.api;

class ReceptionDialplan {
  
  String MOCK = null;
  
  String extension_ = null;
  ReceptionDialplan();

  @override
  String toString() {
    return 'ReceptionDialplan[MOCK=$MOCK, extension_=$extension_, ]';
  }

  ReceptionDialplan.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    MOCK = json['MOCK'];
    extension_ = json['extension'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (MOCK != null)
      json['MOCK'] = MOCK;
    if (extension_ != null)
      json['extension'] = extension_;
    return json;
  }

  static List<ReceptionDialplan> listFromJson(List<dynamic> json) {
    return json == null ? List<ReceptionDialplan>() : json.map((value) => ReceptionDialplan.fromJson(value)).toList();
  }

  static Map<String, ReceptionDialplan> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, ReceptionDialplan>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = ReceptionDialplan.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of ReceptionDialplan-objects as value to a dart map
  static Map<String, List<ReceptionDialplan>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<ReceptionDialplan>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = ReceptionDialplan.listFromJson(value);
       });
     }
     return map;
  }
}

