import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ppiwd_work_breaks_frontend/activity_client.dart';
import 'package:ppiwd_work_breaks_frontend/packemeasurement_client.dart';
import 'package:ppiwd_work_breaks_frontend/sensor_app/measurements_result.dart';
import 'package:ppiwd_work_breaks_frontend/sensor_client.dart';

import '../token_client.dart';
import 'sensor_helpers.dart';
import 'activity_clock.dart';
import 'metawear_connect.dart';

class SensorApp extends StatefulWidget {
  const SensorApp(
      {super.key,
      required this.tokenClient,
      required this.sensorClient,
      required this.activityClient,
      required this.packedMeasurementClient});
  final TokenClient tokenClient;
  final SensorClient sensorClient;
  final ActivityClient activityClient;
  final PackedMeasurementClient packedMeasurementClient;

  @override
  State<SensorApp> createState() => _SensorAppState();
}

class _SensorAppState extends State<SensorApp> {
  int _selectedIndex = 0;
  bool _deviceConnected = false;

  @override
  void initState() {
    super.initState();
    widget.sensorClient.addConnectedHandler(handleDeviceConnected);
    widget.sensorClient.addDisconnectedHandler(handleDeviceDisconnected);
    widget.sensorClient.addConnectFailureHandler(handleDeviceConnectFailuer);
    _deviceConnected = widget.sensorClient.isDeviceConnected();
  }

  @override
  void dispose() {
    super.dispose();
    widget.sensorClient.removeConnectedHandler(handleDeviceConnected);
    widget.sensorClient.removeConnectedHandler(handleDeviceDisconnected);
    widget.sensorClient.removeConnectFailureHandler(handleDeviceConnectFailuer);
  }

  void handleDeviceConnected(String mac) {
    var snackBar = SnackBar(
      content: Text("Połączono z urząrzeniem: $mac"),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    setState(() {
      _deviceConnected = widget.sensorClient.isDeviceConnected();
    });
  }

  void handleDeviceConnectFailuer(String mac) {
    var snackBar = SnackBar(
      content: Text("Błąd połączenia z urząrzeniem: $mac"),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void handleDeviceDisconnected(String mac) {}

  @override
  Widget build(BuildContext context) {
    if (_deviceConnected == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet<void>(
            context: context,
            isDismissible: false,
            builder: (BuildContext context) {
              return MetawearConnect(
                sensorClient: widget.sensorClient,
              );
            });
      });
    }
    return Scaffold(
      backgroundColor: Colors.orange[50],
      body: Row(
        children: [
          Expanded(
              child: Column(children: [
            const SizedBox(
              height: 50,
            ),
            ActivityClock(
              activityClient: widget.activityClient,
              sensorClient: widget.sensorClient,
            ),
            MeasurementsResult(
                sensorClient: widget.sensorClient,
                packedMeasurementClient: widget.packedMeasurementClient)
          ])),
          Container(
            color: Styles.navigationRailColor,
            child: SafeArea(
              child: NavigationRail(
                backgroundColor: Styles.navigationRailColor,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.sensors,
                        color: Styles.navigationIconColor),
                    label: Text('Czujniki'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.logout, color: Styles.navigationIconColor),
                    label: Text('Wyloguj'),
                  ),
                ],
                selectedIndex: _selectedIndex,
                onDestinationSelected: (value) {
                  if (value == 1) {
                    widget.tokenClient.logOut();
                    widget.sensorClient.disconectMetaWear();
                    context.go('/');
                    return;
                  }
                  setState(() {
                    _selectedIndex = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
