part of orf.api;

class Reception {
  
  int id = 0;
  
  String name = "";
  
  int oid = 0;
  
  List<String> addresses = [];
  
  List<String> alternateNames = [];
  
  List<String> bankingInformation = [];
  
  List<String> salesMarketingHandling = [];
  
  List<String> emailAddresses = [];
  
  List<String> handlingInstructions = [];
  
  List<String> openingHours = [];
  
  List<String> vatNumbers = [];
  
  List<String> websites = [];
  
  List<String> customerTypes = [];
  
  String miniWiki = "";
  
  String dialplan = "";
  
  String greeting = "";
  
  String otherData = "";
  
  String shortGreeting = "";
  
  String product = "";
  
  bool enabled = false;
  
  List<PhoneNumber> phoneNumbers = [];
  Reception();

  @override
  String toString() {
    return 'Reception[id=$id, name=$name, oid=$oid, addresses=$addresses, alternateNames=$alternateNames, bankingInformation=$bankingInformation, salesMarketingHandling=$salesMarketingHandling, emailAddresses=$emailAddresses, handlingInstructions=$handlingInstructions, openingHours=$openingHours, vatNumbers=$vatNumbers, websites=$websites, customerTypes=$customerTypes, miniWiki=$miniWiki, dialplan=$dialplan, greeting=$greeting, otherData=$otherData, shortGreeting=$shortGreeting, product=$product, enabled=$enabled, phoneNumbers=$phoneNumbers, ]';
  }

  Reception.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    id = json['id'];
    name = json['name'];
    oid = json['oid'];
    addresses = (json['addresses'] == null) ?
      null :
      (json['addresses'] as List).cast<String>();
    alternateNames = (json['alternateNames'] == null) ?
      null :
      (json['alternateNames'] as List).cast<String>();
    bankingInformation = (json['bankingInformation'] == null) ?
      null :
      (json['bankingInformation'] as List).cast<String>();
    salesMarketingHandling = (json['salesMarketingHandling'] == null) ?
      null :
      (json['salesMarketingHandling'] as List).cast<String>();
    emailAddresses = (json['emailAddresses'] == null) ?
      null :
      (json['emailAddresses'] as List).cast<String>();
    handlingInstructions = (json['handlingInstructions'] == null) ?
      null :
      (json['handlingInstructions'] as List).cast<String>();
    openingHours = (json['openingHours'] == null) ?
      null :
      (json['openingHours'] as List).cast<String>();
    vatNumbers = (json['vatNumbers'] == null) ?
      null :
      (json['vatNumbers'] as List).cast<String>();
    websites = (json['websites'] == null) ?
      null :
      (json['websites'] as List).cast<String>();
    customerTypes = (json['customerTypes'] == null) ?
      null :
      (json['customerTypes'] as List).cast<String>();
    miniWiki = json['miniWiki'];
    dialplan = json['dialplan'];
    greeting = json['greeting'];
    otherData = json['otherData'];
    shortGreeting = json['shortGreeting'];
    product = json['product'];
    enabled = json['enabled'];
    phoneNumbers = (json['phoneNumbers'] == null) ?
      null :
      PhoneNumber.listFromJson(json['phoneNumbers']);
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (id != null)
      json['id'] = id;
    if (name != null)
      json['name'] = name;
    if (oid != null)
      json['oid'] = oid;
    if (addresses != null)
      json['addresses'] = addresses;
    if (alternateNames != null)
      json['alternateNames'] = alternateNames;
    if (bankingInformation != null)
      json['bankingInformation'] = bankingInformation;
    if (salesMarketingHandling != null)
      json['salesMarketingHandling'] = salesMarketingHandling;
    if (emailAddresses != null)
      json['emailAddresses'] = emailAddresses;
    if (handlingInstructions != null)
      json['handlingInstructions'] = handlingInstructions;
    if (openingHours != null)
      json['openingHours'] = openingHours;
    if (vatNumbers != null)
      json['vatNumbers'] = vatNumbers;
    if (websites != null)
      json['websites'] = websites;
    if (customerTypes != null)
      json['customerTypes'] = customerTypes;
    if (miniWiki != null)
      json['miniWiki'] = miniWiki;
    if (dialplan != null)
      json['dialplan'] = dialplan;
    if (greeting != null)
      json['greeting'] = greeting;
    if (otherData != null)
      json['otherData'] = otherData;
    if (shortGreeting != null)
      json['shortGreeting'] = shortGreeting;
    if (product != null)
      json['product'] = product;
    if (enabled != null)
      json['enabled'] = enabled;
    if (phoneNumbers != null)
      json['phoneNumbers'] = phoneNumbers;
    return json;
  }

  static List<Reception> listFromJson(List<dynamic> json) {
    return json == null ? List<Reception>() : json.map((value) => Reception.fromJson(value)).toList();
  }

  static Map<String, Reception> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, Reception>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = Reception.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of Reception-objects as value to a dart map
  static Map<String, List<Reception>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<Reception>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = Reception.listFromJson(value);
       });
     }
     return map;
  }
}

