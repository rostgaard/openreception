library ort.mock_data;

import 'dart:math' show Random;

import 'package:orf/model.dart' as model;

abstract class Randomizer {
  static int seed = new DateTime.now().millisecondsSinceEpoch;
  static Random rand = new Random(seed);

  static final List<String> events = [
    'Milk purchase',
    'Meeting with ${randomChoice(contacts)}',
    'All work and no play',
    'Roller coaster inspection',
    'Prepare world domination',
    'PTA meeting',
    'Out to "lunch" with ${randomChoice(contacts)}',
    '${randomChoice(contacts)} is quite angry with us'
  ];

  static final List<String> dialplanNote = [
    '',
    'Vacation dialplan',
    'Reserved for hang-overs',
    'Not longer needed',
    'Should really just be removed'
  ];

  static final List<String> handlings = [
    'Ask them to butt out',
    'No calls. Not ever',
    'Put them through',
    'Not longer needed',
    'Should really just be removed'
  ];

  static final List<String> contacts = [
    'Alexandra Kongstad Pedersen',
    'Anne And',
    'Gardenia Hø',
    'Hans Hansen',
    'Peter Petersen',
    'Tom Thomsen',
    'Petra Petrea',
    'Gunner Gunnersen',
    'Ole Olesen',
    'Helga Helgason',
    'Martinus Martinussen',
    'Bob Børgesen',
    'Charlie Carstensen',
    'Alice Arnesen',
    'Charlie Carstensen',
    'Bob Børgesen',
    'Bente Bogfinke',
    'Carla Cikade',
    'Dorthe Dådyr',
    'Eva Egern',
    'Frode Flyvemyre',
    'Gerda Ged',
    'Hans Havodder',
    'Ida Isfugl',
    'Jan Jordbi',
    'Karsten Klokkefrø',
    'Lars Latterfrø',
    'Maren Muldvarp',
    'Nille Natugle',
    'Ole Odder',
    'Petra Pindsvin',
    'Ronald Rødspætte',
    'Sune Syvsover',
    'Tulla Trane',
    'Ulla Undulat',
    'Verner Vaskebjørn',
    'Allan Abe',
    'Børge Bæver',
    'Carlo Connemara',
    'Dorian Dompap',
    'Eskild Edderfugl',
    'Frank Fritte',
    'Gunner Grævling',
    'Heidi Husmus',
    'Lars Latterfrø',
    'Frank Fritte',
    'Eskild Edderfugl',
    'Helga Helgason',
    'Martinus Martinussen',
    'Anja Hansen',
    'Astrid Bang',
    'Birgit Blomquist',
    'Janne Winther Andreasen',
    'Knud Jønsson',
    'Morten Smidt-Holm',
    'Naja Duelund',
    'Oda Olsen',
    'Gert Keld',
    'Perry Næbdyr',
    'Palle Letkniv',
    'Anders Sand',
    'Rie Gid S.Todder',
    'Kvak S. Alver',
    'Sigmund Sivsko'
  ];

  static final List<String> titles = [
    'Forskningsleder/seniorforsker',
    'Forsker',
    'Administrationschef',
    'Kreditorbogholder',
    'Forskningsleder/seniorforsker',
    'Direktør',
    'Seniorforsker',
    'Sekretær/debitorbogholder',
    'Senior Superman',
    'Nattevagt',
    'Overlæge',
    'Underlæge',
    'Bussemandsskræmmer',
    'Spøgelsesjæger',
    'Grønthøster',
    'Blåhvalsjæger',
    'Myresluger',
    'Underdirektør',
    'Potteskjuler',
    'Hegnbestiger',
    'Glaspuster',
    'Næsepudser',
    'Kummebejser',
    'Skærmtrold',
    'Møntvender',
    'Bagvender',
    'Sivskofletter',
    'Ordkløver',
    'Tingfinder',
    'Sodavandsbæller',
    'Dynevender',
    'Endevender',
    'Vendekåbe',
    'Stoledanser',
    'Frisbeehenter',
    'IKEA-skab-samler',
    'Ringbind',
    'Stalker',
    'Blotter',
    'F5-Trykker',
    'Lusepuster',
    'Lyseslukker',
    'Sneglekoger',
    'Frølårsklipper',
    'Dåseåbner',
    'Hvidløgspresser',
    'Pruttens ejermand'
  ];

