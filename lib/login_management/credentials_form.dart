import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_helpers.dart';

class CredentialsForm extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  CredentialsForm({super.key, required this.sendDataFunc, required this.errorMsg, this.sendDataButtonText = 'Send', 
                    this.initialEmail = '', this.initialPassword = ''}) {
                      _email.text = initialEmail;
                      _password.text = initialPassword;
  }
  final String errorMsg;
  final void Function(String email, String password) sendDataFunc;
  final String initialEmail;
  final String initialPassword;
  final String sendDataButtonText;

  void sendData() {
    if(_formKey.currentState!.validate()) {
      sendDataFunc(_email.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Wrap(
              runSpacing: 5.0,
              children: [
                TextFormField(
                  controller: _email,
                  validator: Validators.validateEmail,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9a-zA-Z@.-]+'))],
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                    border: const OutlineInputBorder(),
                    labelText: 'Email address',
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decorationColor: Theme.of(context).primaryColor,
                  ),
                ),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  obscuringCharacter: '*',
                  validator: Validators.validatePassword,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9a-zA-Z]+'))],
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                    border: const OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decorationColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          )
        ),
        ElevatedButton(
          onPressed: sendData,
          style: Styles.formButtonStyle,
          child: Text(sendDataButtonText),
        ),
        Text(errorMsg, style: const TextStyle(color: Colors.red,),),
    ]);
  }
}
