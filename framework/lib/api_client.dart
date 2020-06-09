part of orf.api;

class QueryParam {
  String name;
  String value;

  QueryParam(this.name, this.value);
}

class ApiClient {

  String basePath;
  var client = Client();

  Map<String, String> _defaultHeaderMap = {};
  Map<String, Authentication> _authentications = {};

  final _regList = RegExp(r'^List<(.*)>$');
  final _regMap = RegExp(r'^Map<String,(.*)>$');

  ApiClient({this.basePath = "http://localhost"}) {
    // Setup authentications (key: authentication name, value: authentication).
    _authentications['ApiKeyAuth'] = ApiKeyAuth("query", "token");
  }

  void addDefaultHeader(String key, String value) {
     _defaultHeaderMap[key] = value;
  }

  dynamic _deserialize(dynamic value, String targetType) {
    try {
      switch (targetType) {
        case 'String':
          return '$value';
        case 'int':
          return value is int ? value : int.parse('$value');
        case 'bool':
          return value is bool ? value : '$value'.toLowerCase() == 'true';
        case 'double':
          return value is double ? value : double.parse('$value');
        case 'ActiveRecording':
          return ActiveRecording.fromJson(value);
        case 'AgentStatistics':
          return AgentStatistics.fromJson(value);
        case 'BaseContact':
          return BaseContact.fromJson(value);
        case 'CalendarEntry':
          return CalendarEntry.fromJson(value);
        case 'Call':
          return Call.fromJson(value);
        case 'CallState':
          return new CallStateTypeTransformer().decode(value);
        case 'CallTransferRequest':
          return CallTransferRequest.fromJson(value);
        case 'CallerInfo':
          return CallerInfo.fromJson(value);
        case 'ChangeType':
          return new ChangeTypeTypeTransformer().decode(value);
        case 'ClientConnection':
          return ClientConnection.fromJson(value);
        case 'CommandSuccessResponse':
          return CommandSuccessResponse.fromJson(value);
        case 'Commit':
          return Commit.fromJson(value);
        case 'Configuration':
          return Configuration.fromJson(value);
        case 'DeleteResponse':
          return DeleteResponse.fromJson(value);
        case 'Message':
          return Message.fromJson(value);
        case 'MessageContext':
          return MessageContext.fromJson(value);
        case 'MessageEndpoint':
          return MessageEndpoint.fromJson(value);
        case 'MessageEndpointType':
          return new MessageEndpointTypeTypeTransformer().decode(value);
        case 'MessageFilter':
          return MessageFilter.fromJson(value);
        case 'MessageFlag':
          return MessageFlag.fromJson(value);
        case 'MessageQueueEntry':
          return MessageQueueEntry.fromJson(value);
        case 'MessageState':
          return new MessageStateTypeTransformer().decode(value);
        case 'NotificationSendPayload':
          return NotificationSendPayload.fromJson(value);
        case 'NotificationSendRequest':
          return NotificationSendRequest.fromJson(value);
        case 'NotificationSendResponse':
          return NotificationSendResponse.fromJson(value);
        case 'NotificationSendResponseStatus':
          return NotificationSendResponseStatus.fromJson(value);
        case 'ObjectChange':
          return ObjectChange.fromJson(value);
        case 'ObjectType':
          return new ObjectTypeTypeTransformer().decode(value);
        case 'Organization':
          return Organization.fromJson(value);
        case 'OrganizationReference':
          return OrganizationReference.fromJson(value);
        case 'OriginationContext':
          return OriginationContext.fromJson(value);
        case 'OriginationRequest':
          return OriginationRequest.fromJson(value);
        case 'Peer':
          return Peer.fromJson(value);
        case 'PeerAccount':
          return PeerAccount.fromJson(value);
        case 'PhoneNumber':
          return PhoneNumber.fromJson(value);
        case 'Reception':
          return Reception.fromJson(value);
        case 'ReceptionAttributes':
          return ReceptionAttributes.fromJson(value);
        case 'ReceptionContact':
          return ReceptionContact.fromJson(value);
        case 'ReceptionReference':
          return ReceptionReference.fromJson(value);
        case 'ResponseCode':
          return new ResponseCodeTypeTransformer().decode(value);
        case 'ServerConfiguration':
          return ServerConfiguration.fromJson(value);
        case 'User':
          return User.fromJson(value);
        case 'UserReference':
          return UserReference.fromJson(value);
        case 'UserStatus':
          return UserStatus.fromJson(value);
        default:
          {
            Match match;
            if (value is List &&
                (match = _regList.firstMatch(targetType)) != null) {
              var newTargetType = match[1];
              return value.map((v) => _deserialize(v, newTargetType)).toList();
            } else if (value is Map &&
                (match = _regMap.firstMatch(targetType)) != null) {
              var newTargetType = match[1];
              return Map.fromIterables(value.keys,
                  value.values.map((v) => _deserialize(v, newTargetType)));
            }
          }
      }
    } on Exception catch (e, stack) {
      throw ApiException.withInner(500, 'Exception during deserialization.', e, stack);
    }
    throw ApiException(500, 'Could not find a suitable class for deserialization');
  }