  static final List<String> companyNames = [
    'Acme inc',
    'Wayne Enterprise',
    'Ghostbusters A/S',
    'Slamtroldmanden',
    'Kødbollen A/S',
    'Blomme\'s Gartneri',
    'Hummerspecialisten ApS',
    'Gnaske-Grønt ApS',
    'Firmanavn_der_fortæller_om_samtlige_produkter_hos_os A/S',
    'BulgurKompaniget A/S',
    'Andefødder Aps',
    'Spirevippen I/S',
    'Petersen\'s Globale Kobberudvinding',
    'PingPong ApS',
    'Kasper\'s Køkken A/S',
    'Den Varme Radiator ApS',
    'KludeCentralen ApS',
    'MobileAdvolaterne A/S',
    'Bogforlaget A/S',
    'Revisor Søren ApS',
    'Den Varme Radiator ApS',
    'KludeCentralen ApS',
    'MobileAdvolaterne A/S',
    'Bogforlaget A/S',
    'Revisor Søren ApS',
    'Kalle\'s Dyrefoder ApS',
    'Fantasibureauet A/S',
    'Fem Flade fisk I/S',
    'Advokatkontoret',
    'Gave-Ideer ApS',
    'Det Tredie Firmanavn I/S',
    'Kraniosakralklinikken ApS',
    'Hvalbøffer A/S',
    'De gode ideer ApS',
    'Super-supporten A/S',
    'Doozerne A/S',
    'Sublim Forskning A/S',
    'Hårtotten ApS',
    'Alt til katten A/S',
    'Sjov og Spas',
    'Humørbomben K/S',
    'Kurts kartoffelskrællerservice',
    'Det absolutte nulpunkt',
    'Den hellige ko-kebab',
    'Peters pottemageri',
    'Reklamegas Aps',
    'Lenes lækre lune lagner I/S',
    'Grine-Gerts anti-depressiver',
    'Kasse-kompaniet',
    'Hårstiverne'
  ];

  static final List<String> messageBodies = [
    'I\'m selling these fine leather jackets',
    'Please call me back regarding stuff',
    'I love the smell of pastry',
    'Regarding your enlargement',
    'Nigerian royalties wish to send you money',
    'Call back soon',
    'The cheese has started to smell',
    'Are you paying for that?',
    'Imagination land called',
    'Roller coasters purchase',
    'These are not the droids you are looking for. Come to me for new ones!',
    'All your base are belong',
    'I would love to change the world, but they won\'t give me the source code'
  ];

  static final List<String> callerNames = [
    'Bob Barker',
    'Mister Green',
    'Walter White',
    'Boy Wonder',
    'Batman',
    'Perry the Platypus',
    'Ferb Fletcher',
    'Phineas Flynn',
    'Candace Flynn',
    'Dr. Heinz Doofenshmirtz',
    'Reed Richards (Mr. Fantastic)',
    'Peter Parker (Spiderman)',
    'Bruce Banner (the Hulk)',
    'Matt Murdock (Daredevil)',
    'Susan Storm (Invisible Girl)',
    'Scott Summers (Cyclops)',
    'Stephen Strange (Dr. Strange)',
    'Darkwing Duck'
  ];

  //TODO: Check that these match the flags in the framework.
  static final List<List<String>> flagsLists = [
    [],
    ["pleaseCall"],
    ['urgent.', 'pleaseCall'],
    ['hasCalled', 'pleaseCall'],
    ["willCallBack"],
    ["urgent"],
    ["urgent", "willCallBack"]
  ];

  static final userNames = [
    'Bob Børgesen',
    'Alice Arnesen',
    'Charlie Carstensen',
    'Dorthe Didriksen',
    'Erik Einersen',
    'Frede Frandsen',
    'Gurli Gunnersen',
    'Heidi Hermansen',
    'Ida Iversen',
    'Julius Jensen',
    'Rasmine Rapmund',
    'Signe Snaksom',
    'Sanne Sludrechartol',
    'Miranda Migrene',
    'Tage Fortalsom',
    'Mogens Morgenånde',
    'Bengt Blidrøst',
    'Svend Skrap',
    'Børge Bralder',
    'Buller Bredmund',
    'Ove Overlæbe',
    'Misse Mundvand'
  ];

  static List<String> organizationFlags = [
    'VIP',
    'Charity',
    'Pro bono',
    'Bad credit',
    'Cash',
    'Invoice',
    'Account',
    'Labor',
    'Up front'
  ];

  static List<String> departments = [
    'Sales',
    'Support',
    'Marketing',
    'Plundering',
    'Stealing',
    'Prison'
  ];

