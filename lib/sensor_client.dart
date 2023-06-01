import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'package:permission_handler/permission_handler.dart';

class BleScanResult {
  String mac;
  String name;

  BleScanResult(this.mac, this.name);
}

class CoordinatesDto {
  double x;
  double y;
  double z;
  CoordinatesDto(this.x, this.y, this.z);

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'z': z};
  }
}

class SensorClient {
  static const metawearPlatform =
      MethodChannel('com.example.ppiwd_work_breaks_frontend/metawear');
  String? _connectedDeviceMac;
  bool _timerRunning = false;

  final List<Function(String mac)> _connectedHandlers = [];
  final List<Function(String mac)> _disconnectedHandlers = [];
  final List<Function(List<BleScanResult> scanResults)> _bleScanResultHandlers =
      [];
  final List<Function(String mac)> _connectFailureHandlers = [];
  final List<Function(int timestamp, CoordinatesDto coordinates)>
      _putAccelHandlers = [];
  final List<Function(int timestamp, CoordinatesDto coordinates)>
      _putGyroHandlers = [];

  SensorClient() {
    metawearPlatform.setMethodCallHandler(metaWearCallback);
  }

  void changeTimerState(bool isRunning) {
    _timerRunning = isRunning;
  }

  void addConnectedHandler(Function(String mac) connectHandler) {
    _connectedHandlers.add(connectHandler);
  }

  void removeConnectedHandler(Function(String mac) connectHandler) {
    _connectedHandlers.removeWhere((element) => element == connectHandler);
  }

  void addDisconnectedHandler(Function(String mac) disconnectHandler) {
    _connectedHandlers.add(disconnectHandler);
  }

  void removeDisconnectedHanlder(Function(String mac) disconnectHandler) {
    _connectedHandlers.removeWhere((element) => element == disconnectHandler);
  }

  void addBleScanResultHandler(
      Function(List<BleScanResult> scanResults) scanResultHandler) {
    _bleScanResultHandlers.add(scanResultHandler);
  }

  void removeBleScanResultHandler(
      Function(List<BleScanResult> scanResults) scanResultHandler) {
    _bleScanResultHandlers
        .removeWhere((element) => element == scanResultHandler);
  }

  void addConnectFailureHandler(Function(String mac) connectFailureHandler) {
    _connectFailureHandlers.add(connectFailureHandler);
  }

  void removeConnectFailureHandler(Function(String mac) connectFailureHandler) {
    _connectFailureHandlers
        .removeWhere((element) => element == connectFailureHandler);
  }

  void addPutAccelHandler(
      Function(int timestamp, CoordinatesDto coordinates) putAccelHandler) {
    _putAccelHandlers.add(putAccelHandler);
  }

  void removePutAccelHandler(
      Function(int timestamp, CoordinatesDto coordinates) putAccelHandler) {
    _putAccelHandlers.removeWhere((element) => element == putAccelHandler);
  }

  void addPutGyroHandler(
      Function(int timestamp, CoordinatesDto coordinates) putGyroHandler) {
    _putGyroHandlers.add(putGyroHandler);
  }

  void removePutGyroHandler(
      Function(int timestamp, CoordinatesDto coordinates) putGyroHandler) {
    _putGyroHandlers.removeWhere((element) => element == putGyroHandler);
  }

  Future<void> metaWearCallback(MethodCall call) async {
    switch (call.method) {
      case "putAccel":
        for (var putAccelHandler in _putAccelHandlers) {
          putAccelHandler(
              call.arguments['timestamp'],
              CoordinatesDto(call.arguments['data'][0],
                  call.arguments['data'][1], call.arguments['data'][2]));
        }
        break;
      case "putGyro":
        for (var putGyroHandler in _putGyroHandlers) {
          putGyroHandler(
              call.arguments['timestamp'],
              CoordinatesDto(call.arguments['data'][0],
                  call.arguments['data'][1], call.arguments['data'][2]));
        }
        break;
      case "putBleScanResult":
        List<BleScanResult> scanResults = [];
        ((call.arguments) as Map).forEach((key, value) {
          scanResults.add(BleScanResult(value['mac'], value['name']));
          developer.log('device: ${value['name']} [${value['mac']}]',
              name: 'ppiwd/ble');
        });
        for (var bleScanResultHandler in _bleScanResultHandlers) {
          bleScanResultHandler(scanResults);
        }
        break;
      case "connected":
        _connectedDeviceMac = call.arguments['mac'];
        for (var connectHandler in _connectedHandlers) {
          connectHandler(call.arguments['mac']);
        }
        developer.log('connected: ${call.arguments['mac']}',
            name: 'ppiwd/board');
        break;
      case "disconnected":
        _connectedDeviceMac = null;
        for (var disconnectHandler in _disconnectedHandlers) {
          disconnectHandler(call.arguments['mac']);
        }
        developer.log('disconnected: ${call.arguments['mac']}',
            name: 'ppiwd/board');
        break;
      case "connectFailure":
        for (var connectFailureHandler in _connectFailureHandlers) {
          connectFailureHandler(call.arguments['mac']);
        }
        developer.log('connectFailure: ${call.arguments['mac']}',
            name: 'ppiwd/board');
        break;
    }
  }

  bool isDeviceConnected() {
    return _connectedDeviceMac != null;
  }

  void connectMetaWear(String mac) async {
    try {
      await metawearPlatform.invokeMethod("connect", {'mac': mac});
      if(_timerRunning) {
        startMeasurements();
      }
    } on PlatformException catch (e) {
      developer.log('failed to connect: ${e.message}');
    }
  }

  void disconectMetaWear() async {
    try {
      await metawearPlatform.invokeMethod("disconnect");
    } on PlatformException catch (e) {
      developer.log('failed to disconnect: ${e.message}');
    }
  }

  void scanBle() async {
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

  void startMeasurements() async {
    try {
      await metawearPlatform.invokeMethod("startMeasurements");
    } on PlatformException catch (e) {
      developer.log('failed to start measurements: ${e.message}');
    }
  }

  void stopMeasurements() async {
    try {
      await metawearPlatform.invokeMethod("stopMeasurements");
    } on PlatformException catch (e) {
      developer.log('failed to stop measurements: ${e.message}');
    }
  }
}
