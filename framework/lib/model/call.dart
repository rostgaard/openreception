part of orf.api;

class Call {
  /* The call id */
  String id = null;
  
  CallState state = null;
  //enum stateEnum {  unknown,  created,  ringing,  queued,  unparked,  hungup,  transferring,  transferred,  speaking,  parked,  };{
  /* The other channel/leg of the call */
  String bLeg = null;
  /* Indicates whether the call is locked */
  bool locked = null;
  
  bool inbound = null;
  
  String destination = null;
  
  String callerId = null;
  
  bool greetingPlayed = null;
  
  int orRid = null;
  
  int orCid = null;
  
  int assignedTo = null;
  
  String channel = null;
  
  DateTime arrivalTime = null;
  
  DateTime answeredAt = null;
  Call();

  @override
  String toString() {
    return 'Call[id=$id, state=$state, bLeg=$bLeg, locked=$locked, inbound=$inbound, destination=$destination, callerId=$callerId, greetingPlayed=$greetingPlayed, orRid=$orRid, orCid=$orCid, assignedTo=$assignedTo, channel=$channel, arrivalTime=$arrivalTime, answeredAt=$answeredAt, ]';
  }

  Call.fromJson(Map<String, dynamic> json) {
    if (json == null) return;
    id = json['id'];
    state = (json['state'] == null) ?
      null :
      CallState.fromJson(json['state']);
    bLeg = json['b_leg'];
    locked = json['locked'];
    inbound = json['inbound'];
    destination = json['destination'];
    callerId = json['caller_id'];
    greetingPlayed = json['greeting_played'];
    orRid = json['__or__rid'];
    orCid = json['__or__cid'];
    assignedTo = json['assigned_to'];
    channel = json['channel'];
    arrivalTime = (json['arrival_time'] == null) ?
      null :
      DateTime.parse(json['arrival_time']);
    answeredAt = (json['answered_at'] == null) ?
      null :
      DateTime.parse(json['answered_at']);
  }

  Map<String, dynamic> toJson() {
    Map <String, dynamic> json = {};
    if (id != null)
      json['id'] = id;
    if (state != null)
      json['state'] = state;
    if (bLeg != null)
      json['b_leg'] = bLeg;
    if (locked != null)
      json['locked'] = locked;
    if (inbound != null)
      json['inbound'] = inbound;
    if (destination != null)
      json['destination'] = destination;
    if (callerId != null)
      json['caller_id'] = callerId;
    if (greetingPlayed != null)
      json['greeting_played'] = greetingPlayed;
    if (orRid != null)
      json['__or__rid'] = orRid;
    if (orCid != null)
      json['__or__cid'] = orCid;
    if (assignedTo != null)
      json['assigned_to'] = assignedTo;
    if (channel != null)
      json['channel'] = channel;
    if (arrivalTime != null)
      json['arrival_time'] = arrivalTime == null ? null : arrivalTime.toUtc().toIso8601String();
    if (answeredAt != null)
      json['answered_at'] = answeredAt == null ? null : answeredAt.toUtc().toIso8601String();
    return json;
  }

  static List<Call> listFromJson(List<dynamic> json) {
    return json == null ? List<Call>() : json.map((value) => Call.fromJson(value)).toList();
  }

  static Map<String, Call> mapFromJson(Map<String, dynamic> json) {
    var map = Map<String, Call>();
    if (json != null && json.isNotEmpty) {
      json.forEach((String key, dynamic value) => map[key] = Call.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of Call-objects as value to a dart map
  static Map<String, List<Call>> mapListFromJson(Map<String, dynamic> json) {
    var map = Map<String, List<Call>>();
     if (json != null && json.isNotEmpty) {
       json.forEach((String key, dynamic value) {
         map[key] = Call.listFromJson(value);
       });
     }
     return map;
  }
}

