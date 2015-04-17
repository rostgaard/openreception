part of miscserver.router;

final Map client_config =
  {
      "standardGreeting"  : "Velkommen til...",

      "callFlowServerURI"     : config.callFlowServerUri.toString(),
      "receptionServerURI"    : config.receptionServerUri.toString(),
      "contactServerURI"      : config.contactServerUri.toString(),
      "messageServerURI"      : config.messageServerUri.toString(),
      "logServerURI"          : config.logServerUri.toString(),
      "authServerURI"         : config.authServerUri.toString(),

      "notificationSocket": {
          "interface": config.notificationSocketUri.toString(),
          "reconnectInterval": 2000
      },

      "serverLog": {
          "level": "info",
          "interface": {
              "critical": "/log/critical",
              "error": "/log/error",
              "info": "/log/info"
          }
      }
  };


shelf.Response getBobConfig(shelf.Request request) =>
  new shelf.Response.ok(JSON.encode(client_config));

