part of orf.api;

class Commit {
  
  DateTime changedAt = null;
  
  String authorIdentity = null;
  
  String commitHash = null;
  
  int uid = null;
  
  List<ObjectChange> changes = [];
  Commit();

  @override
  String toString() {
    return 'Commit[changedAt=$changedAt, authorIdentity=$authorIdentity, commitHash=$commitHash, uid=$uid, changes=$changes, ]';
  }

  Commit.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    changedAt = (json['changedAt'] == null) ?
      null :
      DateTime.parse(json['changedAt']);
    authorIdentity = json['authorIdentity'];
    commitHash = json['commitHash'];
    uid = json['uid'];
    changes = (json['changes'] == null) ?
      null :
      ObjectChange.listFromJson(json['changes']);
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (changedAt != null)
      json['changedAt'] = changedAt == null ? null : changedAt.toUtc().toIso8601String();
    if (authorIdentity != null)
      json['authorIdentity'] = authorIdentity;
    if (commitHash != null)
      json['commitHash'] = commitHash;
    if (uid != null)
      json['uid'] = uid;
    if (changes != null)
      json['changes'] = changes;
    return json;
  }

  static List<Commit> listFromJson(List<dynamic> json) {
    return json == null ? List<Commit>() : json.map((value) => Commit.fromJson(value)).toList();
  }

  static Map<String, Commit> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, Commit>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = Commit.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of Commit-objects as value to a dart map
  static Map<String, List<Commit>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<Commit>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = Commit.listFromJson(value);
       });
     }
     return map;
  }
}

