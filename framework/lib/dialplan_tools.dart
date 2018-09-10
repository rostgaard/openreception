/*                  This file is part of OpenReception
                   Copyright (C) 2015-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

/// Dialplan compilation tools.
///
/// Provides [DialplanCompiler] and utility functions for generating
/// dialplans from model classes, such as [model.ReceptionDialplan].
library orf.dialplan_tools;

import 'dart:convert';

import 'model.dart' as model;
import 'pbx-keys.dart';

/// String constant that is appended to extensions that are used as
/// fallback dialplan actions. Exposed so that users of the dialplan tools
/// library may access it in order to avoid usage in applications.
const String closedSuffix = 'closed';

/// String constant that is appended to extensions are reserved for
/// outbound calling. Exposed so that users of the dialplan tools library
/// may access it in order to avoid usage in applications.
const String outboundSuffix = 'outbound';

/// Dialplan compiler configuration options.
///
/// The dialplan options may be configured to *not* [goLive], which means
/// that every extension coming from a dialplan model (for example
/// a [model.Transfer]), will instead be replaced by [testNumber]. The same
/// goes for [testEmail], which replaces occurences of emails
/// from [model.Voicemail] objects.
class DialplanCompilerOpts {
  /// Default constructor that enables setting of dialplan cnfiguration
  /// parameters, that otherwise will be set to default values - which are
  /// not sane.
  DialplanCompilerOpts(
      {this.goLive: false,
      this.greetingDir: '\${SOUNDS_DIR}',
      this.testNumber: 'xxxxxxxx',
      this.testEmail: 'some-guy@somewhere',
      this.callerIdName: 'Undefined',
      this.callerIdNumber: '00000000'});

  /// Determines if the dialplan should replace external extensions with
  /// [testNumber] and emails with [testEmail], if set to false (false is
  /// the default value).
  final bool goLive;

  /// Directory path that contains sound files used for playing back
  /// greetings and other information to callers. Defaults to FreeSWITCH
  /// variable ${SOUNDS_DIR} (notice this is *not* a Dart string
  /// interpolation), if omitted in the constructor.
  final String greetingDir;

  /// Phone extension that is to replace external extension in dialplan
  /// generation if [goLive] is false.
  final String testNumber;

  /// Email address that is to replace email adresses in dialplan
  /// generation if [goLive] is false.
  final String testEmail;

  /// Caller ID name to send upon outbound calls. Used when generating
  /// extensions for external transfers.
  final String callerIdName;

  /// Caller ID number to send upon outbound calls. Used when generating
  /// extensions for external transfers.
  final String callerIdNumber;
}

/// Environment that enables state to be passed along to the next function
/// in the chain as well as starting a scope.
class Environment {
  /// Determines if the channel has been previously answered. Used for
  /// inserting explicit `answer` actions into the generated dialplan.
  bool channelAnswered = false;

  /// Determines if the call has been previously announced from a
  /// [model.Notify]. Used for inserting locks around the call playback
  /// actions in the generated dialplan.
  bool callAnnounced = false;
}

/// Dialplan compiler. Builds xml dialplans, xml ivr menus and xml user
/// accounts for FreeSWITCH.
class DialplanCompiler {
  /// Creates a dialplan compiler with configuration from [option]s.
  DialplanCompiler(this.option);

  /// Compiler configuration options.
  DialplanCompilerOpts option;

  /// Convert a [model.ReceptionDialplan] using [model.Reception]
  /// information to an XML string.
  String dialplanToXml(
          model.ReceptionDialplan dialplan, model.Reception reception) =>
      _dialplanToXml(dialplan, option, reception);

  /// Convert a [model.IvrMenu] into an XML string.
  String ivrToXml(model.IvrMenu menu) => _ivrToXml(menu, option);

  /// Convert a [model.Voicemail] object into an XML string.
  String voicemailToXml(model.Voicemail voicemail) =>
      _voicemailToXml(voicemail, option);

  /// Convert a [model.User] to an XML string using information
  /// from [model.PeerAccount].
  String userToXml(model.User user, model.PeerAccount account) => '''<include>
  <user id="${account.username}">
    <params>
      <param name="password" value="${account.password}"/>
    </params>
    <variables>
      <variable name="toll_allow" value="domestic,international,local"/>
      <variable name="accountcode" value="${account.username}"/>
      <variable name="user_context" value="${account.context}"/>
      <variable name="effective_caller_id_name" value="${user.name}"/>
      <variable name="effective_caller_id_number" value="${account.username}"/>
      <variable name="outbound_caller_id_name" value="\$\${outbound_caller_name}"/>
      <variable name="outbound_caller_id_number" value="\$\${outbound_caller_id}"/>
      <variable name="callgroup" value="${account.context}"/>
    </variables>
  </user>
</include>''';
}

/// Extracts a list of names of IVR menus contained in [rdp].
@deprecated
Future<Iterable<String>> ivrOf(model.ReceptionDialplan rdp) async =>
    rdp.allActions.whereType<model.Ivr>().map((model.Ivr ivr) => ivr.menuName);

/// Sanitizes [string] for use in dialplans by HTML escaping it.
String _sanify(String string) =>
    HtmlEscape(HtmlEscapeMode.attribute).convert(string);

/// Converts a [Map] of variables into a FreeSWITCH variable String.
String _variablesToString(Map<String, dynamic> vars) {
  final Iterable<String> kvStrings =
      vars.keys.map((String key) => '$key=${_sanify(vars[key].toString())}');

  return kvStrings.join(',');
}

/// Creates an extension that transfers to an external trunk.
///
/// The trunk is the one specified in the FreeSWITCH `default_trunk`
/// dialplan variable.
List<String> _externalTrunkTransfer(
    String extension, int rid, DialplanCompilerOpts opts) {
  final Map<String, dynamic> vars = <String, dynamic>{
    ORPbxKey.receptionId: rid,
    'originate_timeout': '120',
    'origination_caller_id_name': opts.callerIdName,
    'origination_caller_id_number': opts.callerIdNumber,
  };

  final Map<String, dynamic> bLegVars = <String, dynamic>{
    'leg_timeout': 50,
    ORPbxKey.receptionId: rid,
    'fifo_music': 'default'
  };

  final String varString =
      '{${_variablesToString(vars)}}' + '[${_variablesToString(bLegVars)}]';

  return <String>[
    '<extension name="$extension-$outboundSuffix-trunk" continue="true">',
    '  <condition field="destination_number" expression="^${PbxKey.externalTransfer}_(\\d+)\$">',
    '    <action application="set" data="ringback=\${dk-ring}"/>',
    '    <action application="ring_ready" />',
    '    <action application="bridge" data="${varString}sofia/gateway/\${default_trunk}/\$1"/>',
    '    <action application="hangup"/>',
    '  </condition>',
    '</extension>'
  ];
}

List<String> _externalSipTransfer(
    String extension, int rid, DialplanCompilerOpts opts) {
  final String callerIdName = _sanify(opts.callerIdName);
  final String callerIdNumber = _sanify(opts.callerIdNumber);
  return <String>[
    '<extension name="$extension-$outboundSuffix-sip" continue="true">',
    '  <condition field="destination_number" expression="^${PbxKey.externalTransfer}_(.*)">',
    '    <action application="set" data="ringback=\${dk-ring}"/>',
    '    <action application="ring_ready" />',
    '    <action application="bridge" data="{${ORPbxKey.receptionId}=$rid,originate_timeout=120,origination_caller_id_name=$callerIdName,origination_caller_id_number=$callerIdNumber}[leg_timeout=50,${ORPbxKey.receptionId}=$rid,fifo_music=default]sofia/external/\$1"/>',
    '    <action application="hangup"/>',
    '  </condition>',
    '</extension>'
  ];
}

/// Normalizes an opening hour string for use in extension name by removing
/// the spaces and removing other odd characters.
String _normalizeOpeningHour(String string) =>
    string.replaceAll(' ', '_').replaceAll(':', '');

/// Indent a string by [count] spaces.
String _indent(String item, {int count: 2}) =>
    '${List<String>.filled(count, ' ').join('')}$item';

/// Turn an [model.OpeningHour] into a list of dialplan actions.
List<String> _openingHourToXmlDialplan(
    String extension,
    model.OpeningHour oh,
    Iterable<model.Action> actions,
    DialplanCompilerOpts option,
    Environment env) {
  List<String> lines = List<String>();
  final List<String> actionLines = actions
      .map((model.Action action) => _actionToXmlDialplan(action, option, env))
      .fold(
          List<String>(),
          (List<String> combined, List<String> current) => combined
            ..addAll(current.map((String e) => _indent(e, count: 4))));

  lines.addAll(<String>[
    '',
    _comment('Actions for opening hour $oh'),
    '<extension name="$extension-${_normalizeOpeningHour(oh.toString())}" continue="true">'
  ]);

  if (env.callAnnounced) {
    lines.add(
        '  <condition field="\${${ORPbxKey.receptionOpen}}" expression="^true\$"/>');
  }
  lines
    ..add(
        '  <condition ${_openingHourToFreeSwitch(oh)} break="${PbxKey.onTrue}">')
    ..addAll(actionLines)
    ..add('    <action application="hangup"/>')
    ..add('  </condition>')
    ..add('</extension>');
  return lines;
}

/// Generate a fallback extension.
List<String> _fallbackToDialplan(
    String extension,
    Iterable<model.Action> actions,
    DialplanCompilerOpts option,
    Environment env,
    model.Reception reception) {
  return List<String>.from(<String>[
    '',
    _comment('Default fallback actions for $extension'),
    '<extension name="$extension-$closedSuffix">',
    '  <condition>',
  ])
    ..addAll(actions
        .map((model.Action action) => _actionToXmlDialplan(action, option, env))
        .fold(
            List<String>(),
            (List<String> combined, List<String> current) =>
                combined..addAll(current.map((String item) => _indent(item))))
        .toList())
    ..add('    <action application="hangup"/>')
    ..add('  </condition>')
    ..add('</extension>');
}

/// Turn a [model.HourAction] into a list of dialplan actions.
Iterable<String> _hourActionToXmlDialplan(String extension,
    model.HourAction hourAction, DialplanCompilerOpts option) {
  final Iterable<Iterable<String>> has = hourAction.hours.map(
      (model.OpeningHour oh) => _openingHourToXmlDialplan(
          extension, oh, hourAction.actions, option, Environment()));

  final List<String> strings = has.fold(
      <String>[],
      (List<String> combined, Iterable<String> current) =>
          combined..addAll(current));

  return strings;
}

/// Converts an [Iterable] of [model.HourAction] objects into a
/// single [Iterable] of [String]s.
///
/// Takes in the [extension] that is currently being generated an the
/// [hourActions] to generate. The [option]s are required, because it will
/// be forwarded to the next functions in the dialplan generation chain.
Iterable<String> _hourActionsToXmlDialplan(String extension,
    Iterable<model.HourAction> hourActions, DialplanCompilerOpts option) {
  // Convert every houraction found into an iterable of strings.
  final Iterable<Iterable<String>> haStrings = hourActions.map(
      (model.HourAction ha) => _hourActionToXmlDialplan(extension, ha, option));

  // Reduce the all the iterables found into a single iterable of strings.
  final List<String> folded = haStrings.fold(
      <String>[],
      (List<String> combined, Iterable<String> current) =>
          combined..addAll(current));

  return folded;
}

/// Turns a [model.NamedExtension] into a dialplan document fragment.
Iterable<String> _namedExtensionToDialPlan(model.NamedExtension extension,
        DialplanCompilerOpts option, Environment env) =>
    <String>[
      '',
      _noteTemplate('Extra-extension ${extension.name}'),
      '<extension name="${extension.name}" continue="true">',
      '  <condition field="destination_number" '
          'expression="^${extension.name}\$" '
          'break="${PbxKey.onFalse}">',
    ]
      ..addAll(extension.actions
          .map((model.Action action) =>
              _actionToXmlDialplan(action, option, env))
          .fold(
              <String>[],
              (List<String> combined, Iterable<String> current) =>
                  combined..addAll(current.map(_indent).map(_indent))).toList())
      ..add('    <action application="hangup"/>')
      ..add('  </condition>')
      ..add('</extension>');

Iterable<String> _extraExtensionsToDialplan(
        Iterable<model.NamedExtension> extensions,
        DialplanCompilerOpts option) =>
    extensions
        .map((model.NamedExtension ne) =>
            _namedExtensionToDialPlan(ne, option, Environment()))
        .fold(
            List<String>(),
            (List<String> combined, Iterable<String> current) =>
                combined..addAll(current))
        .toList();

/// Turn a [model.ReceptionDialplan] into an xml-dialplan as string.
String _dialplanToXml(model.ReceptionDialplan dialplan,
    DialplanCompilerOpts option, model.Reception reception) {
  final String htmlEncodedReceptionName = _sanify(reception.name);

  final Iterable<String> hourActions =
      _hourActionsToXmlDialplan(dialplan.extension, dialplan.open, option);

  return '''<!-- Dialplan for extension ${dialplan.extension}. Generated ${DateTime.now()} -->
<include>
  <context name="reception-${dialplan.extension}">

    <!-- Initialize channel variables -->
    <extension name="${dialplan.extension}" continue="true">
      <condition field="destination_number" expression="^${dialplan.extension}\$" break="${PbxKey.onFalse}">
        <action application="log" data="INFO Setting variables of call to ${dialplan.extension}, currently allocated to rid ${reception.id}."/>
        ${_setVar(ORPbxKey.receptionId, reception.id)}
        ${_setVar(ORPbxKey.greetingPlayed, false)}
        ${_setVar(ORPbxKey.locked, false)}
        ${_setVar(ORPbxKey.receptionName, htmlEncodedReceptionName)}
      </condition>
    </extension>

    ${_extraExtensionsToDialplan(dialplan.extraExtensions, option).join('\n    ')}
    <!-- Perform outbound PSTN calls -->
    ${_externalTrunkTransfer(dialplan.extension, reception.id, option).join('\n    ')}

    <!-- Perform outbound SIP calls -->
    ${_externalSipTransfer(dialplan.extension, reception.id, option).join('\n    ')}

    ${hourActions.join('\n    ')}
    ${_fallbackToDialplan(dialplan.extension, dialplan.defaultActions, option, Environment(), reception).join('\n    ')}

  </context>
</include>''';
}

/// Detemine whether or not an extension is local or not.
bool _isInternalExtension(String extension) => extension.contains('-');

/// Template for dialout action.
String _dialoutTemplate(String extension, DialplanCompilerOpts option) =>
    _isInternalExtension(extension)
        ? extension
        : option.goLive
            ? '${PbxKey.externalTransfer}_$extension'
            : '${PbxKey.externalTransfer}_${option.testNumber}';

/// Returns the [email] if the [option] specify that the dialplan is live,
/// otherwise return whatever is specified in [option].
String _liveCheckEmail(String email, DialplanCompilerOpts option) =>
    option.goLive ? email : option.testEmail;

/// Template for dialplan note.
String _noteTemplate(String note) => _comment('Note: $note');

/// Template for a comment.
String _comment(String text) => '<!-- $text -->';

/// Template transfer action.
String _transferTemplate(String extension, DialplanCompilerOpts option) =>
    '<action application="transfer" data="${_dialoutTemplate(extension, option)}"/>';

/// Template fo [model.ReceptionTransfer] action.
String _receptionTransferTemplate(
        String extension, DialplanCompilerOpts option) =>
    '<action application="transfer" data="$extension XML reception-$extension"/>';

/// Template for a sleep action.
String _sleep(int msec) => '<action application="sleep" data="$msec"/>';

/// Template for a call lock event.
String get _lock => '<action application="${PbxKey.event}" '
    'data="${PbxKey.eventSubclass}=${ORPbxKey.callLock},${PbxKey.eventName}=${PbxKey.custom}"/>';

/// Template for a call unlock event.
String get _unlock => '<action application="${PbxKey.event}" '
    'data="${PbxKey.eventSubclass}=${ORPbxKey.callUnlock},${PbxKey.eventName}=${PbxKey.custom}"/>';

/// Template for a set variable action.
String _setVar(String key, dynamic value) =>
    '<action application="set" data="$key=$value"/>';

/// Template for a ring tone event.
String get _ringTone => '<action application="${PbxKey.event}" '
    'data="${PbxKey.eventSubclass}=${ORPbxKey.ringingStart},${PbxKey.eventName}=${PbxKey.custom}" />';

/// Template for a ring stop event.
String get _ringToneStop => '<action application="${PbxKey.event}" '
    'data="${PbxKey.eventSubclass}=${ORPbxKey.ringingStop},${PbxKey.eventName}=${PbxKey.custom}"/>';

/// Template for a notify event.
String get _callNotify => '<action application="${PbxKey.event}" '
    'data="${PbxKey.eventSubclass}=${ORPbxKey.callNotify},${PbxKey.eventName}=${PbxKey.custom}" />';

/// Convert an action a xml dialplan entry.
List<String> _actionToXmlDialplan(
    model.Action action, DialplanCompilerOpts option, Environment env) {
  List<String> returnValue = <String>[];

  // Transfer action.
  if (action is model.Transfer) {
    if (action.note.isNotEmpty) returnValue.add(_noteTemplate(action.note));
    if (!env.channelAnswered) {
      returnValue.add('<action application="answer"/>');
      env.channelAnswered = true;
    }
    returnValue.add('<action application="playback" '
        'data="{loops=1}${option.greetingDir}/A-no-sound-message.wav"/>');

    returnValue.add(_transferTemplate(action.extension, option));
  }

  // Notify action.
  else if (action is model.Notify) {
    returnValue.addAll(<String>[
      _comment('Announce the call to the receptionists'),
      _setVar(ORPbxKey.state, 'new'),
      _callNotify
    ]);
    env.callAnnounced = true;
  }

  // ReceptionTransfer action.
  else if (action is model.ReceptionTransfer) {
    returnValue.addAll(<String>[
      _comment('Transfer call to other reception'),
      _receptionTransferTemplate(action.extension, option)
    ]);
  }

  // Ringtone action.
  else if (action is model.Ringtone) {
    returnValue.addAll(<String>[
      _comment('Sending ringtones'),
      _setVar(ORPbxKey.state, PbxKey.ringing),
      _ringTone,
      '<action application="ring_ready"/>',
      _sleep(5000 * action.count),
      _ringToneStop,
    ]);
  }

  // Playback action.
  else if (action is model.Playback) {
    if (action.note.isNotEmpty) returnValue.add(_noteTemplate(action.note));
    returnValue.addAll(<String>[_comment('Playback file ${action.filename}')]);

    returnValue..add(_setVar(ORPbxKey.state, PbxKey.playback));

    if (!env.channelAnswered) {
      returnValue.add('<action application="answer"/>');
      env.channelAnswered = true;
    }

    if (env.callAnnounced) {
      returnValue.addAll(<String>[_setVar(ORPbxKey.locked, true), _lock]);
    }

    String greetingPath;

    if (option.greetingDir.isEmpty) {
      greetingPath = action.filename;
    } else if (!option.greetingDir.endsWith('/')) {
      greetingPath = option.greetingDir + '/' + action.filename;
    } else {
      greetingPath = option.greetingDir + action.filename;
    }

    returnValue.addAll(<String>[
      '<action application="playback" '
          'data="{loops=${action.repeat}}$greetingPath"/>',
      _setVar(ORPbxKey.greetingPlayed, true),
    ]);

    if (env.callAnnounced) {
      returnValue.addAll(<String>[_setVar(ORPbxKey.locked, false), _unlock]);
    }
  }

  // Enqueue action.
  else if (action is model.Enqueue) {
    if (!env.channelAnswered) {
      returnValue.add('<action application="answer"/>');
      env.channelAnswered = true;
    }

    returnValue.addAll(<String>[
      _comment('Enqueue call'),
      _setVar(ORPbxKey.state, PbxKey.queued),
      '<action application="${PbxKey.event}" data="${PbxKey.eventSubclass}=${ORPbxKey.waitQueueEnter},${PbxKey.eventName}=${PbxKey.custom}" />',
      _setVar('fifo_music', 'local_stream://${action.holdMusic}'),
      '<action application="fifo" data="${action.queueName}@\${domain_name} in"/>'
    ]);
  }

  // Voicemail  action.
  else if (action is model.Voicemail) {
    if (!env.channelAnswered) {
      returnValue.add('<action application="answer"/>');
      env.channelAnswered = true;
    }
    if (action.note.isNotEmpty) returnValue.add(_noteTemplate(action.note));
    returnValue.addAll(<String>[
      _setVar(
          ORPbxKey.emailDateHeader, '\${strftime(%a, %d %b %Y %H:%M:%S %z)}'),
      _setVar('record_waste_resources', 'true'),
      '<action application="voicemail" data="default \$\${domain} ${action.vmBox}"/>'
    ]);
  }

  // Ivr action.
  else if (action is model.Ivr) {
    if (!env.channelAnswered) {
      returnValue.add('<action application="answer"/>');
      env.channelAnswered = true;
    }

    returnValue.addAll(<String>[
      _setVar('record_waste_resources', 'true'),
      _setVar(
          ORPbxKey.emailDateHeader, '\${strftime(%a, %d %b %Y %H:%M:%S %z)}'),
      '<action application="ivr" data="${action.menuName}"/>'
    ]);
  } else {
    throw StateError('Unsupported action type: ${action.runtimeType}');
  }

  return returnValue;
}

/// Turns a [model.WeekDay] into a FreeSWITCH weekday index.
int _weekDayToFreeSwitch(model.WeekDay wday) => (wday.index) + 1;

/// Formats an [model.OpeningHour] into a format that FreeSWITCH
/// understands.
String _openingHourToFreeSwitch(model.OpeningHour oh) {
  String wDayString = '';

  // Prefixes string of integer with a '0' if the integer value is below 10.
  String _twoDigitInt(int i) => i < 10 ? '0$i' : '$i';

  if (<model.WeekDay>[oh.fromDay, oh.toDay].contains(model.WeekDay.all)) {
    wDayString = '';
  } else if (oh.fromDay == oh.toDay) {
    wDayString = 'wday="${_weekDayToFreeSwitch(oh.fromDay)}"';
  } else {
    wDayString =
        'wday="${_weekDayToFreeSwitch(oh.fromDay)}-${_weekDayToFreeSwitch(oh.toDay)}"';
  }

  String ohString =
      '${_twoDigitInt(oh.fromHour)}:${_twoDigitInt(oh.fromMinute)}:00-'
      '${_twoDigitInt(oh.toHour)}:${_twoDigitInt(oh.toMinute)}:00';

  return '$wDayString time-of-day="$ohString"';
}

/// Turn an [model.IvrMenu] into a list of ivr menu actions.
List<String> _ivrMenuToXml(model.IvrMenu menu, DialplanCompilerOpts option) =>
    menu.entries
        .map((model.IvrEntry entry) => _ivrEntryToXml(entry, option))
        .fold(
            <String>[],
            (List<String> combined, Iterable<String> current) =>
                combined..addAll(current));

/// Generate an xml formatted ivr menu string from a [model.IvrMenu].
String _generateXmlFromIvrMenu(
        model.IvrMenu menu, DialplanCompilerOpts option) =>
    '''<menu name="${menu.name}"
      ${PbxKey.greetLong}="\$\${sounds_dir}/${option.greetingDir}/${menu.greetingLong.filename}"
      ${PbxKey.greetShort}="\$\${sounds_dir}/${option.greetingDir}/${menu.greetingShort.filename}"
      ${PbxKey.timeout}="\$\${IVR_timeout}"
      ${PbxKey.maxFailures}="\$\${IVR_max-failures}"
      ${PbxKey.maxTimeouts}="\$\${IVR_max-timeout}">

    ${(_ivrMenuToXml(menu, option)).join('\n    ')}
  </menu>

  ${menu.submenus.map((model.IvrMenu menu) => _generateXmlFromIvrMenu(menu, option)).join('\n  ')}
''';

/// Wrap a [model.IvrMenu] in an include directive.
///
/// This is needed for stand-alone menus.
String _ivrToXml(model.IvrMenu menu, DialplanCompilerOpts option) => '''
<include>
  ${_generateXmlFromIvrMenu(menu, option)}
</include>''';

/// Turn a single [model.IvrMenu] entry int a list of xml actions.
List<String> _ivrEntryToXml(model.IvrEntry entry, DialplanCompilerOpts option) {
  List<String> returnValue = <String>[];

  // IvrTransfer action
  if (entry is model.IvrTransfer) {
    if (entry.transfer.note.isNotEmpty)
      returnValue.add(_noteTemplate(entry.transfer.note));
    returnValue.add(
        '<entry action="${PbxKey.menuExecApp}" digits="${entry.digits}" '
        'param="transfer ${_dialoutTemplate(entry.transfer.extension, option)}"/>');

    // IvrReceptionTransfer action
  } else if (entry is model.IvrReceptionTransfer) {
    if (entry.transfer.note.isNotEmpty)
      returnValue.add(_noteTemplate(entry.transfer.note));
    returnValue.add(
        '<entry action="${PbxKey.menuExecApp}" digits="${entry.digits}" '
        'param="transfer ${entry.transfer.extension} XML reception-${entry.transfer.extension}"/>');
  } else if (entry is model.IvrVoicemail) {
    returnValue.add(
        '<entry action="${PbxKey.menuExecApp}" digits="${entry.digits}" param="voicemail default \$\${domain} ${entry.voicemail.vmBox}"/>');
  } else if (entry is model.IvrSubmenu) {
    returnValue.add(
        '<entry action="${PbxKey.menuSub}" digits="${entry.digits}" param="${entry.name}"/>');
  } else if (entry is model.IvrTopmenu) {
    returnValue
        .add('<entry action="${PbxKey.menuTop}" digits="${entry.digits}"/>');
  } else
    throw ArgumentError.value(
        entry.runtimeType,
        'entry'
        'type ${entry.runtimeType} is not supported by translation tool');

  return returnValue;
}

/// Turn a [model.Voicemail] object into an xml voicemail account.
String _voicemailToXml(model.Voicemail vm, DialplanCompilerOpts option) =>
    '''<include>
  <user id="${vm.vmBox}">
    <params>
      <param name="password" value=""/>
      <param name="vm-password" value=""/>
      <param name="http-allowed-api" value="voicemail"/>
      <param name="vm-mailto" value="${_liveCheckEmail(vm.recipient, option)}"/>
      <param name="vm-email-all-messages" value="true"/>
      <param name="vm-notify-mailto" value="${_liveCheckEmail(vm.recipient, option)}"/>
      <param name="vm-attach-file" value="true" />
      <param name="vm-skip-instructions" value="true"/>
      <param name="vm-skip-greeting" value="true"/>
    </params>
    <variables>
      <variable name="toll_allow" value=""/>
      <variable name="user_context" value="voicemail"/>
    </variables>
  </user>
</include>''';
