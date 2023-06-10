import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ppiwd_work_breaks_frontend/activity_client.dart';
import 'package:ppiwd_work_breaks_frontend/packemeasurement_client.dart';
import 'package:ppiwd_work_breaks_frontend/sensor_app/account_chart.dart';
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
  bool _connectDeviceShown = false;
  bool _isTimerRunning = false;

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

  void setIsTimmerRunning(bool isRunning) {
    setState(() {
      _isTimerRunning = isRunning;
    });
  }

  void _handleMenuDestinationSelection(int value) {
    if (_isTimerRunning) {
      var snackBar = const SnackBar(
        content: Text("Wyłącz timer przed zmianą widoku"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }
    if (value == 2) {
      widget.tokenClient.logOut();
      widget.sensorClient.disconectMetaWear();
      context.go('/');
      return;
    }
    setState(() {
      _selectedIndex = value;
    });
  }

  List<Widget> getClockWidget() {
    return [
      ActivityClock(
        activityClient: widget.activityClient,
        sensorClient: widget.sensorClient,
        setIsTimerRunning: setIsTimmerRunning,
      )
    ];
  }

  List<Widget> getChartWidget() {
    return [AccountChart(activityClient: widget.activityClient)];
  }

  List<Widget> getActiveMenuComponent() {
    switch (_selectedIndex) {
      case 0:
        return getClockWidget();
      case 1:
        return getChartWidget();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    if (!_deviceConnected && !_connectDeviceShown) {
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
      setState(
        () => _connectDeviceShown = true,
      );
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
            ...getActiveMenuComponent(),
            MeasurementsResult(
                sensorClient: widget.sensorClient,
                packedMeasurementClient: widget.packedMeasurementClient,
                isTimmerRunning: _isTimerRunning),
          ])),
          Container(
            color: Styles.navigationRailColor,
            child: SafeArea(
              child: NavigationRail(
                backgroundColor: Styles.navigationRailColor,
                destinations: const [
                  NavigationRailDestination(
                    icon:
                        Icon(Icons.sensors, color: Styles.navigationIconColor),
                    label: Text('Czujniki'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.area_chart,
                        color: Styles.navigationIconColor),
                    label: Text('Wykresy'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.logout, color: Styles.navigationIconColor),
                    label: Text('Wyloguj'),
                  ),
                ],
                selectedIndex: _selectedIndex,
                onDestinationSelected: _handleMenuDestinationSelection,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
