import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ppiwd_work_breaks_frontend/activity_client.dart';
import 'package:ppiwd_work_breaks_frontend/datetime_helpers.dart';
import 'package:ppiwd_work_breaks_frontend/sensor_client.dart';

class ActivityClock extends StatefulWidget {
  const ActivityClock(
      {super.key, required this.sensorClient, required this.activityClient});
  final SensorClient sensorClient;
  final ActivityClient activityClient;

  @override
  State<ActivityClock> createState() => _ActivityClockState();
}

class _ActivityClockState extends State<ActivityClock> {
  Duration _duration = const Duration();
  Timer? timer;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadTimerState();
  }

  void _loadTimerState() async {
    try {
      var activityState = await widget.activityClient.getActiveActivity();
      Duration duration = const Duration();
      if (activityState != null) {
        duration = DateTimeHelpers().getDurationFromNow(
            activityState.start_at, activityState.currentTime);
        _runTimer();
      } else {
        widget.sensorClient.changeTimerState(false);
        widget.sensorClient.stopMeasurements();
      }
      setState(() {
        loading = false;
        _duration = duration;
      });
    } catch (e) {
      var snackBar = const SnackBar(
        content: Text("Błąd api podczas wczytywania zegara"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _runTimer() {
    widget.sensorClient.startMeasurements();
    widget.sensorClient.changeTimerState(true);
    timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => setState(() {
              final seconds = _duration.inSeconds + 1;
              _duration = Duration(seconds: seconds);
            }));
  }

  void _startTimer() async {
    try {
      await widget.activityClient.startActivity();
      _runTimer();
    } catch (e) {
      var snackBar = const SnackBar(
        content: Text("Błąd api podczas startu zegaru"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _stopTimer() async {
    try {
      await widget.activityClient.stopActivity();
      widget.sensorClient.changeTimerState(false);
      widget.sensorClient.stopMeasurements();
      setState(() {
        timer?.cancel();
        _duration = const Duration();
      });
    } catch (e) {
      var snackBar = const SnackBar(
        content: Text("Błąd api podczas zatrzymania zegaru"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTime(),
          const SizedBox(
            height: 20,
          ),
          _buildButtons()
        ],
      ),
    );
  }

  Widget _buildTime() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_duration.inHours);
    final minutes = twoDigits(_duration.inMinutes.remainder(60));
    final seconds = twoDigits(_duration.inSeconds.remainder(60));
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _buildTimeCard(time: hours, header: 'Godziny'),
      const SizedBox(
        width: 8,
      ),
      _buildTimeCard(time: minutes, header: 'Minuty'),
      const SizedBox(
        width: 8,
      ),
      _buildTimeCard(time: seconds, header: 'Sekundy'),
    ]);
  }

  Widget _buildTimeCard({required String time, required String header}) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Text(
              time,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 50),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Text(header, style: const TextStyle(color: Colors.black45)),
        ],
      );

  Widget _buildButtons() {
    final isRunning = timer == null ? false : timer!.isActive;
    if (loading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text('Trwa wczytywanie zegara...')),
          CircularProgressIndicator()
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isRunning
            ? ElevatedButton(
                onPressed: _stopTimer,
                child: const Text('Stop'),
              )
            : ElevatedButton(
                onPressed: _startTimer,
                child: const Text('Start'),
              ),
      ],
    );
  }
}
