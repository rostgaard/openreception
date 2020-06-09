part of orf.api;



class CallApi {
  final ApiClient apiClient;

  CallApi([ApiClient apiClient]) : apiClient = apiClient ?? defaultApiClient;

  /// Get an active recording with HTTP info returned
  ///
  /// 
  Future<Response> getActiveRecordingWithHttpInfo(String channelId) async {
    Object postBody;

    // verify required params are set
    if(channelId == null) {
     throw ApiException(400, "Missing required param: channelId");
    }

    // create path and map variables
    String path = "/activerecording/{channelId}".replaceAll("{format}","json").replaceAll("{" + "channelId" + "}", channelId.toString());

    // query params
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String contentType = contentTypes.isNotEmpty ? contentTypes[0] : "application/json";
    List<String> authNames = ["ApiKeyAuth"];

    if(contentType.startsWith("multipart/form-data")) {
      bool hasFields = false;
      MultipartRequest mp = MultipartRequest(null, null);
      if(hasFields)
        postBody = mp;
    }
    else {
    }

    var response = await apiClient.invokeAPI(path,
                                             'GET',
                                             queryParams,
                                             postBody,
                                             headerParams,
                                             formParams,
                                             contentType,
                                             authNames);
    return response;
  }

  /// Get an active recording
  ///
  /// 
  Future<ActiveRecording> getActiveRecording(String channelId) async {
    Response response = await getActiveRecordingWithHttpInfo(channelId);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'ActiveRecording') as ActiveRecording;
    } else {
      return null;
    }
  }

  /// Get an AgentStatistics with HTTP info returned
  ///
  /// 
  Future<Response> getAgentStatisticsWithHttpInfo(int uid) async {
    Object postBody;

    // verify required params are set
    if(uid == null) {
     throw ApiException(400, "Missing required param: uid");
    }

    // create path and map variables
    String path = "/agentstatistics/{uid}".replaceAll("{format}","json").replaceAll("{" + "uid" + "}", uid.toString());

    // query params
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String contentType = contentTypes.isNotEmpty ? contentTypes[0] : "application/json";
    List<String> authNames = ["ApiKeyAuth"];

    if(contentType.startsWith("multipart/form-data")) {
      bool hasFields = false;
      MultipartRequest mp = MultipartRequest(null, null);
      if(hasFields)
        postBody = mp;
    }
    else {
    }

    var response = await apiClient.invokeAPI(path,
                                             'GET',
                                             queryParams,
                                             postBody,
                                             headerParams,
                                             formParams,
                                             contentType,
                                             authNames);
    return response;
  }

  /// Get an AgentStatistics
  ///
  /// 
  Future<AgentStatistics> getAgentStatistics(int uid) async {
    Response response = await getAgentStatisticsWithHttpInfo(uid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'AgentStatistics') as AgentStatistics;
    } else {
      return null;
    }
  }

  /// Get a call by ID with HTTP info returned
  ///
  /// 
  Future<Response> getCallWithHttpInfo(String callId) async {
    Object postBody;

    // verify required params are set
    if(callId == null) {
     throw ApiException(400, "Missing required param: callId");
    }

    // create path and map variables
    String path = "/call/{callId}".replaceAll("{format}","json").replaceAll("{" + "callId" + "}", callId.toString());

    // query params
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String contentType = contentTypes.isNotEmpty ? contentTypes[0] : "application/json";
    List<String> authNames = ["ApiKeyAuth"];

    if(contentType.startsWith("multipart/form-data")) {
      bool hasFields = false;
      MultipartRequest mp = MultipartRequest(null, null);
      if(hasFields)
        postBody = mp;
    }
    else {
    }

    var response = await apiClient.invokeAPI(path,
                                             'GET',
                                             queryParams,
                                             postBody,
                                             headerParams,
                                             formParams,
                                             contentType,
                                             authNames);
    return response;
  }

  /// Get a call by ID
  ///
  /// 
  Future<Call> getCall(String callId) async {
    Response response = await getCallWithHttpInfo(callId);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Call') as Call;
    } else {
      return null;
    }
  }

  /// Get a peer with HTTP info returned
  ///
  /// 
  Future<Response> getPeerWithHttpInfo(String peerid) async {
    Object postBody;

    // verify required params are set
    if(peerid == null) {
     throw ApiException(400, "Missing required param: peerid");
    }

    // create path and map variables
    String path = "/peer/{peerid}".replaceAll("{format}","json").replaceAll("{" + "peerid" + "}", peerid.toString());

    // query params
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String contentType = contentTypes.isNotEmpty ? contentTypes[0] : "application/json";
    List<String> authNames = ["ApiKeyAuth"];

    if(contentType.startsWith("multipart/form-data")) {
      bool hasFields = false;
      MultipartRequest mp = MultipartRequest(null, null);
      if(hasFields)
        postBody = mp;
    }
    else {
    }

    var response = await apiClient.invokeAPI(path,
                                             'GET',
                                             queryParams,
                                             postBody,
                                             headerParams,
                                             formParams,
                                             contentType,
                                             authNames);
    return response;
  }

  /// Get a peer
  ///
  /// 
  Future<Peer> getPeer(String peerid) async {
    Response response = await getPeerWithHttpInfo(peerid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Peer') as Peer;
    } else {
      return null;
    }
  }

  /// Get a call by ID with HTTP info returned
  ///
  /// 
  Future<Response> hangupCallWithHttpInfo(String callId) async {
    Object postBody;

    // verify required params are set
    if(callId == null) {
     throw ApiException(400, "Missing required param: callId");
    }

    // create path and map variables
    String path = "/call/{callId}/hangup".replaceAll("{format}","json").replaceAll("{" + "callId" + "}", callId.toString());

    // query params
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String contentType = contentTypes.isNotEmpty ? contentTypes[0] : "application/json";
    List<String> authNames = ["ApiKeyAuth"];

    if(contentType.startsWith("multipart/form-data")) {
      bool hasFields = false;
      MultipartRequest mp = MultipartRequest(null, null);
      if(hasFields)
        postBody = mp;
    }
    else {
    }

    var response = await apiClient.invokeAPI(path,
                                             'POST',
                                             queryParams,
                                             postBody,
                                             headerParams,
                                             formParams,
                                             contentType,
                                             authNames);
    return response;
  }

  /// Get a call by ID
  ///
  /// 
  Future<DeleteResponse> hangupCall(String callId) async {
    Response response = await hangupCallWithHttpInfo(callId);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'DeleteResponse') as DeleteResponse;
    } else {
      return null;
    }
  }

  /// Get a list of active recordings with HTTP info returned
  ///
  /// 
  Future<Response> listActiveRecordingsWithHttpInfo() async {
    Object postBody;

    // verify required params are set

    // create path and map variables
    String path = "/activerecording".replaceAll("{format}","json");

    // query params
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String contentType = contentTypes.isNotEmpty ? contentTypes[0] : "application/json";
    List<String> authNames = ["ApiKeyAuth"];

    if(contentType.startsWith("multipart/form-data")) {
      bool hasFields = false;
      MultipartRequest mp = MultipartRequest(null, null);
      if(hasFields)
        postBody = mp;
    }
    else {
    }

    var response = await apiClient.invokeAPI(path,
                                             'GET',
                                             queryParams,
                                             postBody,
                                             headerParams,
                                             formParams,
                                             contentType,
                                             authNames);
    return response;
  }

  /// Get a list of active recordings
  ///
  /// 
  Future<List<ActiveRecording>> listActiveRecordings() async {
    Response response = await listActiveRecordingsWithHttpInfo();
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<ActiveRecording>') as List).map((item) => item as ActiveRecording).toList();
    } else {
      return null;
    }
  }

  /// Get a list of AgentStatistics with HTTP info returned
  ///
  /// 
  Future<Response> listAgentStatisticsWithHttpInfo() async {
    Object postBody;

    // verify required params are set

    // create path and map variables
    String path = "/agentstatistics".replaceAll("{format}","json");

    // query params
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String contentType = contentTypes.isNotEmpty ? contentTypes[0] : "application/json";
    List<String> authNames = ["ApiKeyAuth"];

    if(contentType.startsWith("multipart/form-data")) {
      bool hasFields = false;
      MultipartRequest mp = MultipartRequest(null, null);
      if(hasFields)
        postBody = mp;
    }
    else {
    }

    var response = await apiClient.invokeAPI(path,
                                             'GET',
                                             queryParams,
                                             postBody,
                                             headerParams,
                                             formParams,
                                             contentType,
                                             authNames);
    return response;
  }

  /// Get a list of AgentStatistics
  ///
  /// 
  Future<List<AgentStatistics>> listAgentStatistics() async {
    Response response = await listAgentStatisticsWithHttpInfo();
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<AgentStatistics>') as List).map((item) => item as AgentStatistics).toList();
    } else {
      return null;
    }
  }

  /// Get a call by ID with HTTP info returned
  ///
  /// 
  Future<Response> listCallsWithHttpInfo() async {
    Object postBody;

    // verify required params are set

    // create path and map variables
    String path = "/call".replaceAll("{format}","json");

    // query params
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String contentType = contentTypes.isNotEmpty ? contentTypes[0] : "application/json";
    List<String> authNames = ["ApiKeyAuth"];

    if(contentType.startsWith("multipart/form-data")) {
      bool hasFields = false;
      MultipartRequest mp = MultipartRequest(null, null);
      if(hasFields)
        postBody = mp;
    }
    else {
    }

    var response = await apiClient.invokeAPI(path,
                                             'GET',
                                             queryParams,
                                             postBody,
                                             headerParams,
                                             formParams,
                                             contentType,
                                             authNames);
    return response;
  }

  /// Get a call by ID
  ///
  /// 
  Future<List<Call>> listCalls() async {
    Response response = await listCallsWithHttpInfo();
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<Call>') as List).map((item) => item as Call).toList();
    } else {
      return null;
    }
  }

  /// Get a list of peers with HTTP info returned
  ///
  /// 
  Future<Response> listPeersWithHttpInfo() async {
    Object postBody;

    // verify required params are set

    // create path and map variables
    String path = "/peer".replaceAll("{format}","json");

    // query params
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String contentType = contentTypes.isNotEmpty ? contentTypes[0] : "application/json";
    List<String> authNames = ["ApiKeyAuth"];

    if(contentType.startsWith("multipart/form-data")) {
      bool hasFields = false;
      MultipartRequest mp = MultipartRequest(null, null);
      if(hasFields)
        postBody = mp;
    }
    else {
    }

    var response = await apiClient.invokeAPI(path,
                                             'GET',
                                             queryParams,
                                             postBody,
                                             headerParams,
                                             formParams,
                                             contentType,
                                             authNames);
    return response;
  }

  /// Get a list of peers
  ///
  /// 
  Future<List<Peer>> listPeers() async {
    Response response = await listPeersWithHttpInfo();
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<Peer>') as List).map((item) => item as Peer).toList();
    } else {
      return null;
    }
  }

  /// Originate a new call with HTTP info returned
  ///
  /// 
  Future<Response> originateCallWithHttpInfo(OriginationRequest originationRequest) async {
    Object postBody = originationRequest;

    // verify required params are set
    if(originationRequest == null) {
     throw ApiException(400, "Missing required param: originationRequest");
    }

    // create path and map variables
    String path = "/call".replaceAll("{format}","json");

    // query params
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];

    String contentType = contentTypes.isNotEmpty ? contentTypes[0] : "application/json";
    List<String> authNames = ["ApiKeyAuth"];

    if(contentType.startsWith("multipart/form-data")) {
      bool hasFields = false;
      MultipartRequest mp = MultipartRequest(null, null);
      if(hasFields)
        postBody = mp;
    }
    else {
    }

    var response = await apiClient.invokeAPI(path,
                                             'POST',
                                             queryParams,
                                             postBody,
                                             headerParams,
                                             formParams,
                                             contentType,
                                             authNames);
    return response;
  }

  /// Originate a new call
  ///
  /// 
  Future<Call> originateCall(OriginationRequest originationRequest) async {
    Response response = await originateCallWithHttpInfo(originationRequest);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Call') as Call;
    } else {
      return null;
    }
  }

  /// Park a call by ID with HTTP info returned
  ///
  /// 
  Future<Response> parkCallWithHttpInfo(String callId) async {
    Object postBody;

    // verify required params are set
    if(callId == null) {
     throw ApiException(400, "Missing required param: callId");
    }

    // create path and map variables
    String path = "/call/{callId}/park".replaceAll("{format}","json").replaceAll("{" + "callId" + "}", callId.toString());

    // query params
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String contentType = contentTypes.isNotEmpty ? contentTypes[0] : "application/json";
    List<String> authNames = ["ApiKeyAuth"];

    if(contentType.startsWith("multipart/form-data")) {
      bool hasFields = false;
      MultipartRequest mp = MultipartRequest(null, null);
      if(hasFields)
        postBody = mp;
    }
    else {
    }

    var response = await apiClient.invokeAPI(path,
                                             'POST',
                                             queryParams,
                                             postBody,
                                             headerParams,
                                             formParams,
                                             contentType,
                                             authNames);
    return response;
  }

  /// Park a call by ID
  ///
  /// 
  Future<Call> parkCall(String callId) async {
    Response response = await parkCallWithHttpInfo(callId);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Call') as Call;
    } else {
      return null;
    }
  }

  /// Pick up a call by ID with HTTP info returned
  ///
  /// 
  Future<Response> pickupCallWithHttpInfo(String callId) async {
    Object postBody;

    // verify required params are set
    if(callId == null) {
     throw ApiException(400, "Missing required param: callId");
    }

    // create path and map variables
    String path = "/call/{callId}/pickup".replaceAll("{format}","json").replaceAll("{" + "callId" + "}", callId.toString());

    // query params
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String contentType = contentTypes.isNotEmpty ? contentTypes[0] : "application/json";
    List<String> authNames = ["ApiKeyAuth"];

    if(contentType.startsWith("multipart/form-data")) {
      bool hasFields = false;
      MultipartRequest mp = MultipartRequest(null, null);
      if(hasFields)
        postBody = mp;
    }
    else {
    }

    var response = await apiClient.invokeAPI(path,
                                             'POST',
                                             queryParams,
                                             postBody,
                                             headerParams,
                                             formParams,
                                             contentType,
                                             authNames);
    return response;
  }

  /// Pick up a call by ID
  ///
  /// 
  Future<Call> pickupCall(String callId) async {
    Response response = await pickupCallWithHttpInfo(callId);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Call') as Call;
    } else {
      return null;
    }
  }

  /// Reload server state from PBX with HTTP info returned
  ///
  /// 
  Future<Response> reloadCallStateWithHttpInfo() async {
    Object postBody;

    // verify required params are set

    // create path and map variables
    String path = "/manage/state-reload".replaceAll("{format}","json");

    // query params
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String contentType = contentTypes.isNotEmpty ? contentTypes[0] : "application/json";
    List<String> authNames = ["ApiKeyAuth"];

    if(contentType.startsWith("multipart/form-data")) {
      bool hasFields = false;
      MultipartRequest mp = MultipartRequest(null, null);
      if(hasFields)
        postBody = mp;
    }
    else {
    }

    var response = await apiClient.invokeAPI(path,
                                             'POST',
                                             queryParams,
                                             postBody,
                                             headerParams,
                                             formParams,
                                             contentType,
                                             authNames);
    return response;
  }

  /// Reload server state from PBX
  ///
  /// 
  Future<CommandSuccessResponse> reloadCallState() async {
    Response response = await reloadCallStateWithHttpInfo();
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'CommandSuccessResponse') as CommandSuccessResponse;
    } else {
      return null;
    }
  }

  /// Transfer a call by ID with HTTP info returned
  ///
  /// 
  Future<Response> transferCallWithHttpInfo(String callId, CallTransferRequest callTransferRequest) async {
    Object postBody = callTransferRequest;

    // verify required params are set
    if(callId == null) {
     throw ApiException(400, "Missing required param: callId");
    }
    if(callTransferRequest == null) {
     throw ApiException(400, "Missing required param: callTransferRequest");
    }

    // create path and map variables
    String path = "/call/{callId}/Transfer".replaceAll("{format}","json").replaceAll("{" + "callId" + "}", callId.toString());

    // query params
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = ["application/json"];

    String contentType = contentTypes.isNotEmpty ? contentTypes[0] : "application/json";
    List<String> authNames = ["ApiKeyAuth"];

    if(contentType.startsWith("multipart/form-data")) {
      bool hasFields = false;
      MultipartRequest mp = MultipartRequest(null, null);
      if(hasFields)
        postBody = mp;
    }
    else {
    }

    var response = await apiClient.invokeAPI(path,
                                             'POST',
                                             queryParams,
                                             postBody,
                                             headerParams,
                                             formParams,
                                             contentType,
                                             authNames);
    return response;
  }

  /// Transfer a call by ID
  ///
  /// 
  Future<Call> transferCall(String callId, CallTransferRequest callTransferRequest) async {
    Response response = await transferCallWithHttpInfo(callId, callTransferRequest);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Call') as Call;
    } else {
      return null;
    }
  }

}
