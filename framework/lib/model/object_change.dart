part of orf.api;

class ObjectChange {
  
  ChangeType changeType = null;
  //enum changeTypeEnum {  add,  delete,  modify,  };{
  
  ObjectType objectType = null;
  //enum objectTypeEnum {  user,  calendar,  reception,  organization,  contact,  receptionAttribute,  dialplan,  ivrMenu,  message,  };{
  ObjectChange();

  @override
  String toString() {
    return 'ObjectChange[changeType=$changeType, objectType=$objectType, ]';
  }

  ObjectChange.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    changeType = (json['changeType'] == null) ?
      null :
      ChangeType.fromJson(json['changeType']);
    objectType = (json['objectType'] == null) ?
      null :
      ObjectType.fromJson(json['objectType']);
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (changeType != null)
      json['changeType'] = changeType;
    if (objectType != null)
      json['objectType'] = objectType;
    return json;
  }

  static List<ObjectChange> listFromJson(List<dynamic> json) {
    return json == null ? List<ObjectChange>() : json.map((value) => ObjectChange.fromJson(value)).toList();
  }

  static Map<String, ObjectChange> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, ObjectChange>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = ObjectChange.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of ObjectChange-objects as value to a dart map
  static Map<String, List<ObjectChange>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<ObjectChange>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = ObjectChange.listFromJson(value);
       });
     }
     return map;
  }
}

