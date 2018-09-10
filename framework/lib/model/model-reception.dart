/*                  This file is part of OpenReception
                   Copyright (C) 2014-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orf.model;

class Reception {
  static const int noId = 0;

  int id = Reception.noId;
  String name = '';

  int oid = Organization.noId;

  List<String> addresses = <String>[];
  List<String> alternateNames = <String>[];
  List<String> bankingInformation = <String>[];
  List<String> salesMarketingHandling = <String>[];
  List<String> emailAddresses = <String>[];
  List<String> handlingInstructions = <String>[];
  List<String> openingHours = <String>[];
  List<String> vatNumbers = <String>[];
  List<String> websites = <String>[];
  List<String> customerTypes = <String>[];
  List<PhoneNumber> phoneNumbers = <PhoneNumber>[];
  String miniWiki = '';
  List<WhenWhat> whenWhats = <WhenWhat>[];

  String dialplan;
  String greeting;
  String otherData;
  String _shortGreeting = '';
  String product;
  bool enabled = false;

  static final Reception noReception = new Reception.empty();

  static Reception _selectedReception = noReception;

  static Bus<Reception> _receptionChange = new Bus<Reception>();

  /// Default initializing contructor
  Reception.empty();

  Reception.fromJson(Map<String, dynamic> receptionMap) {
    try {
      this
        ..id = receptionMap[key.id]
        ..oid = receptionMap[key.oid]
        ..name = receptionMap[key.name]
        ..enabled = receptionMap[key.enabled]
        ..dialplan = receptionMap[key.dialplan];

      if (receptionMap[key.attributes] != null) {
        attributes = receptionMap[key.attributes];
      }
    } catch (error,s) {
      print("$error  $s");
      throw new ArgumentError('Invalid data in map' + receptionMap.toString());
    }
  }

  String get shortGreeting =>
      this._shortGreeting.isNotEmpty ? this._shortGreeting : this.greeting;
  set shortGreeting(String newGreeting) {
    this._shortGreeting = newGreeting;
  }

  @deprecated
  static Reception decode(Map<String, dynamic> map) =>
      new Reception.fromJson(map);

  static Stream<Reception> get onReceptionChange => _receptionChange.stream;

  static Reception get selectedReception => _selectedReception;
  static set selectedReception(Reception reception) {
    _selectedReception = reception;
    _receptionChange.fire(_selectedReception);
  }

  Map<String, dynamic> get attributes => <String, dynamic>{
        key.addresses: addresses,
        key.alternateNames: alternateNames,
        key.bankingInfo: bankingInformation,
        key.customerTypes: customerTypes,
        key.emailAdresses: emailAddresses,
        key.greeting: greeting,
        key.handlingInstructions: handlingInstructions,
        key.miniWiki: miniWiki,
        key.openingHours: openingHours,
        key.other: otherData,
        key.product: product,
        key.salesMarketingHandling: salesMarketingHandling,
        key.shortGreeting: _shortGreeting,
        key.vatNumbers: vatNumbers,
        key.phoneNumbers: new List<Map<String, dynamic>>.from(
            phoneNumbers.map((PhoneNumber number) => number.toJson())),
        key.websites: websites,
        key.whenWhat: whenWhats.map((WhenWhat ww) => ww.toJson()).toList()
      };

  set attributes(Map<String, Object> attributes) {
    if (attributes.containsKey(key.whenWhat)) {
      List<Map<String, Object>> values = List.from(attributes[key.whenWhat]);
      whenWhats = values
          .map((Map<String, Object> map) => new WhenWhat.fromJson(map))
          .toList();
    }

    this
      ..addresses = List<String>.from(attributes[key.addresses])
      ..alternateNames = List<String>.from(attributes[key.alternateNames])
      ..bankingInformation = List<String>.from(attributes[key.bankingInfo])
      ..customerTypes = List<String>.from(attributes[key.customerTypes])
      ..emailAddresses = List<String>.from(attributes[key.emailAdresses])
      ..greeting = attributes[key.greeting] as String
      ..handlingInstructions = List<String>.from(attributes[key.handlingInstructions])
      ..miniWiki = attributes[key.miniWiki]
      ..phoneNumbers =
          (attributes[key.phoneNumbers] as Iterable<Map<String, dynamic>>)
              .map((Map<String, dynamic> map) => new PhoneNumber.fromJson(map))
              .toList()
      ..product = attributes[key.product] as String
      ..openingHours = attributes[key.openingHours] as List<String>
      ..otherData = attributes[key.other] as String
      ..salesMarketingHandling =
          attributes[key.salesMarketingHandling] as List<String>
      .._shortGreeting = attributes[key.shortGreeting] != null
          ? attributes[key.shortGreeting]
          : ''
      ..vatNumbers = attributes[key.vatNumbers] as List<String>
      ..websites = attributes[key.websites] as List<String>;
  }

  /// Returns a Map representation of the Reception.
  Map<String, dynamic> toJson() => <String, dynamic>{
        key.id: id,
        key.enabled: enabled,
        key.oid: oid,
        key.dialplan: dialplan,
        key.name: name,
        key.attributes: attributes
      };

  @override
  bool operator ==(Object other) => other is Reception && this.id == other.id;

  bool get isNotEmpty => this.id != noReception.id;
  bool get isEmpty => this.id == noReception.id;

  ReceptionReference get reference => new ReceptionReference(id, name);

  @override
  int get hashCode => toString().hashCode;
}
