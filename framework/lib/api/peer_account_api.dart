part of orf.api;



class PeerAccountApi {
  final ApiClient apiClient;

  PeerAccountApi([ApiClient apiClient]) : apiClient = apiClient ?? defaultApiClient;

  /// Add a new PeerAccount with HTTP info returned
  ///
  /// 
  Future<Response> addPeerAccountWithHttpInfo(PeerAccount peerAccount) async {
    Object postBody = peerAccount;

    // verify required params are set
    if(peerAccount == null) {
     throw ApiException(400, "Missing required param: peerAccount");
    }

    // create path and map variables
    String path = "/peeraccount".replaceAll("{format}","json");

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

  /// Add a new PeerAccount
  ///
  /// 
  Future<PeerAccount> addPeerAccount(PeerAccount peerAccount) async {
    Response response = await addPeerAccountWithHttpInfo(peerAccount);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'PeerAccount') as PeerAccount;
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> deletePeerAccountWithHttpInfo(String peerId) async {
    Object postBody;

    // verify required params are set
    if(peerId == null) {
     throw ApiException(400, "Missing required param: peerId");
    }

    // create path and map variables
    String path = "/peeraccount/{peerId}".replaceAll("{format}","json").replaceAll("{" + "peerId" + "}", peerId.toString());

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
                                             'DELETE',
                                             queryParams,
                                             postBody,
                                             headerParams,
                                             formParams,
                                             contentType,
                                             authNames);
    return response;
  }

  /// 
  ///
  /// 
  Future<DeleteResponse> deletePeerAccount(String peerId) async {
    Response response = await deletePeerAccountWithHttpInfo(peerId);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'DeleteResponse') as DeleteResponse;
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> deployPeerAccountWithHttpInfo(String peerId) async {
    Object postBody;

    // verify required params are set
    if(peerId == null) {
     throw ApiException(400, "Missing required param: peerId");
    }

    // create path and map variables
    String path = "/peeraccount/{peerId}/deploy".replaceAll("{format}","json").replaceAll("{" + "peerId" + "}", peerId.toString());

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

  /// 
  ///
  /// 
  Future<List<String>> deployPeerAccount(String peerId) async {
    Response response = await deployPeerAccountWithHttpInfo(peerId);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<String>') as List).map((item) => item as String).toList();
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> peerAccountWithHttpInfo(String peerId) async {
    Object postBody;

    // verify required params are set
    if(peerId == null) {
     throw ApiException(400, "Missing required param: peerId");
    }

    // create path and map variables
    String path = "/peeraccount/{peerId}".replaceAll("{format}","json").replaceAll("{" + "peerId" + "}", peerId.toString());

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

  /// 
  ///
  /// 
  Future<PeerAccount> peerAccount(String peerId) async {
    Response response = await peerAccountWithHttpInfo(peerId);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'PeerAccount') as PeerAccount;
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// List the current available peerAccounts in the system
  Future<Response> peerAccountsWithHttpInfo() async {
    Object postBody;

    // verify required params are set

    // create path and map variables
    String path = "/peeraccount".replaceAll("{format}","json");

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

  /// 
  ///
  /// List the current available peerAccounts in the system
  Future<List<PeerAccount>> peerAccounts() async {
    Response response = await peerAccountsWithHttpInfo();
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<PeerAccount>') as List).map((item) => item as PeerAccount).toList();
    } else {
      return null;
    }
  }

}
