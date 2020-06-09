part of orf.api;

class CalendarEntry {
  
  int id = null;
  
  int lastAuthorId = null;
  
  DateTime touched = null;
  
  String content = null;
  
  DateTime start = null;
  
  DateTime stop = null;
  CalendarEntry();

  @override
  String toString() {
    return 'CalendarEntry[id=$id, lastAuthorId=$lastAuthorId, touched=$touched, content=$content, start=$start, stop=$stop, ]';
  }

  CalendarEntry.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    id = json['id'];
    lastAuthorId = json['lastAuthorId'];
    touched = (json['touched'] == null) ?
      null :
      DateTime.parse(json['touched']);
    content = json['content'];
    start = (json['start'] == null) ?
      null :
      DateTime.parse(json['start']);
    stop = (json['stop'] == null) ?
      null :
      DateTime.parse(json['stop']);
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (id != null)
      json['id'] = id;
    if (lastAuthorId != null)
      json['lastAuthorId'] = lastAuthorId;
    if (touched != null)
      json['touched'] = touched == null ? null : touched.toUtc().toIso8601String();
    if (content != null)
      json['content'] = content;
    if (start != null)
      json['start'] = start == null ? null : start.toUtc().toIso8601String();
    if (stop != null)
      json['stop'] = stop == null ? null : stop.toUtc().toIso8601String();
    return json;
  }

  static List<CalendarEntry> listFromJson(List<dynamic> json) {
    return json == null ? List<CalendarEntry>() : json.map((value) => CalendarEntry.fromJson(value)).toList();
  }

  static Map<String, CalendarEntry> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, CalendarEntry>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = CalendarEntry.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of CalendarEntry-objects as value to a dart map
  static Map<String, List<CalendarEntry>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<CalendarEntry>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = CalendarEntry.listFromJson(value);
       });
     }
     return map;
  }
}

