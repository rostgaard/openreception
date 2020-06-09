part of orf.api;

class MessageFilter {
  
  int userId = 0;
  
  int receptionId = 0;
  
  int contactId = 0;
  
  int limitCount = 100;
  MessageFilter();

  @override
  String toString() {
    return 'MessageFilter[userId=$userId, receptionId=$receptionId, contactId=$contactId, limitCount=$limitCount, ]';
  }

  MessageFilter.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    userId = json['userId'];
    receptionId = json['receptionId'];
    contactId = json['contactId'];
    limitCount = json['limitCount'];
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (userId != null)
      json['userId'] = userId;
    if (receptionId != null)
      json['receptionId'] = receptionId;
    if (contactId != null)
      json['contactId'] = contactId;
    if (limitCount != null)
      json['limitCount'] = limitCount;
    return json;
  }

  static List<MessageFilter> listFromJson(List<dynamic> json) {
    return json == null ? List<MessageFilter>() : json.map((value) => MessageFilter.fromJson(value)).toList();
  }

  static Map<String, MessageFilter> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, MessageFilter>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = MessageFilter.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of MessageFilter-objects as value to a dart map
  static Map<String, List<MessageFilter>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<MessageFilter>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = MessageFilter.listFromJson(value);
       });
     }
     return map;
  }
}

