part of orf.api;

class Playback {
  
  String MOCK = null;
  Playback();

  @override
  String toString() {
    return 'Playback[MOCK=$MOCK, ]';
  }

  Playback.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    MOCK = json['MOCK'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (MOCK != null)
      json['MOCK'] = MOCK;
    return json;
  }

  static List<Playback> listFromJson(List<dynamic> json) {
    return json == null ? List<Playback>() : json.map((value) => Playback.fromJson(value)).toList();
  }

  static Map<String, Playback> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, Playback>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = Playback.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of Playback-objects as value to a dart map
  static Map<String, List<Playback>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<Playback>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = Playback.listFromJson(value);
       });
     }
     return map;
  }
}

