import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ppiwd_work_breaks_frontend/token_client.dart';

import 'login_management/login_page.dart';
import 'sensor_app/sensor_app.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TokenClient? _client;

  late final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return LoginPage(assign: (TokenClient client) => _client = client);
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'sensors',
          builder: (BuildContext context, GoRouterState state) {
            return SensorApp(client: _client!,);
          },
        ),
      ],
    ),
  ],
);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      routerConfig: _router,
    );
  }
}
