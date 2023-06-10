import 'dart:convert';
import 'package:http/http.dart';

// need to change to address of server
String hostAddress = 'http://192.168.8.105:8080';

class TokenClient {
  final _authorizationEndpoint = Uri.parse('$hostAddress/login');

  final _tokenHeader = 'Authorization';
  final _jsonHeader = 'Content-Type';

  final _client = Client();
  String? _credentials;

  bool get loggedOut => _credentials != null;

  Future<Response> authorize(String login, String password) async {
    var requestBody = jsonEncode({
      'login': login,
      'password': password,
    });
    try {
      var response = await _client.post(_authorizationEndpoint,
          headers: {_jsonHeader: 'application/json'}, body: requestBody);
      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        _credentials = responseBody['token'];
      }
      return response;
    } catch (error) {
      return Response('{"error": "$error"}', 404);
    }
  }

  Future<Response> send(BaseRequest request) async {
    request.headers[_tokenHeader] = 'Bearer $_credentials';
    request.headers[_jsonHeader] = 'application/json';
    var response = await Response.fromStream(await _client.send(request));
    return response;
  }

  String? getErrorMessage(Response response) {
    switch (response.statusCode) {
      case 200:
        return null;
      case 401:
        return 'Błąd autoryzacji';
      case 404:
        return 'Nie znaleziono zasobu';
      case 503:
        return 'Usługa niedostępna';
      default:
        return 'Nieznany błąd';
    }
  }

  void logOut() {
    _credentials = null;
  }
}