  static String randomDepartment() => randomChoice(departments);
  static String randomEvent() => randomChoice(events);
  static String randomHandling() => randomChoice(handlings);
  static String randomCompany() => randomChoice(companyNames);
  static String randomUsername() => randomChoice(userNames);
  static String randomTitle() => randomChoice(titles);
  static String randomCallerName() => randomChoice(callerNames);
  static String randomContactName() => randomChoice(contacts);
  static String randomMessageBody() => randomChoice(messageBodies);
  static List<String> randomMessageFlags() => randomChoice(flagsLists);
  static String randomEndpointType() =>
      randomChoice(model.MessageEndpointType.types);
  static String randomRecipientType() =>
      randomChoice(model.MessageEndpointType.types);
  static String randomContactType() => randomChoice(model.ContactType.types);
  static String randomDialplanNote() => randomChoice(dialplanNote);

  /**
   * returns a model.CalendarEntry with no owner.
   */
  static model.CalendarEntry randomCalendarEntry() =>
      new model.CalendarEntry.empty()
        ..content = randomChoice(events)
        ..start = new DateTime.now()
        ..stop = (new DateTime.now()..add(new Duration(hours: 1)));

  /**
   * Generates a random [model.IvrMenu].
   */
  static model.IvrMenu randomIvrMenu() =>
      new model.IvrMenu('menu-${randomPhoneNumber()}', randomPlayback())
        ..entries = randomIvrEntries();

  /**
   *
   */
  static List<model.IvrEntry> randomIvrEntries() => [
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '*',
        '#'
      ].take(rand.nextInt(4) + 1).map(randomIvrEntry).toList();

  /**
    * Generates a random [model.IvrEntry] action.
    */
  static model.IvrEntry randomIvrEntry(String digit) => randomChoice([
        randomIvrTopmenu,
        randomIvrSubmenu,
        randomIvrTransfer,
        randomIvrVoicemail,
      ])(digit);

  /**
   *
   */
  static model.IvrTopmenu randomIvrTopmenu(String digit) =>
      new model.IvrTopmenu(digit);

  /**
   *
   */
  static model.IvrSubmenu randomIvrSubmenu(String digit) =>
      new model.IvrSubmenu(digit, 'submenu_${rand.nextInt(100)}');

  /**
   *
   */
  static model.IvrTransfer randomIvrTransfer(String digit) =>
      new model.IvrTransfer(digit, randomTransfer());

  /**
   *
   */
  static model.IvrVoicemail randomIvrVoicemail(String digit) =>
      new model.IvrVoicemail(digit, randomVoicemail());

  /**
   * Generates a random [model.ReceptionDialplan].
   */
  static model.ReceptionDialplan randomDialplan({bool excludeMenus: false}) =>
      new model.ReceptionDialplan()
        ..open = randomDialplanHourActions(excludeMenus: excludeMenus)
        ..extension =
            '${randomPhoneNumber()}-${new DateTime.now().millisecondsSinceEpoch}'
        ..defaultActions = randomDialplanActions(excludeMenus: excludeMenus)
        ..note = randomDialplanNote();

  /**
   *
   */
  static List<model.HourAction> randomDialplanHourActions(
          {bool excludeMenus: false}) =>
      new List.generate(rand.nextInt(4) + 1,
          (_) => randomHourAction(excludeMenus: excludeMenus));

  /**
   *
   */
  static model.HourAction randomHourAction({bool excludeMenus: false}) =>
      new model.HourAction()
        ..actions = randomDialplanActions(excludeMenus: excludeMenus)
        ..hours = randomOpeningHours();

  /**
   *
   */
  static List<model.OpeningHour> randomOpeningHours() =>
      new List.generate(rand.nextInt(4) + 1, (_) => randomOpeningHour());

  /**
   *
   */
  static model.OpeningHour randomOpeningHour() => new model.OpeningHour.empty()
    ..fromDay = randomWeekDay()
    ..toDay = randomWeekDay()
    ..fromHour = rand.nextInt(24)
    ..toHour = rand.nextInt(24)
    ..fromMinute = rand.nextInt(60)
    ..toMinute = rand.nextInt(60);

  /**
   *
   */
  static randomWeekDay() => randomChoice(model.WeekDay.values);

  /**
   * Generates a random-sized list of random [model.Action] objects.
   */
  static List<model.Action> randomDialplanActions({bool excludeMenus: false}) {
    //Number of actions to generate.
    final int numActions = rand.nextInt(5) + 2;

    return new List.generate(
        numActions, (_) => randomAction(excludeMenus: excludeMenus));
  }

