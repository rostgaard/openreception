part of orf.api;

class PeerAccount {
  
  String username = null;
  
  String password = null;
  
  String context = null;
  PeerAccount();

  @override
  String toString() {
    return 'PeerAccount[username=$username, password=$password, context=$context, ]';
  }

  PeerAccount.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    username = json['username'];
    password = json['password'];
    context = json['context'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (username != null)
      json['username'] = username;
    if (password != null)
      json['password'] = password;
    if (context != null)
      json['context'] = context;
    return json;
  }

  static List<PeerAccount> listFromJson(List<dynamic> json) {
    return json == null ? List<PeerAccount>() : json.map((value) => PeerAccount.fromJson(value)).toList();
  }

  static Map<String, PeerAccount> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, PeerAccount>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = PeerAccount.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of PeerAccount-objects as value to a dart map
  static Map<String, List<PeerAccount>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<PeerAccount>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = PeerAccount.listFromJson(value);
       });
     }
     return map;
  }
}

