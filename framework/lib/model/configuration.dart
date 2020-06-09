part of orf.api;

class Configuration {
  
  String authServerUri = null;
  
  String calendarServerUri = null;
  
  String callFlowServerUri = null;
  
  String cdrServerUri = null;
  
  String contactServerUri = null;
  
  String dialplanServerUri = null;
  
  bool hideInboundCallerId = null;
  
  String messageServerUri = null;
  
  List<String> myIdentifiers = [];
  
  String notificationServerUri = null;
  
  String notificationSocketUri = null;
  
  String receptionServerUri = null;
  
  String systemLanguage = null;
  
  String userServerUri = null;
  Configuration();

  @override
  String toString() {
    return 'Configuration[authServerUri=$authServerUri, calendarServerUri=$calendarServerUri, callFlowServerUri=$callFlowServerUri, cdrServerUri=$cdrServerUri, contactServerUri=$contactServerUri, dialplanServerUri=$dialplanServerUri, hideInboundCallerId=$hideInboundCallerId, messageServerUri=$messageServerUri, myIdentifiers=$myIdentifiers, notificationServerUri=$notificationServerUri, notificationSocketUri=$notificationSocketUri, receptionServerUri=$receptionServerUri, systemLanguage=$systemLanguage, userServerUri=$userServerUri, ]';
  }

  Configuration.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    authServerUri = json['authServerUri'];
    calendarServerUri = json['calendarServerUri'];
    callFlowServerUri = json['callFlowServerUri'];
    cdrServerUri = json['cdrServerUri'];
    contactServerUri = json['contactServerUri'];
    dialplanServerUri = json['dialplanServerUri'];
    hideInboundCallerId = json['hideInboundCallerId'];
    messageServerUri = json['messageServerUri'];
    myIdentifiers = (json['myIdentifiers'] == null) ?
      null :
      (json['myIdentifiers'] as List).cast<String>();
    notificationServerUri = json['notificationServerUri'];
    notificationSocketUri = json['notificationSocketUri'];
    receptionServerUri = json['receptionServerUri'];
    systemLanguage = json['systemLanguage'];
    userServerUri = json['userServerUri'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (authServerUri != null)
      json['authServerUri'] = authServerUri;
    if (calendarServerUri != null)
      json['calendarServerUri'] = calendarServerUri;
    if (callFlowServerUri != null)
      json['callFlowServerUri'] = callFlowServerUri;
    if (cdrServerUri != null)
      json['cdrServerUri'] = cdrServerUri;
    if (contactServerUri != null)
      json['contactServerUri'] = contactServerUri;
    if (dialplanServerUri != null)
      json['dialplanServerUri'] = dialplanServerUri;
    if (hideInboundCallerId != null)
      json['hideInboundCallerId'] = hideInboundCallerId;
    if (messageServerUri != null)
      json['messageServerUri'] = messageServerUri;
    if (myIdentifiers != null)
      json['myIdentifiers'] = myIdentifiers;
    if (notificationServerUri != null)
      json['notificationServerUri'] = notificationServerUri;
    if (notificationSocketUri != null)
      json['notificationSocketUri'] = notificationSocketUri;
    if (receptionServerUri != null)
      json['receptionServerUri'] = receptionServerUri;
    if (systemLanguage != null)
      json['systemLanguage'] = systemLanguage;
    if (userServerUri != null)
      json['userServerUri'] = userServerUri;
    return json;
  }

  static List<Configuration> listFromJson(List<dynamic> json) {
    return json == null ? List<Configuration>() : json.map((value) => Configuration.fromJson(value)).toList();
  }

  static Map<String, Configuration> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, Configuration>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = Configuration.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of Configuration-objects as value to a dart map
  static Map<String, List<Configuration>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<Configuration>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = Configuration.listFromJson(value);
       });
     }
     return map;
  }
}

