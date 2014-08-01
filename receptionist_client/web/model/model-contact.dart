/*                     This file is part of Bob
                   Copyright (C) 2012-, AdaHeads K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of model;

final Contact nullContact = new Contact._null();

/**
 * A [Contact] object. Sorting contacts is done based on [name].
 */
class Contact implements Comparable {

  static const String className = '${libraryName}.Contact';

  int _receptionID = nullReception.ID;
  MiniboxList _backupList = new MiniboxList();
  CalendarEventList _calendarEventList = new CalendarEventList();
  String department = '';
  MiniboxList _emailAddressList = new MiniboxList();
  MiniboxList _handlingList = new MiniboxList();
  int id;
  String info = '';
  bool isHuman;
  String name = '';
  List<Map> phones;
  String position = '';
  String relations = '';
  String responsibility = '';
  List<Recipient> _distributionList = new List<Recipient>();
  List<String> _tags = new List<String>();
  List<PhoneNumber> _phoneNumberList = new List<PhoneNumber>();
  MiniboxList _telephoneNumberList = new MiniboxList();
  MiniboxList _workHoursList = new MiniboxList();

  int get receptionID => _receptionID;
  MiniboxList get backupList => _backupList;
  Future<CalendarEventList> get calendarEventList => calendar(this.id, this.receptionID);
  MiniboxList get emailAddressList => _emailAddressList;
  MiniboxList get handlingList => _handlingList;
  List<String> get tags => _tags;
  MiniboxList get telephoneNumberList => _telephoneNumberList; // <- TODO: cleanup this
  List<PhoneNumber> get phoneNumberList => _phoneNumberList;
  MiniboxList get workHoursList => _workHoursList;
  List<Recipient> get distributionList => _distributionList;

  static final Contact noContact = nullContact;

  static Contact _selectedContact = nullContact;

  static final EventType<Contact> activeContactChanged = new EventType<Contact>();

  static Contact get selectedContact => _selectedContact;
  static set selectedContact(Contact contact) {
    _selectedContact = contact;
    event.bus.fire(event.contactChanged, _selectedContact);
    event.bus.fire(activeContactChanged, _selectedContact);
  }

  /**
   * 
   */
  Future<List<Recipient>> dereferenceDistributionList() {

    Completer<List<Recipient>> completer = new Completer<List<Recipient>>();

    Future.forEach(this.distributionList, (Recipient recipient) {
      return Contact.get(recipient.contactID, recipient.receptionID).then((Contact dereferencedContact) {
        recipient.contactName = dereferencedContact.name;

        return storage.Reception.get(recipient.receptionID).then((Reception dereferencedReception) {
          recipient.receptionName = dereferencedReception.name;
        });

      });
    }).then((_) {
      completer.complete(this.distributionList);
    }).catchError((error) {
      completer.completeError(error);
    });

    return completer.future;
  }


  /**
   * [Contact] constructor. Expects a map in the following format:
   *
   * intString JSON object =
   *  {
   *    "priority": int,
   *    "value": String
   *  }
   *
   * Contact JSON object =
   *  {
   *    "full_name": String,
   *    "attributes": [
   *      {
   *        "relations": String,
   *        "workhours": [>= 0 intString objects],
   *        "department": String,
   *        "reception_id": int,
   *        "handling": [>= 0 intString objects],
   *        "telephonenumbers": [>= 0 intString objects],
   *        "responsibility": String,
   *        "emailaddresses": [>= 0 intString objects],
   *        "info": String,
   *        "position": String,
   *        "backup": [>= 0 intString objects],
   *        "tags": [>= 0 Strings],
   *        "contact_id": int
   *      }
   *    ],
   *    "is_human": bool,
   *    "contact_id": int
   *  }
   *
   * TODO Obviously the above map format should be in the docs/wiki, as it is
   * also highly relevant to Alice.
   */
  Contact.fromJson(Map json, int receptionID) {

    const String context = '${className}.fromJson';

    try {

      this.id = json['contact_id'];
      this._receptionID = receptionID;
      this.isHuman = json['is_human'];
      this.name = json['full_name'];

      this._backupList = new MiniboxList.fromJson(json, 'backup');
      this._emailAddressList = new MiniboxList.fromJson(json, 'emailaddresses');
      this._handlingList = new MiniboxList.fromJson(json, 'handling');
      this._telephoneNumberList = new MiniboxList.fromJson(json, 'phones');
      this._workHoursList = new MiniboxList.fromJson(json, 'workhours');

      department = json['department'];
      info = json['info'];
      position = json['position'];
      relations = json['relations'];
      responsibility = json['responsibility'];

      if (json.containsKey('tags')) {
        _tags = json['tags'];
      }

      if (json.containsKey('phones')) {
        (json['phones'] as List).forEach((item) {
          this._phoneNumberList.add(new PhoneNumber.fromMap(item));

          phones = json['phones'];
        });
      }

      try {
        if (json.containsKey('distribution_list')) {
          (json['distribution_list'] as Map).forEach((role, recipientList) {
            (recipientList as List).forEach((Map recipientMap) {
              Map map = {};
              try {
                
                log.debugContext('${map}', context);
                
                map['role'] = role;
                map['contact'] = {'id' : recipientMap['contact_id']};
                map['reception'] = {'id' : recipientMap['reception_id']};;
                
                this._distributionList.add(new Recipient.fromMap(map));
                

              } catch (error) {
                log.errorContext('Failed to parse recipient ${recipientMap}', context);
              }
              
            });
          });
        }
      } catch (error, stackTrace) {
        log.errorContext('Failed to parse distribution list. $error : $stackTrace', context);
      }
    } catch (error, stackTrace) {
      log.errorContext('Failed to parse contact map. $error : $stackTrace', context);
    }
  }

  static Future<Contact> get(int contactID, int receptionID) {
    return storage.Contact.get(contactID, receptionID);
  }

  static Future<ContactList> list(int receptionID) {
    return storage.Contact.list(receptionID);
  }

  static Future<CalendarEventList> calendar(int contactID, int receptionID) {
    return storage.Contact.calendar(contactID, receptionID);
  }


  /**
   * [Contact] null constructor.
   */
  Contact._null() {
    id = null;
    isHuman = null;
  }

  /**
   * Enables a [Contact] to sort itself compared to other contacts.
   */
  int compareTo(Contact other) => name.compareTo(other.name);

  /**
   * [Contact] as String, for debug/log purposes.
   */
  String toString() => '${name}-${id}-${isHuman}';

  Future<Map> contextMap() {

    return storage.Reception.get(this.receptionID).then((Reception reception) {
      return {
        'contact': {
          'id': this.id,
          'name': this.name
        },
        'reception': {
          'id': this.receptionID,
          'name': reception.name
        }
      };
    });

  }
}