  /**
   * Generates a random [model.Playback] action.
   */
  static model.Playback randomPlayback() =>
      new model.Playback('somefile', note: randomDialplanNote());

  /**
   * Generates a random [model.Transfer] action.
   */
  static model.Transfer randomTransfer() =>
      new model.Transfer(randomPhoneNumber(), note: randomCallerName());

  /**
   * Generates a random [model.Voicemail] action.
   */
  static model.Voicemail randomVoicemail() =>
      new model.Voicemail('vm-${randomPhoneNumber()}',
          recipient: randomGmail(), note: randomDialplanNote());

  /**
   * Generates a random [model.Enqueue] action.
   */
  static model.Enqueue randomEnqueue() =>
      new model.Enqueue('queue-${rand.nextInt(100)}',
          holdMusic: 'playlist-${rand.nextInt(100)}',
          note: randomDialplanNote());

  /**
   * Generates a random [model.Notify] action.
   */
  static model.Notify randomNotify() =>
      new model.Notify('event-${rand.nextInt(100)}');

  /**
   * Generates a random [model.Ringtone] action.
   */
  static model.Ringtone randomRingtone() =>
      new model.Ringtone(rand.nextInt(4) + 1);

  /**
   * Generates a random [model.Ivr] action.
   */
  static model.Ivr randomIvr() =>
      new model.Ivr('menu-${rand.nextInt(100)}', note: randomDialplanNote());
  /**
   * Generates a random [model.Action] action.
   */
  static model.Action randomAction({bool excludeMenus: false}) => randomChoice([
        randomVoicemail,
        randomEnqueue,
        randomNotify,
        randomRingtone,
        randomTransfer,
        randomPlayback
      ]..addAll(excludeMenus ? [] : [randomIvr]))();

  /**
   * Generates a random 8-digit phone number.
   */
  static String randomPhoneNumber() {
    int firstDigit = rand.nextInt(8) + 2;
    List<int> lastDigits = new List<int>.generate(8, (_) => rand.nextInt(10));
    List<int> digits = [firstDigit]..addAll(lastDigits);

    return digits.join('');
  }

  /**
   *
   */
  static String randomUserEmail() => 'employee${rand.nextInt(100)}@us.com';

  /**
   *
   */
  static String randomEmail() =>
      '${rand.nextInt(100)}@us${rand.nextInt(100)}.com';

  /**
   *
   */
  static String randomPeer() => '11${rand.nextInt(10)}${rand.nextInt(10)}';

  /**
   *
   */
  static String randomString(int length) => new String.fromCharCodes(
      new List.generate(length, (index) => rand.nextInt(33) + 89));

  /**
   *
   */
  static String randomGmail() =>
      'employee${rand.nextInt(10)}${rand.nextInt(10)}@gmail.com';

  /**
   *
   */
  static String randomPortait() =>
      'employee${rand.nextInt(10)}${rand.nextInt(10)}.png';

  static model.PhoneNumber randomPhone() => new model.PhoneNumber.empty()
    ..confidential = rand.nextBool()
    ..note = randomDialplanNote()
    ..destination = randomPhoneNumber();

  /**
   *
   */
  static model.User randomUser() => new model.User.empty()
    ..address = randomUserEmail()
    ..name = randomUsername()
    ..extension = randomPeer();

  static String randomLocalExtension() => rand.nextInt(501).toString();

  /**
   *
   */
  static String randomOrganizationFlag() => randomChoice(organizationFlags);

  /**
   * Constructs and returns a [Organization] object with random content.
   *
   * The returned object is does not have a valid ID.
   */
  static model.Organization randomOrganization() =>
      new model.Organization.empty()
        ..notes =
            new List.generate(rand.nextInt(3), (_) => randomOrganizationFlag())
        ..name = randomCompany();

  static model.BaseContact randomBaseContact() => new model.BaseContact.empty()
    ..type = randomContactType()
    ..name = randomContactName()
    ..enabled = rand.nextBool();

