part of orf.api;



class ContactApi {
  final ApiClient apiClient;

  ContactApi([ApiClient apiClient]) : apiClient = apiClient ?? defaultApiClient;

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> addToReceptionWithHttpInfo(int cid, int rid, ReceptionAttributes receptionAttributes) async {
    Object postBody = receptionAttributes;

    // verify required params are set
    if(cid == null) {
     throw ApiException(400, "Missing required param: cid");
    }
    if(rid == null) {
     throw ApiException(400, "Missing required param: rid");
    }
    if(receptionAttributes == null) {
     throw ApiException(400, "Missing required param: receptionAttributes");
    }

    // create path and map variables
    String path = "/contact/{cid}/reception/{rid}".replaceAll("{format}","json").replaceAll("{" + "cid" + "}", cid.toString()).replaceAll("{" + "rid" + "}", rid.toString());

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
  Future<BaseContact> addToReception(int cid, int rid, ReceptionAttributes receptionAttributes) async {
    Response response = await addToReceptionWithHttpInfo(cid, rid, receptionAttributes);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'BaseContact') as BaseContact;
    } else {
      return null;
    }
  }

  /// Gets the contact current histories with HTTP info returned
  ///
  /// 
  Future<Response> contactChangelogWithHttpInfo(int cid) async {
    Object postBody;

    // verify required params are set
    if(cid == null) {
     throw ApiException(400, "Missing required param: cid");
    }

    // create path and map variables
    String path = "/changes/contact/{cid}/changelog".replaceAll("{format}","json").replaceAll("{" + "cid" + "}", cid.toString());

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

  /// Gets the contact current histories
  ///
  /// 
  Future<String> contactChangelog(int cid) async {
    Response response = await contactChangelogWithHttpInfo(cid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'String') as String;
    } else {
      return null;
    }
  }

  /// Gets the contact current histories with HTTP info returned
  ///
  /// 
  Future<Response> contactHistoriesWithHttpInfo() async {
    Object postBody;

    // verify required params are set

    // create path and map variables
    String path = "/changes/contact".replaceAll("{format}","json");

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

  /// Gets the contact current histories
  ///
  /// 
  Future<List<Commit>> contactHistories() async {
    Response response = await contactHistoriesWithHttpInfo();
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<Commit>') as List).map((item) => item as Commit).toList();
    } else {
      return null;
    }
  }

  /// Gets the contact current histories with HTTP info returned
  ///
  /// 
  Future<Response> contactHistoryWithHttpInfo(int cid) async {
    Object postBody;

    // verify required params are set
    if(cid == null) {
     throw ApiException(400, "Missing required param: cid");
    }

    // create path and map variables
    String path = "/changes/contact/{cid}".replaceAll("{format}","json").replaceAll("{" + "cid" + "}", cid.toString());

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

  /// Gets the contact current histories
  ///
  /// 
  Future<List<Commit>> contactHistory(int cid) async {
    Response response = await contactHistoryWithHttpInfo(cid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<Commit>') as List).map((item) => item as Commit).toList();
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> contactOrganizationsWithHttpInfo(int cid) async {
    Object postBody;

    // verify required params are set
    if(cid == null) {
     throw ApiException(400, "Missing required param: cid");
    }

    // create path and map variables
    String path = "/contact/{cid}/organization".replaceAll("{format}","json").replaceAll("{" + "cid" + "}", cid.toString());

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
  Future<List<OrganizationReference>> contactOrganizations(int cid) async {
    Response response = await contactOrganizationsWithHttpInfo(cid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<OrganizationReference>') as List).map((item) => item as OrganizationReference).toList();
    } else {
      return null;
    }
  }

  /// Gets the contact current histories with HTTP info returned
  ///
  /// 
  Future<Response> contactReceptionChangelogWithHttpInfo(int cid) async {
    Object postBody;

    // verify required params are set
    if(cid == null) {
     throw ApiException(400, "Missing required param: cid");
    }

    // create path and map variables
    String path = "/changes/contact/{cid}/reception/changelog".replaceAll("{format}","json").replaceAll("{" + "cid" + "}", cid.toString());

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

  /// Gets the contact current histories
  ///
  /// 
  Future<String> contactReceptionChangelog(int cid) async {
    Response response = await contactReceptionChangelogWithHttpInfo(cid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'String') as String;
    } else {
      return null;
    }
  }

  /// Gets the contact current histories with HTTP info returned
  ///
  /// 
  Future<Response> contactReceptionHistoryWithHttpInfo(int cid, int rid) async {
    Object postBody;

    // verify required params are set
    if(cid == null) {
     throw ApiException(400, "Missing required param: cid");
    }
    if(rid == null) {
     throw ApiException(400, "Missing required param: rid");
    }

    // create path and map variables
    String path = "/changes/contact/{cid}/reception/{rid}".replaceAll("{format}","json").replaceAll("{" + "cid" + "}", cid.toString()).replaceAll("{" + "rid" + "}", rid.toString());

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

  /// Gets the contact current histories
  ///
  /// 
  Future<List<Commit>> contactReceptionHistory(int cid, int rid) async {
    Response response = await contactReceptionHistoryWithHttpInfo(cid, rid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<Commit>') as List).map((item) => item as Commit).toList();
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> contactReceptionsWithHttpInfo(int cid) async {
    Object postBody;

    // verify required params are set
    if(cid == null) {
     throw ApiException(400, "Missing required param: cid");
    }

    // create path and map variables
    String path = "/contact/{cid}/reception".replaceAll("{format}","json").replaceAll("{" + "cid" + "}", cid.toString());

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
  Future<List<ReceptionReference>> contactReceptions(int cid) async {
    Response response = await contactReceptionsWithHttpInfo(cid);
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
  Future<Response> contactsByReceptionWithHttpInfo(int rid) async {
    Object postBody;

    // verify required params are set
    if(rid == null) {
     throw ApiException(400, "Missing required param: rid");
    }

    // create path and map variables
    String path = "/contact/list/reception/{rid}".replaceAll("{format}","json").replaceAll("{" + "rid" + "}", rid.toString());

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
  Future<List<ReceptionContact>> contactsByReception(int rid) async {
    Response response = await contactsByReceptionWithHttpInfo(rid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<ReceptionContact>') as List).map((item) => item as ReceptionContact).toList();
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> createBaseContactWithHttpInfo(BaseContact baseContact) async {
    Object postBody = baseContact;

    // verify required params are set
    if(baseContact == null) {
     throw ApiException(400, "Missing required param: baseContact");
    }

    // create path and map variables
    String path = "/contact".replaceAll("{format}","json");

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
  Future<BaseContact> createBaseContact(BaseContact baseContact) async {
    Response response = await createBaseContactWithHttpInfo(baseContact);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'BaseContact') as BaseContact;
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> getBaseContactWithHttpInfo(int cid) async {
    Object postBody;

    // verify required params are set
    if(cid == null) {
     throw ApiException(400, "Missing required param: cid");
    }

    // create path and map variables
    String path = "/contact/{cid}".replaceAll("{format}","json").replaceAll("{" + "cid" + "}", cid.toString());

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
  Future<BaseContact> getBaseContact(int cid) async {
    Response response = await getBaseContactWithHttpInfo(cid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'BaseContact') as BaseContact;
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> getBaseContactsWithHttpInfo() async {
    Object postBody;

    // verify required params are set

    // create path and map variables
    String path = "/contact".replaceAll("{format}","json");

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
  Future<List<BaseContact>> getBaseContacts() async {
    Response response = await getBaseContactsWithHttpInfo();
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<BaseContact>') as List).map((item) => item as BaseContact).toList();
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> listByOrganizationWithHttpInfo(int oid) async {
    Object postBody;

    // verify required params are set
    if(oid == null) {
     throw ApiException(400, "Missing required param: oid");
    }

    // create path and map variables
    String path = "/contact/organization/{oid}".replaceAll("{format}","json").replaceAll("{" + "oid" + "}", oid.toString());

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
  Future<List<BaseContact>> listByOrganization(int oid) async {
    Response response = await listByOrganizationWithHttpInfo(oid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return (apiClient.deserialize(_decodeBodyBytes(response), 'List<BaseContact>') as List).map((item) => item as BaseContact).toList();
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> listByReceptionWithHttpInfo(int rid) async {
    Object postBody;

    // verify required params are set
    if(rid == null) {
     throw ApiException(400, "Missing required param: rid");
    }

    // create path and map variables
    String path = "/contact/reception/{rid}".replaceAll("{format}","json").replaceAll("{" + "rid" + "}", rid.toString());

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
  Future<ReceptionContact> listByReception(int rid) async {
    Response response = await listByReceptionWithHttpInfo(rid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'ReceptionContact') as ReceptionContact;
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> receptionContactWithHttpInfo(int cid, int rid) async {
    Object postBody;

    // verify required params are set
    if(cid == null) {
     throw ApiException(400, "Missing required param: cid");
    }
    if(rid == null) {
     throw ApiException(400, "Missing required param: rid");
    }

    // create path and map variables
    String path = "/contact/{cid}/reception/{rid}".replaceAll("{format}","json").replaceAll("{" + "cid" + "}", cid.toString()).replaceAll("{" + "rid" + "}", rid.toString());

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
  Future<ReceptionAttributes> receptionContact(int cid, int rid) async {
    Response response = await receptionContactWithHttpInfo(cid, rid);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'ReceptionAttributes') as ReceptionAttributes;
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> removeBaseContactWithHttpInfo(int cid) async {
    Object postBody;

    // verify required params are set
    if(cid == null) {
     throw ApiException(400, "Missing required param: cid");
    }

    // create path and map variables
    String path = "/contact/{cid}".replaceAll("{format}","json").replaceAll("{" + "cid" + "}", cid.toString());

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
  Future<DeleteResponse> removeBaseContact(int cid) async {
    Response response = await removeBaseContactWithHttpInfo(cid);
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
  Future<Response> removeFromReceptionWithHttpInfo(int cid, int rid) async {
    Object postBody;

    // verify required params are set
    if(cid == null) {
     throw ApiException(400, "Missing required param: cid");
    }
    if(rid == null) {
     throw ApiException(400, "Missing required param: rid");
    }

    // create path and map variables
    String path = "/contact/{cid}/reception/{rid}".replaceAll("{format}","json").replaceAll("{" + "cid" + "}", cid.toString()).replaceAll("{" + "rid" + "}", rid.toString());

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
  Future<DeleteResponse> removeFromReception(int cid, int rid) async {
    Response response = await removeFromReceptionWithHttpInfo(cid, rid);
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
  Future<Response> updateBaseContactWithHttpInfo(int cid, BaseContact baseContact) async {
    Object postBody = baseContact;

    // verify required params are set
    if(cid == null) {
     throw ApiException(400, "Missing required param: cid");
    }
    if(baseContact == null) {
     throw ApiException(400, "Missing required param: baseContact");
    }

    // create path and map variables
    String path = "/contact/{cid}".replaceAll("{format}","json").replaceAll("{" + "cid" + "}", cid.toString());

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
  Future<BaseContact> updateBaseContact(int cid, BaseContact baseContact) async {
    Response response = await updateBaseContactWithHttpInfo(cid, baseContact);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'BaseContact') as BaseContact;
    } else {
      return null;
    }
  }

  ///  with HTTP info returned
  ///
  /// 
  Future<Response> updateReceptionDataWithHttpInfo(int cid, int rid, ReceptionAttributes receptionAttributes) async {
    Object postBody = receptionAttributes;

    // verify required params are set
    if(cid == null) {
     throw ApiException(400, "Missing required param: cid");
    }
    if(rid == null) {
     throw ApiException(400, "Missing required param: rid");
    }
    if(receptionAttributes == null) {
     throw ApiException(400, "Missing required param: receptionAttributes");
    }

    // create path and map variables
    String path = "/contact/{cid}/reception/{rid}".replaceAll("{format}","json").replaceAll("{" + "cid" + "}", cid.toString()).replaceAll("{" + "rid" + "}", rid.toString());

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
  Future<BaseContact> updateReceptionData(int cid, int rid, ReceptionAttributes receptionAttributes) async {
    Response response = await updateReceptionDataWithHttpInfo(cid, rid, receptionAttributes);
    if(response.statusCode >= 400) {
      throw ApiException(response.statusCode, _decodeBodyBytes(response));
    } else if(response.body != null) {
      return apiClient.deserialize(_decodeBodyBytes(response), 'BaseContact') as BaseContact;
    } else {
      return null;
    }
  }

}
