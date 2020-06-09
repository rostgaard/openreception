part of orf.api;

class ReceptionAttributes {
  
  int cid = 0;
  
  int receptionId = 0;
  
  List<PhoneNumber> phoneNumbers = [];
  
  List<MessageEndpoint> endpoints = [];
  
  List<String> backupContacts = [];
  
  List<String> messagePrerequisites = [];
  
  List<String> tags = [];
  
  List<String> emailaddresses = [];
  
  List<String> handling = [];
  
  List<String> workhours = [];
  
  List<String> titles = [];
  
  List<String> responsibilities = [];
  
  List<String> relations = [];
  
  List<String> departments = [];
  
  List<String> infos = [];
  
  List<String> whenWhats = [];
  ReceptionAttributes();

  @override
  String toString() {
    return 'ReceptionAttributes[cid=$cid, receptionId=$receptionId, phoneNumbers=$phoneNumbers, endpoints=$endpoints, backupContacts=$backupContacts, messagePrerequisites=$messagePrerequisites, tags=$tags, emailaddresses=$emailaddresses, handling=$handling, workhours=$workhours, titles=$titles, responsibilities=$responsibilities, relations=$relations, departments=$departments, infos=$infos, whenWhats=$whenWhats, ]';
  }

  ReceptionAttributes.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    cid = json['cid'];
    receptionId = json['receptionId'];
    phoneNumbers = (json['phoneNumbers'] == null) ?
      null :
      PhoneNumber.listFromJson(json['phoneNumbers']);
    endpoints = (json['endpoints'] == null) ?
      null :
      MessageEndpoint.listFromJson(json['endpoints']);
    backupContacts = (json['backupContacts'] == null) ?
      null :
      (json['backupContacts'] as List).cast<String>();
    messagePrerequisites = (json['messagePrerequisites'] == null) ?
      null :
      (json['messagePrerequisites'] as List).cast<String>();
    tags = (json['tags'] == null) ?
      null :
      (json['tags'] as List).cast<String>();
    emailaddresses = (json['emailaddresses'] == null) ?
      null :
      (json['emailaddresses'] as List).cast<String>();
    handling = (json['handling'] == null) ?
      null :
      (json['handling'] as List).cast<String>();
    workhours = (json['workhours'] == null) ?
      null :
      (json['workhours'] as List).cast<String>();
    titles = (json['titles'] == null) ?
      null :
      (json['titles'] as List).cast<String>();
    responsibilities = (json['responsibilities'] == null) ?
      null :
      (json['responsibilities'] as List).cast<String>();
    relations = (json['relations'] == null) ?
      null :
      (json['relations'] as List).cast<String>();
    departments = (json['departments'] == null) ?
      null :
      (json['departments'] as List).cast<String>();
    infos = (json['infos'] == null) ?
      null :
      (json['infos'] as List).cast<String>();
    whenWhats = (json['whenWhats'] == null) ?
      null :
      (json['whenWhats'] as List).cast<String>();
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (cid != null)
      json['cid'] = cid;
    if (receptionId != null)
      json['receptionId'] = receptionId;
    if (phoneNumbers != null)
      json['phoneNumbers'] = phoneNumbers;
    if (endpoints != null)
      json['endpoints'] = endpoints.map((e) => e.toJson()).toList(growable: false);
    if (backupContacts != null)
      json['backupContacts'] = backupContacts;
    if (messagePrerequisites != null)
      json['messagePrerequisites'] = messagePrerequisites;
    if (tags != null)
      json['tags'] = tags;
    if (emailaddresses != null)
      json['emailaddresses'] = emailaddresses;
    if (handling != null)
      json['handling'] = handling;
    if (workhours != null)
      json['workhours'] = workhours;
    if (titles != null)
      json['titles'] = titles;
    if (responsibilities != null)
      json['responsibilities'] = responsibilities;
    if (relations != null)
      json['relations'] = relations;
    if (departments != null)
      json['departments'] = departments;
    if (infos != null)
      json['infos'] = infos;
    if (whenWhats != null)
      json['whenWhats'] = whenWhats;
    return json;
  }

  static List<ReceptionAttributes> listFromJson(List<dynamic> json) {
    return json == null ? List<ReceptionAttributes>() : json.map((value) => ReceptionAttributes.fromJson(value)).toList();
  }

  static Map<String, ReceptionAttributes> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, ReceptionAttributes>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = ReceptionAttributes.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of ReceptionAttributes-objects as value to a dart map
  static Map<String, List<ReceptionAttributes>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<ReceptionAttributes>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = ReceptionAttributes.listFromJson(value);
       });
     }
     return map;
  }
}

