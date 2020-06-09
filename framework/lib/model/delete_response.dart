part of orf.api;

class DeleteResponse {
  
  ResponseCode status = null;
  //enum statusEnum {  ok,  error,  };{
  
  String description = null;
  DeleteResponse();

  @override
  String toString() {
    return 'DeleteResponse[status=$status, description=$description, ]';
  }

  DeleteResponse.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    status = (json['status'] == null) ?
      null :
      ResponseCode.fromJson(json['status']);
    description = json['description'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (status != null)
      json['status'] = status;
    if (description != null)
      json['description'] = description;
    return json;
  }

  static List<DeleteResponse> listFromJson(List<dynamic> json) {
    return json == null ? List<DeleteResponse>() : json.map((value) => DeleteResponse.fromJson(value)).toList();
  }

  static Map<String, DeleteResponse> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, DeleteResponse>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = DeleteResponse.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of DeleteResponse-objects as value to a dart map
  static Map<String, List<DeleteResponse>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<DeleteResponse>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = DeleteResponse.listFromJson(value);
       });
     }
     return map;
  }
}