  dynamic deserialize(String json, String targetType) {
    // Remove all spaces.  Necessary for reg expressions as well.
    targetType = targetType.replaceAll(' ', '');

    if (targetType == 'String') return json;

    var decodedJson = jsonDecode(json);
    return _deserialize(decodedJson, targetType);
  }

  String serialize(Object obj) {
    String serialized = '';
    if (obj == null) {
      serialized = '';
    } else {
      serialized = json.encode(obj);
    }
    return serialized;
  }

  // We don't use a Map<String, String> for queryParams.
  // If collectionFormat is 'multi' a key might appear multiple times.
  Future<Response> invokeAPI(String path,
                             String method,
                             Iterable<QueryParam> queryParams,
                             Object body,
                             Map<String, String> headerParams,
                             Map<String, String> formParams,
                             String contentType,
                             List<String> authNames) async {

    _updateParamsForAuth(authNames, queryParams, headerParams);

    var ps = queryParams
      .where((p) => p.value != null)
      .map((p) => '${p.name}=${Uri.encodeQueryComponent(p.value)}');

    String queryString = ps.isNotEmpty ?
                         '?' + ps.join('&') :
                         '';

    String url = basePath + path + queryString;

    headerParams.addAll(_defaultHeaderMap);
    headerParams['Content-Type'] = contentType;

    if(body is MultipartRequest) {
      var request = MultipartRequest(method, Uri.parse(url));
      request.fields.addAll(body.fields);
      request.files.addAll(body.files);
      request.headers.addAll(body.headers);
      request.headers.addAll(headerParams);
      var response = await client.send(request);
      return Response.fromStream(response);
    } else {
      var msgBody = contentType == "application/x-www-form-urlencoded" ? formParams : serialize(body);
      switch(method) {
        case "POST":
          return client.post(url, headers: headerParams, body: msgBody);
        case "PUT":
          return client.put(url, headers: headerParams, body: msgBody);
        case "DELETE":
          return client.delete(url, headers: headerParams);
        case "PATCH":
          return client.patch(url, headers: headerParams, body: msgBody);
        case "HEAD":
          return client.head(url, headers: headerParams);
        default:
          return client.get(url, headers: headerParams);
      }
    }
  }

  /// Update query and header parameters based on authentication settings.
  /// @param authNames The authentications to apply
  void _updateParamsForAuth(List<String> authNames, List<QueryParam> queryParams, Map<String, String> headerParams) {
    authNames.forEach((authName) {
      Authentication auth = _authentications[authName];
      if (auth == null) throw ArgumentError("Authentication undefined: " + authName);
      auth.applyToParams(queryParams, headerParams);
    });
  }

  T getAuthentication<T extends Authentication>(String name) {
    var authentication = _authentications[name];

    return authentication is T ? authentication : null;
  }
}
