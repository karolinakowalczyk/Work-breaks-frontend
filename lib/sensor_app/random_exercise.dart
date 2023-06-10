import 'package:flutter/material.dart';
import 'package:ppiwd_work_breaks_frontend/sensor_client.dart';

import '../activity_client.dart';

class RandomExercise extends StatefulWidget {
  final ActivityType exerciseType;
  final Duration durationExercise;
  final bool showDuringExerciseTimer;
  final String startExerciseTime;
  const RandomExercise(
      {super.key,
      required this.sensorClient,
      required this.activityClient,
      required this.exerciseType,
      required this.durationExercise,
      required this.showDuringExerciseTimer,
      required this.startExerciseTime});
  final SensorClient sensorClient;
  final ActivityClient activityClient;
  @override
  State<RandomExercise> createState() => _RandomExerciseState();
}

class _RandomExerciseState extends State<RandomExercise> {
  bool showExerciseWidget = false;
  String imagePath = '';
  String exerciseText = '';
  String exerciseTimeInfo = '00 : 00 : 00';

  @override
  void initState() {
    super.initState();
    _getExerciseType();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 20,
          ),
          _buildExerciseText(),
          _buildExerciseImage(),
          const SizedBox(
            height: 20,
          ),
          widget.showDuringExerciseTimer
              ? _buildDuringExcerciseTime()
              : _buildExerciseTimeInfo()
        ],
      ),
    );
  }

  void _getExerciseType() {
    setState(() {
      showExerciseWidget = true;
      exerciseTimeInfo = widget.startExerciseTime;
    });
    switch (widget.exerciseType) {
      case ActivityType.walking:
        setState(() {
          imagePath = 'assets/images/WALKING.png';
          exerciseText = 'Chodzenie';
        });
        break;
      case ActivityType.forwardFolding:
        setState(() {
          imagePath = 'assets/images/FORWARD_FOLDING.png';
          exerciseText = 'Skłony';
        });
        break;
      case ActivityType.inPlaceRunning:
        setState(() {
          imagePath = 'assets/images/IN_PLACE_RUNNING.png';
          exerciseText = 'Bieganie w miejscu';
        });
        break;
      case ActivityType.jumpingJacks:
        setState(() {
          imagePath = 'assets/images/JUMPING_JACKS.png';
          exerciseText = 'Pajacyki';
        });
        break;
      case ActivityType.squats:
        setState(() {
          imagePath = 'assets/images/SQUATS.png';
          exerciseText = 'Przysiady';
        });
        break;
      default:
        setState(() {
          exerciseText = '';
        });
        break;
    }
  }

  Widget _buildExerciseImage() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      showExerciseWidget
          ? Image.asset(
              imagePath,
              height: 300,
              width: 200,
              fit: BoxFit.fitWidth,
            )
          : const Padding(
              padding: EdgeInsets.only(left: 0, bottom: 0, right: 0, top: 10),
              child: Text('Wczytywanie ćwiczenia...',
                  style: TextStyle(color: Colors.black45)),
            ),
    ]);
  }

  Widget _buildExerciseTimeInfo() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      showExerciseWidget
          ? Padding(
              padding:
                  const EdgeInsets.only(left: 0, bottom: 0, right: 0, top: 10),
              child: Text('Start o: $exerciseTimeInfo',
                  style: const TextStyle(color: Colors.black45)),
            )
          : const SizedBox()
    ]);
  }

  Widget _buildExerciseText() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      showExerciseWidget
          ? Padding(
              padding:
                  const EdgeInsets.only(left: 0, bottom: 0, right: 0, top: 10),
              child: Text('Ćwiczenie: $exerciseText',
                  style: const TextStyle(color: Colors.black45)),
            )
          : const SizedBox()
    ]);
  }

  Widget _buildDuringExcerciseTime() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(widget.durationExercise.inHours);
    final minutes = twoDigits(widget.durationExercise.inMinutes.remainder(60));
    final seconds = twoDigits(widget.durationExercise.inSeconds.remainder(60));
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _buildTimeCard(time: hours),
      const SizedBox(
        width: 6,
      ),
      _buildTimeCard(time: minutes),
      const SizedBox(
        width: 6,
      ),
      _buildTimeCard(time: seconds),
    ]);
  }

  Widget _buildTimeCard({required String time}) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20)),
            child: Text(
              time,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 30),
            ),
          ),
        ],
      );
}
