import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ppiwd_work_breaks_frontend/packemeasurement_client.dart';
import 'package:ppiwd_work_breaks_frontend/sensor_client.dart';
import 'package:ppiwd_work_breaks_frontend/activity_client.dart';
import 'package:ppiwd_work_breaks_frontend/token_client.dart';

import 'login_management/login_page.dart';
import 'sensor_app/sensor_app.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late TokenClient _tokenClient;
  late SensorClient _sensorClient;
  late ActivityClient _activityClient;
  late PackedMeasurementClient _packedMeasurementClient;
  _MyAppState() {
    _tokenClient = TokenClient();
    _sensorClient = SensorClient();
    _activityClient = ActivityClient(_tokenClient);
    _packedMeasurementClient = PackedMeasurementClient(_tokenClient);
  }

  @override
  void initState() {
    super.initState();
  }

  late final GoRouter _router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return LoginPage(
            tokenClient: _tokenClient,
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'sensors',
            builder: (BuildContext context, GoRouterState state) {
              return SensorApp(
                tokenClient: _tokenClient,
                sensorClient: _sensorClient,
                activityClient: _activityClient,
                packedMeasurementClient: _packedMeasurementClient,
              );
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
