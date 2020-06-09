part of orf.api;

class Peer {
  
  String name = null;
  
  int channelCount = 0;
  
  bool inTransition = false;
  
  bool registered = false;
  Peer();

  @override
  String toString() {
    return 'Peer[name=$name, channelCount=$channelCount, inTransition=$inTransition, registered=$registered, ]';
  }

  Peer.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    name = json['name'];
    channelCount = json['channelCount'];
    inTransition = json['inTransition'];
    registered = json['registered'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (name != null)
      json['name'] = name;
    if (channelCount != null)
      json['channelCount'] = channelCount;
    if (inTransition != null)
      json['inTransition'] = inTransition;
    if (registered != null)
      json['registered'] = registered;
    return json;
  }

  static List<Peer> listFromJson(List<dynamic> json) {
    return json == null ? List<Peer>() : json.map((value) => Peer.fromJson(value)).toList();
  }

  static Map<String, Peer> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, Peer>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = Peer.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of Peer-objects as value to a dart map
  static Map<String, List<Peer>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<Peer>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = Peer.listFromJson(value);
       });
     }
     return map;
  }
}

