part of orf.api;

class ActiveRecording {
  /* The name of the agent channel currently being recorded. */
  String agentChannel = null;
  /* The filesystem path to the recording file. */
  String path = null;
  /* The time the recording was started. */
  DateTime started = null;
  ActiveRecording();

  @override
  String toString() {
    return 'ActiveRecording[agentChannel=$agentChannel, path=$path, started=$started, ]';
  }

  ActiveRecording.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    agentChannel = json['agentChannel'];
    path = json['path'];
    started = (json['started'] == null) ?
      null :
      DateTime.parse(json['started']);
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (agentChannel != null)
      json['agentChannel'] = agentChannel;
    if (path != null)
      json['path'] = path;
    if (started != null)
      json['started'] = started == null ? null : started.toUtc().toIso8601String();
    return json;
  }

  static List<ActiveRecording> listFromJson(List<dynamic> json) {
    return json == null ? List<ActiveRecording>() : json.map((value) => ActiveRecording.fromJson(value)).toList();
  }

  static Map<String, ActiveRecording> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, ActiveRecording>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = ActiveRecording.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of ActiveRecording-objects as value to a dart map
  static Map<String, List<ActiveRecording>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<ActiveRecording>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = ActiveRecording.listFromJson(value);
       });
     }
     return map;
  }
}

