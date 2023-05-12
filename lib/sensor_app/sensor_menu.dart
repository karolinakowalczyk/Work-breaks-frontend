
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

class SensorMenu extends StatefulWidget {
  const SensorMenu({super.key});

  @override
  State<SensorMenu> createState() => _SensorMenuState();
}

class _SensorMenuState extends State<SensorMenu> {
  static const metawearPlatform = MethodChannel('com.example.ppiwd_work_breaks_frontend/metawear');

  @override
  void initState() {
    super.initState();
    metawearPlatform.setMethodCallHandler(metaWearCallback);
  }

  Future<void> metaWearCallback(MethodCall call) async {
    switch (call.method) {
      case "putAccel":
        developer.log('[${call.arguments['timestamp']}] accel: ${call.arguments['data']}', name: 'ppiwd/accel');
        break;
      case "putGyro":
        developer.log('[${call.arguments['timestamp']}] gyro: ${call.arguments['data']}', name: 'ppiwd/gyro');
        break;
      case "putBleScanResult":
        ((call.arguments) as Map).forEach((key, value) {
          developer.log('device: ${value['name']} [${value['mac']}]', name: 'ppiwd/ble');
        });
        break;
      case "connected":
        developer.log('connected: ${call.arguments['mac']}', name: 'ppiwd/board');
        break;
      case "disconnected":
        developer.log('disconnected: ${call.arguments['mac']}', name: 'ppiwd/board');
        break;
      case "connectFailure":
        developer.log('connectFailure: ${call.arguments['mac']}', name: 'ppiwd/board');
        break;
    }
  }

  void _connectMetaWear() async {
    try {
      await metawearPlatform.invokeMethod("connect", {'mac': "F7:EA:A1:28:AE:F9"});
    } on PlatformException catch (e) {
      developer.log('failed to connect: ${e.message}');
    }
  }

  void _disconectMetaWear() async {
    try {
      await metawearPlatform.invokeMethod("disconnect");
    } on PlatformException catch (e) {
      developer.log('failed to disconnect: ${e.message}');
    }
  }

  void _scanBle() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect
    ].request();
    if (statuses.values.every((status) => status != PermissionStatus.granted)) {
      developer.log('bluetooth permission is required');
    }
    try {
      await metawearPlatform.invokeMethod("scan", {'period': 5000});
    } on PlatformException catch (e) {
      developer.log('failed to scan: ${e.message}');
    }
  }

  void _startMeasurements() async {
    try {
      await metawearPlatform.invokeMethod("startMeasurements");
    } on PlatformException catch (e) {
      developer.log('failed to start measurements: ${e.message}');
    }
  }

  void _stopMeasurements() async {
    try {
      await metawearPlatform.invokeMethod("stopMeasurements");
    } on PlatformException catch (e) {
      developer.log('failed to stop measurements: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [  
              Container(  
                margin: const EdgeInsets.all(25),  
                child: ElevatedButton(  
                  onPressed: _connectMetaWear,  
                  child: const Text('Connect board'),
                ),  
              ),  
              Container(  
                margin: const EdgeInsets.all(25),  
                child: ElevatedButton(  
                  onPressed: _disconectMetaWear,  
                  child: const Text('Disconnect board'),  
                ),  
              ), 
              Container(  
                margin: const EdgeInsets.all(25),  
                child: ElevatedButton(  
                  onPressed: _scanBle,  
                  child: const Text('Scan ble devices'),  
                ),  
              ),
              Container(  
                margin: const EdgeInsets.all(25),  
                child: ElevatedButton(  
                  onPressed: _startMeasurements,  
                  child: const Text('Start measurements'),  
                ),  
              ),  
              Container(  
                margin: const EdgeInsets.all(25),  
                child: ElevatedButton(  
                  onPressed: _stopMeasurements,  
                  child: const Text('Stop measurements'),  
                ),  
              ),  
          ],)
        ),
      )
    );
  }
}
