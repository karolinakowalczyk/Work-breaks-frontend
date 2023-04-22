import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
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
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

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

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
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
          ] )));
  }
}
