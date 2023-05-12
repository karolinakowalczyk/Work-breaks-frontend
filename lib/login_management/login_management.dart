import 'dart:convert';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../token_client.dart';

class LoginManagement {
  late final TokenClient tokenManager;

  LoginManagement({TokenClient? tokenClient}) {
    tokenManager = tokenClient ??  TokenClient();
  }

  Future<String?> validateLogin(String email, String password) async {
    Response response = await tokenManager.authorize(email, password);
    var potentialError = jsonDecode(response.body);
    var errorMessage = potentialError['error'] ?? potentialError['message'];
    if(errorMessage == null) {
      tokenManager.getErrorMessage(response);
      if(response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('credentials', '$email,$password');
      }
    }
    return errorMessage;
  }

  Future<String?> registerUser(String email, String password) async {
    var request = Request('POST', Uri.parse('$hostAddress/users/authentication/register'));
    request.body = jsonEncode({'email': email, 'password': password});
    Response response = await tokenManager.send(request);
    var potentialError = jsonDecode(response.body);
    var errorMessage = potentialError['error'] ?? potentialError['message'];
    if(errorMessage == null) {
      tokenManager.getErrorMessage(response);
    }
    return errorMessage;
  }
}
