part of orf.api;

class CallerInfo {
  
  String name = "?";
  
  String company = "?";
  
  String phone = "?";
  
  String cellPhone = "?";
  
  String localExtension = "?";
  CallerInfo();

  @override
  String toString() {
    return 'CallerInfo[name=$name, company=$company, phone=$phone, cellPhone=$cellPhone, localExtension=$localExtension, ]';
  }

  CallerInfo.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    name = json['name'];
    company = json['company'];
    phone = json['phone'];
    cellPhone = json['cellPhone'];
    localExtension = json['localExtension'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (name != null)
      json['name'] = name;
    if (company != null)
      json['company'] = company;
    if (phone != null)
      json['phone'] = phone;
    if (cellPhone != null)
      json['cellPhone'] = cellPhone;
    if (localExtension != null)
      json['localExtension'] = localExtension;
    return json;
  }

  static List<CallerInfo> listFromJson(List<dynamic> json) {
    return json == null ? List<CallerInfo>() : json.map((value) => CallerInfo.fromJson(value)).toList();
  }

  static Map<String, CallerInfo> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, CallerInfo>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = CallerInfo.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of CallerInfo-objects as value to a dart map
  static Map<String, List<CallerInfo>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<CallerInfo>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = CallerInfo.listFromJson(value);
       });
     }
     return map;
  }
}

