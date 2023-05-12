import 'package:flutter/material.dart';

import 'credentials_form.dart';
import 'login_helpers.dart';

class RegisterForm extends StatelessWidget {
  RegisterForm({super.key, required this.errorMsg, required this.registerUser}) {
    form = CredentialsForm(
      errorMsg: errorMsg,
      sendDataFunc: _register,
    );
  }
  final Function(String email, String password) registerUser;
  final String errorMsg;
  late final CredentialsForm form;
  
  void _register(String email, String password) {
    registerUser(email, password);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Please input your data', style: Styles.informationStyle,),
        const SizedBox(height: 5.0,),
        form,
    ]);
  }
}
