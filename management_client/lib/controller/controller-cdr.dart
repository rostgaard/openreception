part of orm.controller;

class Cdr {
  final Uri _host;
  final String _token;

  Cdr(Uri this._host, String this._token);

  Future<Map<String, dynamic>> summaries(
      DateTime from, DateTime to, String rids) {
    final String f = Uri.encodeComponent(from.toIso8601String());
    final String t = Uri.encodeComponent(to.toIso8601String());
    String url = '$_host/from/$f/to/$t/kind/summary?token=$_token';

    if (rids.trim().isNotEmpty) {
      url += '&rids=${Uri.encodeComponent(rids.trim())}';
    }

    return html.HttpRequest.getString(url).then((String response) {
      return json.decode(response) as Map<String, dynamic>;
    });
  }

  Future<Map<String, dynamic>> list(
      DateTime from, DateTime to, String direction, String rids, String uids) {
    final String f = Uri.encodeComponent(from.toIso8601String());
    final String t = Uri.encodeComponent(to.toIso8601String());
    String url = '$_host/from/$f/to/$t/kind/list?token=$_token';

    url += '&direction=$direction';

    if (rids.trim().isNotEmpty) {
      url += '&rids=${Uri.encodeComponent(rids.trim())}';
    }

    if (uids.trim().isNotEmpty) {
      url += '&uids=${Uri.encodeComponent(uids.trim())}';
    }

    return html.HttpRequest.getString(url).then((String response) {
      return json.decode(response) as Map<String, dynamic>;
    });
  }
}
