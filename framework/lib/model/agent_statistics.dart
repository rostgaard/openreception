part of orf.api;

class AgentStatistics {
  /* The uid of the agent */
  int uid = null;
  /* The number of call that was recently answered by the agent */
  int recent = null;
  /* The total number of calls answered by the agent. */
  int total = null;
  AgentStatistics();

  @override
  String toString() {
    return 'AgentStatistics[uid=$uid, recent=$recent, total=$total, ]';
  }

  AgentStatistics.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    uid = json['uid'];
    recent = json['recent'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (uid != null)
      json['uid'] = uid;
    if (recent != null)
      json['recent'] = recent;
    if (total != null)
      json['total'] = total;
    return json;
  }

  static List<AgentStatistics> listFromJson(List<dynamic> json) {
    return json == null ? List<AgentStatistics>() : json.map((value) => AgentStatistics.fromJson(value)).toList();
  }

  static Map<String, AgentStatistics> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, AgentStatistics>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = AgentStatistics.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of AgentStatistics-objects as value to a dart map
  static Map<String, List<AgentStatistics>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<AgentStatistics>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = AgentStatistics.listFromJson(value);
       });
     }
     return map;
  }
}

