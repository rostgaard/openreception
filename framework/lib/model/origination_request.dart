part of orf.api;

class OriginationRequest {
  
  String extension_ = null;
  
  OriginationContext context = null;
  OriginationRequest();

  @override
  String toString() {
    return 'OriginationRequest[extension_=$extension_, context=$context, ]';
  }

  OriginationRequest.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    extension_ = json['extension'];
    context = (json['context'] == null) ?
      null :
      OriginationContext.fromJson(json['context']);
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (extension_ != null)
      json['extension'] = extension_;
    if (context != null)
      json['context'] = context;
    return json;
  }

  static List<OriginationRequest> listFromJson(List<dynamic> json) {
    return json == null ? List<OriginationRequest>() : json.map((value) => OriginationRequest.fromJson(value)).toList();
  }

  static Map<String, OriginationRequest> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, OriginationRequest>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = OriginationRequest.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of OriginationRequest-objects as value to a dart map
  static Map<String, List<OriginationRequest>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<OriginationRequest>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = OriginationRequest.listFromJson(value);
       });
     }
     return map;
  }
}

