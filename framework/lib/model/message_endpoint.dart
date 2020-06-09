part of orf.api;

class MessageEndpoint {
  
  MessageEndpointType type = null;
  //enum typeEnum {  sms,  email-to,  email-cc,  email-bcc,  };{
  
  String name = "";
  
  String address = "";
  
  String note = "";
  MessageEndpoint();

  @override
  String toString() {
    return 'MessageEndpoint[type=$type, name=$name, address=$address, note=$note, ]';
  }

  MessageEndpoint.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    type = (json['type'] == null) ?
      null :
      MessageEndpointType.fromJson(json['type']);
    name = json['name'];
    address = json['address'];
    note = json['note'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (type != null)
      json['type'] = MessageEndpointTypeTypeTransformer().encode(type);
    if (name != null)
      json['name'] = name;
    if (address != null)
      json['address'] = address;
    if (note != null)
      json['note'] = note;
    return json;
  }

  static List<MessageEndpoint> listFromJson(List<dynamic> json) {
    return json == null ? List<MessageEndpoint>() : json.map((value) => MessageEndpoint.fromJson(value)).toList();
  }

  static Map<String, MessageEndpoint> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, MessageEndpoint>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = MessageEndpoint.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of MessageEndpoint-objects as value to a dart map
  static Map<String, List<MessageEndpoint>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<MessageEndpoint>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = MessageEndpoint.listFromJson(value);
       });
     }
     return map;
  }
}

