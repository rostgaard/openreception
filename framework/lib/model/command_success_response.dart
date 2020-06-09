part of orf.api;

class CommandSuccessResponse {
  
  ResponseCode status = null;
  //enum statusEnum {  ok,  error,  };{
  
  List<String> operationsRequested = [];
  
  List<String> operationsSucceeded = [];
  
  List<String> operationsFailed = [];
  CommandSuccessResponse();

  @override
  String toString() {
    return 'CommandSuccessResponse[status=$status, operationsRequested=$operationsRequested, operationsSucceeded=$operationsSucceeded, operationsFailed=$operationsFailed, ]';
  }

  CommandSuccessResponse.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    status = (json['status'] == null) ?
      null :
      ResponseCode.fromJson(json['status']);
    operationsRequested = (json['operations-requested'] == null) ?
      null :
      (json['operations-requested'] as List).cast<String>();
    operationsSucceeded = (json['operations-succeeded'] == null) ?
      null :
      (json['operations-succeeded'] as List).cast<String>();
    operationsFailed = (json['operations-failed'] == null) ?
      null :
      (json['operations-failed'] as List).cast<String>();
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (status != null)
      json['status'] = status;
    if (operationsRequested != null)
      json['operations-requested'] = operationsRequested;
    if (operationsSucceeded != null)
      json['operations-succeeded'] = operationsSucceeded;
    if (operationsFailed != null)
      json['operations-failed'] = operationsFailed;
    return json;
  }

  static List<CommandSuccessResponse> listFromJson(List<dynamic> json) {
    return json == null ? List<CommandSuccessResponse>() : json.map((value) => CommandSuccessResponse.fromJson(value)).toList();
  }

  static Map<String, CommandSuccessResponse> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, CommandSuccessResponse>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = CommandSuccessResponse.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of CommandSuccessResponse-objects as value to a dart map
  static Map<String, List<CommandSuccessResponse>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<CommandSuccessResponse>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = CommandSuccessResponse.listFromJson(value);
       });
     }
     return map;
  }
}

