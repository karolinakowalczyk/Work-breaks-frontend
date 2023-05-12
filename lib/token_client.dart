import 'dart:convert';
import 'package:http/http.dart';

// need to change to address of server
String hostAddress = 'http://192.168.0.10:8080';

class TokenClient {
  final _authorizationEndpoint = Uri.parse('$hostAddress/users/authentication/authenticate');

  final _tokenHeader = 'Authorization';
  final _jsonHeader = 'Content-Type';

  final _client = Client();
  String? _credentials;

  bool get loggedOut => _credentials != null;

  Future<Response> authorize(String email, String password) async {
    var requestBody = jsonEncode({
      'email': email,
      'password': password,  
    });
    return Response(jsonEncode({'noop': 'null'}), 200);
    try {
      var response = await _client.post(_authorizationEndpoint, 
                            headers: {_jsonHeader: 'application/json'}, body: requestBody);
      if(response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        _credentials = responseBody['accessToken'];
      }
      return response;
    } catch(error) {
      return Response('{"error": "$error"}', 404);
    }
  }

  Future<Response> send(BaseRequest request) async { 
    return Response(jsonEncode({'noop': 'null'}), 200);

    request.headers[_tokenHeader] = 'Bearer $_credentials';
    request.headers[_jsonHeader] = 'application/json';

    var response = await Response.fromStream(await _client.send(request));
    return response;
  }

  String? getErrorMessage(Response response) {
    switch(response.statusCode)
      {
        case 200:
          return null;
        case 401:
          return 'Access denied';
        case 404:
          return 'Connection lost';
        default:
          return 'Unknown error';
      }
  }

  void logOut() {
    _credentials = null;
  }
}
