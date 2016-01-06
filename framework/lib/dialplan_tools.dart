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

library openreception.dialplan_tools;

import 'model.dart' as model;
import 'pbx-keys.dart';

///Config values.
@deprecated
bool goLive = false;
@deprecated
String greetingDir = 'converted-vox';
@deprecated
String testNumber = 'xxxxxxxx';
@deprecated
String testEmail = 'some-guy@somewhere';

const String closedSuffix = 'closed';
const String outboundSuffix = 'outbound';
const String reception = 'reception';
const String receptionOpen = 'reception-open';

class DialplanCompilerOpts {
  final bool goLive;
  final String greetingDir;
  final String testNumber;
  final String testEmail;

  DialplanCompilerOpts(
      {this.goLive: false,
      this.greetingDir: 'converted-vox',
      this.testNumber: 'xxxxxxxx',
      this.testEmail: 'some-guy@somewhere'});
}

class DialplanCompiler {
  DialplanCompilerOpts option;

  DialplanCompiler(this.option);

  String dialplanToXml(model.ReceptionDialplan dialplan, int rid) =>
      _dialplanToXml(dialplan, rid, option);

  String ivrToXml(model.IvrMenu menu) => _ivrToXml(menu, option);

  String voicemailToXml(model.Voicemail vm) => _voicemailToXml(vm, option);

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

List<String> _externalTrunkTransfer(String extension, int rid) => [
      '<extension name="${extension}-${outboundSuffix}-trunk" continue="true">',
      '  <condition field="destination_number" expression="^${PbxKey.externalTransfer}_(\d+)">',
      '    <action application="set" data="ringback=\${dk-ring}"/>',
      '    <action application="ring_ready" />',
      '    <action application="bridge" data="{${ORPbxKey.receptionId}=${rid},originate_timeout=120}[leg_timeout=50,${ORPbxKey.receptionId}=${rid}]sofia/gateway/\${default_trunk}/\$1"/>',
      '    <action application="hangup"/>',
      '  </condition>',
      '</extension>'
    ];

List<String> _externalSipTransfer(String extension, int rid) => [
      '<extension name="${extension}-${outboundSuffix}-sip" continue="true">',
      '  <condition field="destination_number" expression="^${PbxKey.externalTransfer}_(.*)">',
      '    <action application="set" data="ringback=\${dk-ring}"/>',
      '    <action application="ring_ready" />',
      '    <action application="bridge" data="sofia/external/\$1"/>',
      '    <action application="hangup"/>',
      '  </condition>',
      '</extension>'
    ];

/**
 * Normalizes an opening hour string for use in extension name by removing the
 * spaces and removing other odd characters.
 */
String _normalizeOpeningHour(String string) =>
    string.replaceAll(' ', '_').replaceAll(':', '');

/**
 * Indent a string by [count] spaces.
 */
String _indent(item, {int count: 2}) =>
    '${new List.filled(count, ' ').join('')}$item';

/**
 * Determine if an Iterable of actions involves receptions.
 */
bool _involvesReceptionists(Iterable<model.Action> actions) => actions
    .where((action) => action is model.Notify)
    .any((notify) => notify.eventName == ORPbxKey.callNotify);

/**
 *
 */
List<String> _openingHourToXmlDialplan(String extension, model.OpeningHour oh,
        Iterable<model.Action> actions, DialplanCompilerOpts option) =>
    [
      '',
      _comment('Actions for opening hour $oh'),
      '<extension name="${extension}-${_normalizeOpeningHour(oh.toString())}" continue="true">'
    ]
      ..addAll(_involvesReceptionists(actions)
          ? ['  <condition field="\${reception_open}" expression="^true\$"/>']
          : [])
      ..add(
          '  <condition ${_openingHourToFreeSwitch(oh)} break="${PbxKey.onTrue}">')
      ..addAll(actions
          .map((action) => _actionToXmlDialplan(action, option))
          .fold(
              [],
              (combined, current) =>
                  combined..addAll(current.map(_indent).map(_indent))))
      ..add('    <action application="hangup"/>')
      ..add('  </condition>')
      ..add('</extension>');

/**
 * Generate A fallback extension.
 */
List<String> _fallbackToDialplan(String extension,
    Iterable<model.Action> actions, DialplanCompilerOpts option) {
  if (actions.length == 1 && actions.last is model.Playback) {
    actions = new List.generate(10, (_) => actions.last);
  }
  return [
    '',
    _comment('Default fallback actions for $extension'),
    '<extension name="${extension}-$closedSuffix">',
    '  <condition>',
  ]
    ..add('    <action application="playback" '
        'data="tone_stream://L=1;%(100,0,425)"/>')
    ..add('    <action application="answer"/>')
    ..addAll(actions.map((action) => _actionToXmlDialplan(action, option)).fold(
        [], (combined, current) => combined..addAll(current.map(_indent))))
    ..add('    <action application="hangup"/>')
    ..add('  </condition>')
    ..add('</extension>');
}

/**
 *
 */
Iterable<String> _hourActionToXmlDialplan(String extension,
        model.HourAction hourAction, DialplanCompilerOpts option) =>
    hourAction.hours.map((oh) =>
        _openingHourToXmlDialplan(extension, oh, hourAction.actions, option));

/**
 *
 */
Iterable<String> _hourActionsToXmlDialplan(String extension,
        Iterable<model.HourAction> hourActions, DialplanCompilerOpts option) =>
    hourActions.map((ha) => _hourActionToXmlDialplan(extension, ha, option)
        .fold([], (combined, current) => combined..addAll(current)));

Iterable<String> _namedExtensionToDialPlan(
        model.NamedExtension extension, DialplanCompilerOpts option) =>
    [
      '',
      _noteTemplate('Extra-extension ${extension.name}'),
      '<extension name="${extension.name}" continue="true">',
      '  <condition field="destination_number" '
          'expression="^${extension.name}\$" '
          'break="${PbxKey.onFalse}">',
    ]
      ..add('    <action application="playback" '
          'data="tone_stream://L=1;%(100,0,425)"/>')
      ..add('    <action application="answer"/>')
      ..addAll(extension.actions
          .map((action) => _actionToXmlDialplan(action, option))
          .fold(
              [],
              (combined, current) =>
                  combined..addAll(current.map(_indent).map(_indent))))
      ..add('  </condition>')
      ..add('</extension>');

Iterable<String> _extraExtensionsToDialplan(
        Iterable<model.NamedExtension> extensions,
        DialplanCompilerOpts option) =>
    extensions
        .map((ne) => _namedExtensionToDialPlan(ne, option))
        .fold([], (combined, current) => combined..addAll(current));

@deprecated
String convertTextual(model.ReceptionDialplan dialplan, int rid) =>
    _dialplanToXml(
        dialplan,
        rid,
        new DialplanCompilerOpts(
            goLive: goLive,
            greetingDir: greetingDir,
            testEmail: testEmail,
            testNumber: testNumber));

/**
 *
 */
String _dialplanToXml(model.ReceptionDialplan dialplan, int rid,
        DialplanCompilerOpts option) =>
    '''<!-- Dialplan for extension ${dialplan.extension}. Generated ${new DateTime.now()} -->
<include>
  <context name="$reception-${dialplan.extension}">

    <!-- Initialize channel variables -->
    <extension name="${dialplan.extension}" continue="true">
      <condition field="destination_number" expression="^${dialplan.extension}\$" break="${PbxKey.onFalse}">
        <action application="log" data="INFO Setting variables of call to ${dialplan.extension}, currently allocated to rid ${rid}."/>
        ${_setVar(ORPbxKey.receptionId, rid)}
        ${_setVar(ORPbxKey.greetingPlayed, false)}
        ${_setVar(ORPbxKey.locked, false)}
        ${_setVar(ORPbxKey.receptionId, rid)}
        ${_setVar(ORPbxKey.greetingPlayed, false)}
        ${_setVar(ORPbxKey.locked, false)}
      </condition>
    </extension>

    ${_extraExtensionsToDialplan(dialplan.extraExtensions, option).join('\n    ')}
    <!-- Perform outbound PSTN calls -->
    ${_externalTrunkTransfer(dialplan.extension, rid).join('\n    ')}
    
    <!-- Perform outbound SIP calls -->
    ${_externalSipTransfer(dialplan.extension, rid).join('\n    ')}
    
    ${_hourActionsToXmlDialplan(dialplan.extension, dialplan.open, option).fold([], (combined, current) => combined..addAll(current)).join('\n    ')}
    ${_fallbackToDialplan(dialplan.extension, dialplan.defaultActions, option).join('\n    ')}

  </context>
</include>''';

/**
 * Detemine whether or not an extension is local or not.
 */
bool _isInternalExtension(String extension) => extension.contains('-');

/**
 * Template for dialout action.
 */
String _dialoutTemplate(String extension, DialplanCompilerOpts option) =>
    _isInternalExtension(extension)
        ? extension
        : option.goLive
            ? '${PbxKey.externalTransfer}_${extension} XML receptions'
            : '${PbxKey.externalTransfer}_${option.testNumber} XML receptions';

/**
 *
 */
String _liveCheckEmail(String email, DialplanCompilerOpts option) =>
    option.goLive ? email : option.testEmail;

/**
* Template for dialplan note.
*/
String _noteTemplate(String note) => _comment('Note: $note');

/**
 * Template for a comment.
 */
String _comment(String text) => '<!-- $text -->';

/**
 * Template transfer action.
 */
String _transferTemplate(String extension, DialplanCompilerOpts option) =>
    '<action application="transfer" data="${_dialoutTemplate(extension, option)}"/>';

/**
 * Template for a sleep action.
 */
String _sleep(int msec) => '<action application="sleep" data="$msec"/>';

/**
 * Template for a call lock event.
 */
String get _lock => '<action application="${PbxKey.event}" '
    'data="${PbxKey.eventSubclass}=${ORPbxKey.callLock},${PbxKey.eventName}=${PbxKey.custom}"/>';

/**
 * Template for a call unlock event.
 */
String get _unlock => '<action application="${PbxKey.event}" '
    'data="${PbxKey.eventSubclass}=${ORPbxKey.callUnlock},${PbxKey.eventName}=${PbxKey.custom}"/>';

/**
 * Template for a set variable action.
 */
String _setVar(String key, dynamic value) =>
    '<action application="set" data="$key=$value"/>';

/**
 * Template for a ring tone event.
 */
String get _ringTone => '<action application="${PbxKey.event}" '
    'data="${PbxKey.eventSubclass}=${ORPbxKey.ringingStart},${PbxKey.eventName}=${PbxKey.custom}" />';
/**
 * Template for a ring stop event.
 */
String get _ringToneStop => '<action application="${PbxKey.event}" '
    'data="${PbxKey.eventSubclass}=${ORPbxKey.ringingStop},${PbxKey.eventName}=${PbxKey.custom}"/>';

/**
 * Template for a notify event.
 */
String get _callNotify => '<action application="${PbxKey.event}" '
    'data="${PbxKey.eventSubclass}=${ORPbxKey.callNotify},${PbxKey.eventName}=${PbxKey.custom}" />';

/**
 * Convert an action a xml dialplan entry.
 */
List<String> _actionToXmlDialplan(
    model.Action action, DialplanCompilerOpts option) {
  List returnValue = [];
  if (action is model.Transfer) {
    if (action.note.isNotEmpty) returnValue.add(_noteTemplate(action.note));

    returnValue.add(_transferTemplate(action.extension, option));
  } else if (action is model.Notify) {
    returnValue.addAll([
      _comment('Announce the call to the receptionists'),
      _setVar(ORPbxKey.state, 'new'),
      _callNotify
    ]);
  } else if (action is model.Ringtone) {
    returnValue.addAll([
      _comment('Sending ringtones'),
      _setVar(ORPbxKey.state, PbxKey.ringing),
      _ringTone,
      '<action application="playback" data="tone_stream://L=${action.count};\${dk-ring}"/>',
      _ringToneStop,
    ]);
  } else if (action is model.Playback) {
    if (action.note.isNotEmpty) returnValue.add(_noteTemplate(action.note));
    returnValue.addAll([_comment('Playback file ${action.filename}')]);

    returnValue
      ..add(_setVar(ORPbxKey.state, PbxKey.playback))
      ..add('    <action application="playback" '
          'data="tone_stream://L=1;%(100,0,425)"/>')
      ..add('    <action application="answer"/>');

    if (action.wrapInLock) {
      returnValue.addAll([
        _setVar(ORPbxKey.locked, true),
        _setVar(ORPbxKey.locked, true),
        _lock
      ]);
    }

    returnValue.addAll([
      _sleep(500),
      '<action application="playback" data="${option.greetingDir}/${action.filename}"/>',
      _sleep(500),
      _setVar(ORPbxKey.greetingPlayed, true),
      _setVar(ORPbxKey.greetingPlayed, true),
    ]);

    if (action.wrapInLock) {
      returnValue.addAll([
        _setVar(ORPbxKey.locked, false),
        _setVar(ORPbxKey.locked, false),
        _unlock
      ]);
    }
  } else if (action is model.Enqueue) {
    returnValue.addAll([
      _comment('Enqueue call'),
      '<action application="set" data="${ORPbxKey.state}=${PbxKey.queued}"/>',
      '<action application="${PbxKey.event}" data="${PbxKey.eventSubclass}=${ORPbxKey.waitQueueEnter},${PbxKey.eventName}=${PbxKey.custom}" />',
      '<action application="set" data="fifo_music=local_stream://${action.holdMusic}"/>',
      '<action application="fifo" data="${action.queueName}@\${domain_name} in"/>'
    ]);
  } else if (action is model.Voicemail) {
    if (action.note.isNotEmpty) returnValue.add(_noteTemplate(action.note));
    returnValue.addAll([
      '  <action application="set" data="${ORPbxKey.emailDateHeader}=\${strftime(%a, %d %b %Y %H:%M:%S %z)}"/>',
      '  <action application="voicemail" data="default \$\${domain} ${action.vmBox}"/>'
    ]);
  } else if (action is model.Ivr) {
    returnValue.addAll([
      '  <action application="set" data="${ORPbxKey.emailDateHeader}=\${strftime(%a, %d %b %Y %H:%M:%S %z)}"/>',
      '  <action application="ivr" data="${action.menuName}"/>'
    ]);
  } else {
    throw new StateError('Unsupported action type: ${action.runtimeType}');
  }

  return returnValue;
}

/**
 * Replace dialplan that are statically known.
 */
String _unfoldVariables(String buffer, String extension) => buffer
    .replaceAll('\${destination_number}', extension)
    .replaceAll('\${reception-greeting}', '$extension-dag.wav')
    .replaceAll('\${reception-greeting-closed}', '$extension-nat.wav');

/**
 * Turns a [model.WeekDay] into a FreeSWITCH weekday index.
 */
int _weekDayToFreeSwitch(model.WeekDay wday) => (wday.index) + 1;

/**
 * Formats an [model.OpeningHour] into a format that FreeSWITCH understands.
 */
String _openingHourToFreeSwitch(model.OpeningHour oh) {
  String wDayString = '';

  /// Prefixes string of integer with a '0' if the integer value is below 10.
  String _twoDigitInt(int i) => i < 10 ? '0$i' : '$i';

  if ([oh.fromDay, oh.toDay].contains(model.WeekDay.all)) {
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

/**
 *
 */

List<String> _ivrMenuToXml(model.IvrMenu menu, DialplanCompilerOpts option) =>
    menu.entries
        .map((entry) => _ivrEntryToXml(entry, option))
        .fold([], (combined, current) => combined..addAll(current));

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

  ${menu.submenus.map((menu) => _generateXmlFromIvrMenu (menu, option)).join('\n  ')}
''';

@deprecated
String generateXmlFromIvr(model.IvrMenu menu) => _ivrToXml(
    menu,
    new DialplanCompilerOpts(
        goLive: goLive,
        greetingDir: greetingDir,
        testEmail: testEmail,
        testNumber: testNumber));

String _ivrToXml(model.IvrMenu menu, DialplanCompilerOpts option) => '''
<include>
  ${_generateXmlFromIvrMenu(menu, option)}
</include>''';

List<String> _ivrEntryToXml(model.IvrEntry entry, DialplanCompilerOpts option) {
  List returnValue = [];
  if (entry is model.IvrTransfer) {
    if (entry.transfer.note.isNotEmpty) returnValue
        .add(_noteTemplate(entry.transfer.note));
    returnValue.add(
        '<entry action="${PbxKey.menuExecApp}" digits="${entry.digits}" '
        'param="transfer ${_dialoutTemplate(entry.transfer.extension, option)}"/>');
  } else if (entry is model.IvrVoicemail) {
    returnValue.add(
        '<entry action="${PbxKey.menuExecApp}" digits="${entry.digits}" param="voicemail default \$\${domain} ${entry.voicemail.vmBox}"/>');
  } else if (entry is model.IvrSubmenu) {
    returnValue.add(
        '<entry action="${PbxKey.menuSub}" digits="${entry.digits}" param="${entry.name}"/>');
  } else if (entry is model.IvrTopmenu) {
    returnValue
        .add('<entry action="${PbxKey.menuTop}" digits="${entry.digits}"/>');
  } else throw new ArgumentError.value(
      entry.runtimeType,
      'entry'
      'type ${entry.runtimeType} is not supported by translation tool');

  return returnValue;
}

Iterable<String> ivrOf(model.ReceptionDialplan rdp) => rdp.allActions
    .where((action) => action is model.Ivr)
    .map((ivr) => ivr.menuName);

@deprecated
String convertVoicemail(model.Voicemail vm) => _voicemailToXml(
    vm,
    new DialplanCompilerOpts(
        goLive: goLive,
        greetingDir: greetingDir,
        testEmail: testEmail,
        testNumber: testNumber));

/**
 *
 */
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
