import 'package:flutter/material.dart';
import 'credentials_form.dart';
import 'login_helpers.dart';

class LoginForm extends StatelessWidget {
  LoginForm({super.key, required this.errorMsg, required this.validateLogin, required this.navigate,
              this.initialEmail = '', this.initialPassword = ''}) {
    form = CredentialsForm(
      errorMsg: errorMsg,
      sendDataFunc: _login,
      sendDataButtonText: 'Zaloguj',
      initialEmail: initialEmail,
      initialPassword: initialPassword,
    );
  }
  final Function(String email, String password) validateLogin;
  final VoidCallback navigate;
  final String errorMsg;
  final String initialEmail;
  final String initialPassword;
  late final CredentialsForm form; 

  void _login(String email, String password) {
    validateLogin(email, password);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Zaloguj się, aby kontynuować', style: Styles.informationStyle,),
        const SizedBox(height: 5.0,),
        form,
        TextButton(
          onPressed: navigate,
          child: Text(
            'Nie masz konta?',
            style: TextStyle(
              decoration: TextDecoration.underline,
              decorationColor: Theme.of(context).primaryColor,
            ),  
          ),
        ),
    ]);
  }
}
