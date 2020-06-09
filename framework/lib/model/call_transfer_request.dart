part of orf.api;

class CallTransferRequest {
  
  String destination = null;
  CallTransferRequest();

  @override
  String toString() {
    return 'CallTransferRequest[destination=$destination, ]';
  }

  CallTransferRequest.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    destination = json['destination'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (destination != null)
      json['destination'] = destination;
    return json;
  }

  static List<CallTransferRequest> listFromJson(List<dynamic> json) {
    return json == null ? List<CallTransferRequest>() : json.map((value) => CallTransferRequest.fromJson(value)).toList();
  }

  static Map<String, CallTransferRequest> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, CallTransferRequest>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = CallTransferRequest.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of CallTransferRequest-objects as value to a dart map
  static Map<String, List<CallTransferRequest>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<CallTransferRequest>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = CallTransferRequest.listFromJson(value);
       });
     }
     return map;
  }
}

