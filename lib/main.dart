import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
      case "putBleDevice":
        developer.log('device: ${call.arguments['name']} [${call.arguments['mac']}]', name: 'ppiwd/gyro');
        break;
      case "connected":
        developer.log('connected: ${call.arguments['mac']}', name: 'ppiwd/gyro');
        break;
      case "disconnected":
        developer.log('disconnected: ${call.arguments['mac']}', name: 'ppiwd/gyro');
        break;
      case "connectFailure":
        developer.log('connectFailure: ${call.arguments['mac']}', name: 'ppiwd/gyro');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(child: Column(children: <Widget>[  
            Container(  
              margin: const EdgeInsets.all(25),  
              child: TextButton(  
                onPressed: _connectMetaWear,  
                child: const Text('Connect'),
              ),  
            ),  
            Container(  
              margin: const EdgeInsets.all(25),  
              child: TextButton(  
                onPressed: _disconectMetaWear,  
                child: const Text('Disconnect'),  
              ),  
            ), 
            Container(  
              margin: const EdgeInsets.all(25),  
              child: TextButton(  
                onPressed: _scanBle,  
                child: const Text('Scan'),  
              ),  
            ),  
          ] )));
  }
}
