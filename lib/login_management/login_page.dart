import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ppiwd_work_breaks_frontend/token_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_form.dart';
import 'login_management.dart';
import 'register_form.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key, required this.tokenClient}) {
    initManager();
  }
  late final LoginManagement _manager;
  final TokenClient tokenClient;

  void initManager() async {
    _manager = LoginManagement(tokenClient);
  }

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? _email;
  String? _password;
  bool _isRegister = false;
  String _errorMsg = '';

  void navigate() {
    setState(() {
      _isRegister = !_isRegister;
    });
  }

  void _logon(String email, String password, BuildContext context) async {
    String? response = await widget._manager.validateLogin(email, password);
    setState(() {
      _email = email;
      _password = password;
      _errorMsg = response ?? '';
    });
    if (response == null) {
      if (context.mounted) {
        context.go('/sensors');
      }
    }
  }

  void _register(String email, String password, BuildContext context) async {
    String? response = await widget._manager.registerUser(email, password);
    setState(() {
      _email = email;
      _password = password;
      _errorMsg = response ?? '';
    });
    if (response == null) {
      await widget._manager.validateLogin(email, password);
      if (context.mounted) {
        context.go('/sensors');
      }
    }
  }

  void loadInitData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? credentials = prefs.getString('credentials')?.split(',');

    if (credentials != null) {
      setState(() {
        _email = credentials[0];
        _password = credentials[1];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadInitData();
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    Widget returnButton;

    if (_isRegister) {
      page = RegisterForm(
        errorMsg: _errorMsg,
        registerUser: ((email, password) =>
            _register(email, password, context)),
      );
      returnButton = Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.keyboard_return),
            color: Theme.of(context).primaryColor,
            onPressed: navigate,
          ));
    } else {
      page = LoginForm(
        errorMsg: _errorMsg,
        validateLogin: ((email, password) => _logon(email, password, context)),
        navigate: navigate,
        initialEmail: _email ?? '',
        initialPassword: _password ?? '',
      );
      returnButton = const Text('');
    }

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              alignment: Alignment.center,
              fit: BoxFit.none,
              matchTextDirection: false,
              image: AssetImage('assets/images/gym.jpg'),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: SizedBox(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  color: Colors.black54,
                  child: Stack(
                    children: [
                      returnButton,
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 15.0, horizontal: 30.0),
                        child: page,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
