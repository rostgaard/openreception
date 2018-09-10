part of ort.config;

/// Helper functions for keeping track how config resource usage.
abstract class ConfigPool {
  static int aquiredLocalSIPAccounts = 0;
  static int aquiredExternalSipAccounts = 0;
  static int aquiredSnomHosts = 0;
  static int aquiredPjsuaPorts = 0;
  static int aquiredAuthTokens = 0;

  static bool hasAvailableLocalSipAccount() =>
      aquiredLocalSIPAccounts < config.localSipAccounts.length;

  static bool hasAvailableExternalSipAccount() =>
      aquiredExternalSipAccounts < config.externalSipAccounts.length;

  static void resetCounters() {
    aquiredLocalSIPAccounts = 0;
    aquiredExternalSipAccounts = 0;
    aquiredSnomHosts = 0;
    aquiredPjsuaPorts = 0;
    aquiredAuthTokens = 0;
  }

  /// Request the next available local SIP account from the config.
  static SIPAccount requestLocalSipAccount() {
    SIPAccount account =
        config.localSipAccounts.skip(aquiredLocalSIPAccounts).first;
    aquiredLocalSIPAccounts++;

    return account;
  }

  /// Request the next available external SIP account from the config.
  static SIPAccount requestExternalSIPAccount() {
    SIPAccount account =
        config.externalSipAccounts.skip(aquiredExternalSipAccounts).first;
    aquiredExternalSipAccounts++;

    return account;
  }

  /// Request the next available Snom hostname from the config.
  static String requestSNOMHost() {
    String snomHost = config.snomHosts.skip(aquiredSnomHosts).first;
    aquiredSnomHosts++;

    return snomHost;
  }

  /// Request the next available pjsua UDP port from the config.
  static int requestPjsuaPort() {
    int port = config.pjsuaPortAvailablePorts.skip(aquiredPjsuaPorts).first;
    aquiredPjsuaPorts++;

    return port;
  }

  /// Request the next available authentication token from the config.
  static String requestAuthtoken() {
    String token = config.authTokens.skip(aquiredAuthTokens).first;
    aquiredAuthTokens++;

    return token;
  }
}