  static model.ReceptionAttributes randomAttributes() =>
      new model.ReceptionAttributes.empty()
        ..backupContacts =
            new List.generate(rand.nextInt(3) + 1, (_) => randomContactName())
        ..departments =
            new List.generate(rand.nextInt(3) + 1, (_) => randomDepartment())
        ..emailaddresses =
            new List.generate(rand.nextInt(3) + 1, (_) => randomEmail())
        ..endpoints = new List.generate(
            rand.nextInt(3) + 1, (_) => randomMessageEndpoint())
        ..handling =
            new List.generate(rand.nextInt(3) + 1, (_) => randomHandling())
        ..infos =
            new List.generate(rand.nextInt(3) + 1, (_) => randomDialplanNote())
        ..messagePrerequisites =
            new List.generate(rand.nextInt(3) + 1, (_) => randomHandling())
        ..phoneNumbers =
            new List.generate(rand.nextInt(3) + 1, (_) => randomPhone())
        ..relations =
            new List.generate(rand.nextInt(3) + 1, (_) => randomCallerName())
        ..responsibilities =
            new List.generate(rand.nextInt(3) + 1, (_) => randomDepartment())
        ..tags = new List.generate(rand.nextInt(3), (_) => randomDepartment())
        ..titles = new List.generate(rand.nextInt(3), (_) => randomDepartment())
        ..workhours = new List.generate(
            rand.nextInt(3), (_) => randomOpeningHour().toString());

  /**
   * Constructs and returns a [Reception] object with random content.
   *
   * The returned object is does not have a valid ID, nor organizationID.
   */
  static model.Reception randomReception() {
    final String name = randomCompany();
    final String greeting = 'Welcome to $name, how may I help you?';

    return new model.Reception.empty()
      ..dialplan = randomPhoneNumber()
      ..addresses =
          new List.generate(rand.nextInt(3) + 1, (_) => randomDepartment())
      ..alternateNames =
          new List.generate(rand.nextInt(3) + 1, (_) => randomCompany())
      ..bankingInformation =
          new List.generate(rand.nextInt(3) + 1, (_) => randomDepartment())
      ..customerTypes =
          new List.generate(rand.nextInt(3) + 1, (_) => randomDepartment())
      ..emailAddresses =
          new List.generate(rand.nextInt(3) + 1, (_) => randomEmail())
      ..enabled = rand.nextBool()
      ..name = name
      ..greeting = greeting
      ..handlingInstructions =
          new List.generate(rand.nextInt(3) + 1, (_) => randomHandling())
              .toSet()
              .toList()
      ..openingHours = new List.generate(
          rand.nextInt(3), (_) => randomOpeningHour().toString())
      ..otherData = randomString(10)
      ..product = randomString(10)
      ..salesMarketingHandling =
          new List.generate(rand.nextInt(3) + 1, (_) => randomHandling())
              .toSet()
              .toList()
      ..shortGreeting = greeting
      ..phoneNumbers =
          new List.generate(rand.nextInt(3) + 1, (_) => randomPhone())
      ..vatNumbers =
          new List.generate(rand.nextInt(3) + 1, (_) => randomHandling())
      ..websites =
          new List.generate(rand.nextInt(3) + 1, (_) => randomHandling())
      ..oid = model.Organization.noId;
  }

  /**
   * Constructs and returns a [Message] object with random content.
   *
   * The returned object still needs to have its context, user and
   * recipients set before it is a valid parameter to a messageStore.
   */
  static model.Message randomMessage() {
    model.Message message = new model.Message.empty();
    message
      ..body = randomMessageBody()
      ..callId = 'call-id-${new DateTime.now().millisecondsSinceEpoch}'
      ..callerInfo = randomCaller()
      ..createdAt = new DateTime.now()
      ..flag = new model.MessageFlag(randomMessageFlags());

    return message;
  }

  /**
   * Creates a random MessageEndpoint.
   */
  static model.MessageEndpoint randomMessageEndpoint() =>
      new model.MessageEndpoint.empty()
        ..address = randomGmail()
        ..name = randomContactName()
        ..note = randomDialplanNote()
        ..type = randomEndpointType();

  /**
   * Construct a random MessageCaller object.
   */
  static model.CallerInfo randomCaller() => new model.CallerInfo.empty()
    ..cellPhone = randomPhoneNumber()
    ..company = randomCompany()
    ..localExtension = randomLocalExtension()
    ..name = '${randomTitle()} ${randomCallerName()}'
    ..phone = randomPhoneNumber();

  /**
   *
   */
  static String randomReceptionistNumber() =>
      '11${new List<int>.generate(2, (_) => rand.nextInt(5)+5).join('')}';
  /**
   *
   */
  static model.PeerAccount randomPeerAccount() => new model.PeerAccount(
      randomReceptionistNumber(), randomString(16), 'receptions');

  /**
   * Returns a random element from [pool].
   */
  static dynamic randomChoice(List pool) {
    if (pool.isEmpty) {
      throw new ArgumentError('Cannot find a random value in an empty list');
    }

    int index = rand.nextInt(pool.length);

    return pool[index];
  }
}
