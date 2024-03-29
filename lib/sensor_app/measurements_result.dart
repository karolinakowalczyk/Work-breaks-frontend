import 'package:flutter/material.dart';
import 'package:ppiwd_work_breaks_frontend/packemeasurement_client.dart';
import 'package:ppiwd_work_breaks_frontend/sensor_client.dart';
import 'dart:developer' as developer;

class MeasurementsResult extends StatefulWidget {
  const MeasurementsResult(
      {super.key,
      required this.sensorClient,
      required this.packedMeasurementClient,
      required this.isTimmerRunning});
  final SensorClient sensorClient;
  final PackedMeasurementClient packedMeasurementClient;
  final bool isTimmerRunning;

  @override
  State<MeasurementsResult> createState() => _MeasurementsResultState();
}

class _MeasurementsResultState extends State<MeasurementsResult> {
  MeasurementDto? currentMeasurement;
  PackedMeasurementsDto packedMeasurements = PackedMeasurementsDto();
  ActivityType activityType = ActivityType.working;

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
        var measurement = await widget.packedMeasurementClient
            .getMeasurement(packedMeasurements.getAndClear());
        setState(() {
          activityType = measurement.type;
        });
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
    return widget.isTimmerRunning
        ? Column(
            children: [
              const SizedBox(height: 16),
              Text(
                  "Obecnie wykonywana czynność: ${getActivityTypeName(activityType)}")
            ],
          )
        : Column();
  }
}
