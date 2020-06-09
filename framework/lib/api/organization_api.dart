part of orf.api;



class OrganizationApi {
  final ApiClient apiClient;

  OrganizationApi([ApiClient apiClient]) : apiClient = apiClient ?? defaultApiClient;

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> createOrgWithHttpInfo(Organization organization) async {
    Object postBody = organization;

    // verify required params are set
    if(organization == null) {
     throw ApiException(400, "Missing required param: organization");
    }

    // create path and map variables
    String path = "/organization".replaceAll("{format}","json");

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

  /// 
  ///
  /// 
  Future<OrganizationReference> createOrg(Organization organization) async {
    Response response = await createOrgWithHttpInfo(organization);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'OrganizationReference') as OrganizationReference;
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> deleteWithHttpInfo(int oid) async {
    Object postBody;

    // verify required params are set
    if(oid == null) {
     throw ApiException(400, "Missing required param: oid");
    }

    // create path and map variables
    String path = "/organization/{oid}".replaceAll("{format}","json").replaceAll("{" + "oid" + "}", oid.toString());

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
  Future<DeleteResponse> delete(int oid) async {
    Response response = await deleteWithHttpInfo(oid);
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
  Future<Response> fetchWithHttpInfo(int oid) async {
    Object postBody;

    // verify required params are set
    if(oid == null) {
     throw ApiException(400, "Missing required param: oid");
    }

    // create path and map variables
    String path = "/organization/{oid}".replaceAll("{format}","json").replaceAll("{" + "oid" + "}", oid.toString());

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
  Future<Organization> fetch(int oid) async {
    Response response = await fetchWithHttpInfo(oid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'Organization') as Organization;
    } else {
      return null;
    }
  }

  /// Gets the organization current histories with HTTP info returned
  ///
  /// 
  Future<Response> organizationChangelogWithHttpInfo(int oid) async {
    Object postBody;

    // verify required params are set
    if(oid == null) {
     throw ApiException(400, "Missing required param: oid");
    }

    // create path and map variables
    String path = "/changes/organization/{oid}/changelog".replaceAll("{format}","json").replaceAll("{" + "oid" + "}", oid.toString());

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

  /// Gets the organization current histories
  ///
  /// 
  Future<String> organizationChangelog(int oid) async {
    Response response = await organizationChangelogWithHttpInfo(oid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'String') as String;
    } else {
      return null;
    }
  }

  /// Gets the organization current contacts with HTTP info returned
  ///
  /// 
  Future<Response> organizationContactsWithHttpInfo(int oid) async {
    Object postBody;

    // verify required params are set
    if(oid == null) {
     throw ApiException(400, "Missing required param: oid");
    }

    // create path and map variables
    String path = "/organization/{oid}/contact".replaceAll("{format}","json").replaceAll("{" + "oid" + "}", oid.toString());

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

  /// Gets the organization current contacts
  ///
  /// 
  Future<List<BaseContact>> organizationContacts(int oid) async {
    Response response = await organizationContactsWithHttpInfo(oid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<BaseContact>') as List).map((item) => item as BaseContact).toList();
    } else {
      return null;
    }
  }

  /// Gets the organization current histories with HTTP info returned
  ///
  /// 
  Future<Response> organizationHistoriesWithHttpInfo() async {
    Object postBody;

    // verify required params are set

    // create path and map variables
    String path = "/changes/organization".replaceAll("{format}","json");

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

  /// Gets the organization current histories
  ///
  /// 
  Future<List<Commit>> organizationHistories() async {
    Response response = await organizationHistoriesWithHttpInfo();
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<Commit>') as List).map((item) => item as Commit).toList();
    } else {
      return null;
    }
  }

  /// Gets the organization current histories with HTTP info returned
  ///
  /// 
  Future<Response> organizationHistoryWithHttpInfo(int oid) async {
    Object postBody;

    // verify required params are set
    if(oid == null) {
     throw ApiException(400, "Missing required param: oid");
    }

    // create path and map variables
    String path = "/changes/organization/{oid}".replaceAll("{format}","json").replaceAll("{" + "oid" + "}", oid.toString());

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

  /// Gets the organization current histories
  ///
  /// 
  Future<List<Commit>> organizationHistory(int oid) async {
    Response response = await organizationHistoryWithHttpInfo(oid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<Commit>') as List).map((item) => item as Commit).toList();
    } else {
      return null;
    }
  }

  /// Gets the organization current receptions with HTTP info returned
  ///
  /// 
  Future<Response> organizationReceptionsWithHttpInfo(int oid) async {
    Object postBody;

    // verify required params are set
    if(oid == null) {
     throw ApiException(400, "Missing required param: oid");
    }

    // create path and map variables
    String path = "/organization/{oid}/reception".replaceAll("{format}","json").replaceAll("{" + "oid" + "}", oid.toString());

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

  /// Gets the organization current receptions
  ///
  /// 
  Future<List<ReceptionReference>> organizationReceptions(int oid) async {
    Response response = await organizationReceptionsWithHttpInfo(oid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<ReceptionReference>') as List).map((item) => item as ReceptionReference).toList();
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> orgsWithHttpInfo() async {
    Object postBody;

    // verify required params are set

    // create path and map variables
    String path = "/organization".replaceAll("{format}","json");

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
  Future<List<OrganizationReference>> orgs() async {
    Response response = await orgsWithHttpInfo();
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<OrganizationReference>') as List).map((item) => item as OrganizationReference).toList();
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> updateWithHttpInfo(int oid, Organization organization) async {
    Object postBody = organization;

    // verify required params are set
    if(oid == null) {
     throw ApiException(400, "Missing required param: oid");
    }
    if(organization == null) {
     throw ApiException(400, "Missing required param: organization");
    }

    // create path and map variables
    String path = "/organization/{oid}".replaceAll("{format}","json").replaceAll("{" + "oid" + "}", oid.toString());

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
                                             'PUT',
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
  Future<OrganizationReference> update(int oid, Organization organization) async {
    Response response = await updateWithHttpInfo(oid, organization);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'OrganizationReference') as OrganizationReference;
    } else {
      return null;
    }
  }

}
