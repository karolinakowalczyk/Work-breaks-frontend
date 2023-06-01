import 'package:flutter/material.dart';
import 'package:ppiwd_work_breaks_frontend/sensor_client.dart';

class MetawearConnect extends StatefulWidget {
  const MetawearConnect({super.key, required this.sensorClient});
  final SensorClient sensorClient;

  @override
  State<MetawearConnect> createState() => _MetawearConnectState();
}

class _MetawearConnectState extends State<MetawearConnect> {
  static const META_WEAR_NAME = "MetaWear";
  bool _connecting = false;
  List<BleScanResult>? _bleScanResults;

  @override
  void initState() {
    super.initState();
    widget.sensorClient.addBleScanResultHandler(handleBleScanResults);
    widget.sensorClient.addConnectedHandler(handleConnect);
    widget.sensorClient.scanBle();
  }

  @override
  void dispose() {
    super.dispose();
    widget.sensorClient.removeBleScanResultHandler(handleBleScanResults);
    widget.sensorClient.removeConnectedHandler(handleConnect);
  }

  void handleBleScanResults(List<BleScanResult> bleScanResults) {
    setState(() {
      _bleScanResults = bleScanResults
          .where((device) => device.name.contains(META_WEAR_NAME))
          .toList();
    });
  }

  void handleConnect(String mac) {
    Navigator.of(context).pop();
  }

  void refreshDevices() {
    setState(() {
      _bleScanResults = null;
    });
    widget.sensorClient.scanBle();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 55, 189, 246),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _bleScanResults == null
                ? loadingDevicesWidget()
                : loadedDevicesWidget(),
          ],
        ),
      ),
    );
  }

  Widget loadingDevicesWidget() {
    return Column(
      children: const [
        Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text('Trwa wczytywanie urządzeń...')),
        CircularProgressIndicator()
      ],
    );
  }

  Widget loadedDevicesWidget() {
    return SingleChildScrollView(
        child: Container(
      child: _connecting
          ? connectingWidget()
          : _bleScanResults?.isEmpty ?? false
              ? noBleDevicesWidget()
              : foundDevicesWidget(),
    ));
  }

  Widget noBleDevicesWidget() {
    return Center(
        child: Column(children: [
      Container(
        margin: const EdgeInsets.all(16),
        child: const Text('Nie znaleziono urządzeń MetaWear'),
      ),
      ElevatedButton(onPressed: refreshDevices, child: const Text('Odśwież')),
    ]));
  }

  Widget connectingWidget() {
    return const Center(
      child: Text('Łączenie z urządzeniem...'),
    );
  }

  Widget foundDevicesWidget() {
    return ListView(
        padding: const EdgeInsets.all(8),
        shrinkWrap: true,
        children: _bleScanResults
                ?.map((bleScanResult) => SizedBox(
                      height: 40,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                Text(bleScanResult.name),
                                Text(bleScanResult.mac),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            child: const Text(
                              'Połącz',
                            ),
                            onPressed: () {
                              setState(() {
                                _connecting = true;
                              });
                              widget.sensorClient
                                  .connectMetaWear(bleScanResult.mac);
                            },
                          ),
                        ],
                      ),
                    ))
                .toList() ??
            []);
  }
}
