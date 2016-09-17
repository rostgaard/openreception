/*                  This file is part of OpenReception
                   Copyright (C) 2016-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

/// Serialization keys used by configuration files and arguments.
library orf.configuration_constants;

const String hostname = 'hostname';
const String password = 'password';
const String port = 'port';

const String esl = 'esl';
const String authServer = 'auth-server';
const String cdr = 'cdr-server';
const String callflow = 'call-flow-control';
const String contactServer = 'contact-server';
const String configServer = 'config-server';
const String dialplanServer = 'dialplan-server';
const String receptionServer = 'reception-server';
const String calendarServer = 'calendar-server';
const String userServer = 'user-server';
const String messageServer = 'message-server';
const String messageDispatcher = 'message-dispatcher';
const String notificationServer = 'notification-server';
const String smtp = 'smtp';
const String datastorePath = 'datastore-path';
const String configFile = 'config-file';

const String eslHostname = '$esl-$hostname';
const String eslPassword = '$esl-$password';
const String eslPort = '$esl-$port';

const String externalHostname = 'external-hostname';
const String serverToken = 'server-token';
const String cdrCtlPath = 'cdrctl-path';

const String peerContexts = 'peer-contexts';
const String agentChantimeOut = 'agent-channel-timeout';
const String originateTimeout = 'origination-timeout';
const String callerIdName = 'caller-id-name';
const String callerIdNumber = 'caller-id-number';
const String recordingsDir = 'recordings-dir';
const String enableRecordings = 'enable-recordings';

const String ignoreBadCertificate = 'ignore-bad-certificate';
const String secure = 'secure';
const String name = 'name';
const String username = 'username';

const String mailerPeriod = 'mailerPeriod';
const String smsKey = 'sms-key';
const String staticSenderAddress = 'static-sender-address';
const String staticSenderName = 'static-sender-name';

const String googleclientId = 'google-client-id';
const String googleclientSecret = 'google-client-secret';
const String tokenDir = 'token-dir';
const String tokenLifetime = 'token-lifetime';

const String freeswitchConfPath = 'freeswitch-conf-path';
const String goLive = 'go-live';
const String playbackPrefix = 'playback-prefix';
const String testNumber = 'test-number';
const String testEmail = 'test-email';

const String authUri = 'auth-uri';
const String notificationUri = 'notification-uri';
const String experimentalRevisioning = 'experimental-revisioning';
