part of orf.api;



class ClientConfigurationApi {
  final ApiClient apiClient;

  ClientConfigurationApi([ApiClient apiClient]) : apiClient = apiClient ?? defaultApiClient;

  ///  with HTTP info returned
  ///
  /// Get the current configuration
  Future<Response> configWithHttpInfo() async {
    Object postBody;

    // verify required params are set

    // create path and map variables
    String path = "/configuration".replaceAll("{format}","json");

    // query params
    List<QueryParam> queryParams = [];
    Map<String, String> headerParams = {};
    Map<String, String> formParams = {};

    List<String> contentTypes = [];

    String contentType = contentTypes.isNotEmpty ? contentTypes[0] : "application/json";
    List<String> authNames = [];

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
  /// Get the current configuration
  Future<Configuration> config() async {
    Response response = await configWithHttpInfo();
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Configuration') as Configuration;
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// Set an endpoint of a server type
  Future<Response> setServerWithHttpInfo(ServerConfiguration serverConfiguration) async {
    Object postBody = serverConfiguration;

    // verify required params are set
    if(serverConfiguration == null) {
     throw ApiException(400, "Missing required param: serverConfiguration");
    }

    // create path and map variables
    String path = "/configuration".replaceAll("{format}","json");

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
                                             'PATCH',
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
  /// Set an endpoint of a server type
  Future<Configuration> setServer(ServerConfiguration serverConfiguration) async {
    Response response = await setServerWithHttpInfo(serverConfiguration);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Configuration') as Configuration;
    } else {
      return null;
    }
  }

}
