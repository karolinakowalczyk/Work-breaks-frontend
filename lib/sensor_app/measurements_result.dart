import 'package:flutter/material.dart';
import 'package:ppiwd_work_breaks_frontend/packemeasurement_client.dart';
import 'package:ppiwd_work_breaks_frontend/sensor_client.dart';
import 'dart:developer' as developer;

class MeasurementsResult extends StatefulWidget {
  const MeasurementsResult(
      {super.key,
      required this.sensorClient,
      required this.packedMeasurementClient});
  final SensorClient sensorClient;
  final PackedMeasurementClient packedMeasurementClient;

  @override
  State<MeasurementsResult> createState() => _MeasurementsResultState();
}

class _MeasurementsResultState extends State<MeasurementsResult> {
  MeasurementDto? currentMeasurement;
  PackedMeasurementsDto packedMeasurements = PackedMeasurementsDto();

  @override
  void initState() {
    super.initState();
    widget.sensorClient.addPutAccelHandler(handlePutAccel);
    widget.sensorClient.addPutGyroHandler(handlePutGyro);
  }

  @override
  void dispose() {
    super.dispose();
    widget.sensorClient.removePutAccelHandler(handlePutAccel);
    widget.sensorClient.removePutGyroHandler(handlePutGyro);
  }

  void handlePutAccel(int timestamp, CoordinatesDto coordinates) {
    currentMeasurement = MeasurementDto(timestamp.toString(), coordinates);
  }

  void handlePutGyro(int timestamp, CoordinatesDto coordinates) async {
    try {
      if (currentMeasurement == null) {
        return;
      }
      currentMeasurement!.setGyroscope(coordinates);
      packedMeasurements.add(currentMeasurement!);
      if (packedMeasurements.isProperLength()) {
        developer.log('sending');
        //todo test with ml endpoints up
        var measurement = await widget.packedMeasurementClient
            .getMeasurement(packedMeasurements.getAndClear());
        developer.log(measurement);
        currentMeasurement = null;
      }
    } catch (e) {
      var snackBar = const SnackBar(
        content: Text("Błąd api podczas wysyłania pomiarów"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column();
  }
}
