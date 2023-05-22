import 'package:flutter/material.dart';

abstract class Validators {
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please, fill in the field';
    }
    return null;
  }

  static String? validateLogin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please, fill in the field';
    }
    return null;
  }
}

abstract class Styles {
  static final ButtonStyle formButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.pressed)) {
        return Colors.orange[700];
      }
      return Colors.orange[900];
    }),
    side: const MaterialStatePropertyAll(
      BorderSide(
        color: Color(0xFFD94307),
        width: 1.2,
      ),
    ),
  );

  static const TextStyle informationStyle = TextStyle(
    fontSize: 18,
    color: Colors.deepOrange,
    fontWeight: FontWeight.bold,
  );
}
