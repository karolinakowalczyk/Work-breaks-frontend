import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ppiwd_work_breaks_frontend/activity_client.dart';
import 'package:ppiwd_work_breaks_frontend/datetime_helpers.dart';
import 'package:ppiwd_work_breaks_frontend/sensor_app/random_exercise.dart';
import 'package:ppiwd_work_breaks_frontend/sensor_client.dart';
import 'dart:developer' as developer;

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
  Duration durationExercise = const Duration();
  //String exerciseType = '';
  ActivityType exerciseType = ActivityType.noActivity;
  bool exerciseSelected = false;
  Timer? excerciseTimer;
  bool showDuringExerciseTimer = false;
  String startExerciseTime = '';

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

  // void _tempLoadExerciseType() async {
  //   try {
  //     var exerciseResponse = await widget.activityClient.getNextActivity();
  //   } catch (e) {
  //     var snackBar = const SnackBar(
  //       content: Text("Błąd api podczas losowania ćwiczenia TEMP"),
  //     );
  //     ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //   }
  // }

  void _loadExerciseTypeState() async {
    try {
      //var exerciseResponse = await widget.activityClient.getExercise();
      var exerciseResponse = await widget.activityClient.getNextActivity();
      var start = exerciseResponse.startAt;
      var end = exerciseResponse.endAt;
      var current = exerciseResponse.currentTime;
      var difference = end.difference(start).inSeconds;
      developer.log('DIFFERENCE: $difference');
      var now = DateTime.now();
      developer.log('date time $now');
      setState(() {
        exerciseType = exerciseResponse.exercise;
        exerciseSelected = true;
        durationExercise = Duration(seconds: difference);
        startExerciseTime = '${start.hour} : ${start.minute} : ${start.second}';
      });

      //UNCOMMENT - only for show
      //var differenceFromNow = 10;
      var differenceFromNow = start.difference(current).inSeconds;
      developer.log('DIFFERENCE from now: $differenceFromNow');
      Future.delayed(Duration(seconds: differenceFromNow - 5), () {
        _playRemindingSound();
      });
      Future.delayed(Duration(seconds: differenceFromNow), () {
        showDuringExerciseTimer = true;
        _runDuringExcerciseTimer();
      });
    } catch (e) {
      developer.log('error $e');
      var snackBar = const SnackBar(
        content: Text("Błąd api podczas losowania ćwiczenia"),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _clearExerciseTypeState() {
    setState(() {
      exerciseType = ActivityType.noActivity;
      exerciseSelected = false;
      excerciseTimer?.cancel();
      showDuringExerciseTimer = false;
      startExerciseTime = '';
    });
  }

  void setCountDown() {
    const reduceSecondsBy = 1;
    setState(() {
      final seconds = durationExercise.inSeconds - reduceSecondsBy;
      if (seconds < 0) {
        showDuringExerciseTimer = false;
        excerciseTimer!.cancel();
        _clearExerciseTypeState();
        _loadExerciseTypeState();
      } else {
        durationExercise = Duration(seconds: seconds);
      }
    });
  }

  void _runDuringExcerciseTimer() {
    excerciseTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => setCountDown());
  }

  void _playRemindingSound() async {
    // developer.log("before PLAYED");
    // const path = 'assets/audio/start.mp3';
    // final player = AudioPlayer();
    // await player.play(AssetSource(path));
    developer.log("PLAYED");
  }

  void _startTimer() async {
    try {
      await widget.activityClient.startActivity();
      _runTimer();
      //_tempLoadExerciseType();
      _loadExerciseTypeState();
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
      _clearExerciseTypeState();
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
          _buildButtons(),
          exerciseSelected
              ? RandomExercise(
                  sensorClient: widget.sensorClient,
                  activityClient: widget.activityClient,
                  exerciseType: exerciseType,
                  durationExercise: durationExercise,
                  showDuringExerciseTimer: showDuringExerciseTimer,
                  startExerciseTime: startExerciseTime)
              : const SizedBox()
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
