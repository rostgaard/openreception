part of orf.api;

class PhoneNumber {
  
  String destination = "";
  
  bool confidential = false;
  
  String note = "";
  PhoneNumber();

  @override
  String toString() {
    return 'PhoneNumber[destination=$destination, confidential=$confidential, note=$note, ]';
  }

  PhoneNumber.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    destination = json['destination'];
    confidential = json['confidential'];
    note = json['note'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (destination != null)
      json['destination'] = destination;
    if (confidential != null)
      json['confidential'] = confidential;
    if (note != null)
      json['note'] = note;
    return json;
  }

  static List<PhoneNumber> listFromJson(List<dynamic> json) {
    return json == null ? List<PhoneNumber>() : json.map((value) => PhoneNumber.fromJson(value)).toList();
  }

  static Map<String, PhoneNumber> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, PhoneNumber>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = PhoneNumber.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of PhoneNumber-objects as value to a dart map
  static Map<String, List<PhoneNumber>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<PhoneNumber>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = PhoneNumber.listFromJson(value);
       });
     }
     return map;
  }
}

