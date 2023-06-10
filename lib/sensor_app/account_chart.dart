import 'package:flutter/material.dart';
import 'package:ppiwd_work_breaks_frontend/activity_client.dart';
import 'package:ppiwd_work_breaks_frontend/packemeasurement_client.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AccountChart extends StatefulWidget {
  const AccountChart({super.key, required this.activityClient});
  final ActivityClient activityClient;

  @override
  State<AccountChart> createState() => _AccountChart();
}

class _AccountChart extends State<AccountChart> {
  static final formatter = DateFormat('yyyy.MM.dd HH:mm:ss', 'pl_PL');
  static const int PAGE_SIZE = 1;
  List<TimerDTO> timers = [];
  int currentPage = 0;
  int totalPages = 1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimers(0);
  }

  void _loadTimers(page) async {
    setState(() {
      isLoading = true;
    });
    var response = await widget.activityClient.getAllTimers(page, PAGE_SIZE);
    setState(() {
      timers = response.content;
      totalPages = response.totalPages;
      currentPage = page;
      isLoading = false;
    });
  }

  bool _isPrevEnabled() {
    return !isLoading && currentPage > 0;
  }

  bool _isNextEnabled() {
    return !isLoading && currentPage < totalPages - 1;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    var hours = twoDigits(duration.inHours.abs());
    var minutes = twoDigits(duration.inMinutes.remainder(60).abs());
    return "${duration.isNegative ? '-' : ''}${hours}g ${minutes}m";
  }

  String _getExerciseDuration(TimerDTO timerDTO) {
    var exercisesCount = timerDTO.measurements
        .where((measurement) => measurement.type != ActivityType.working)
        .length;
    return _formatDuration(
        PackedMeasurementsDto.getPackageDuration() * exercisesCount);
  }

  String _getWorkingDuration(TimerDTO timerDTO) {
    var exercisesCount = timerDTO.measurements
        .where((measurement) => measurement.type == ActivityType.working)
        .length;
    return _formatDuration(
        PackedMeasurementsDto.getPackageDuration() * exercisesCount);
  }

  String _getWithoutMeasurementsDuration(TimerDTO timerDTO) {
    return _formatDuration(timerDTO.getWorkDuration() -
        (PackedMeasurementsDto.getPackageDuration() *
            timerDTO.measurements.length));
  }

  String _getPlanedExercisesDuration(TimerDTO timerDTO) {
    var duration = Duration.zero;
    if (timerDTO.activities.isNotEmpty) {
      duration = timerDTO.activities.map((activity) {
        return activity.endAt.difference(activity.startAt);
      }).reduce((activity1, activity2) => activity1 + activity2);
    }
    return _formatDuration(duration);
  }

  Widget _buildTimeDistributionChart(TimerDTO timerDTO) {
    var activityTypesChartValues = ActivityType.values.map((activityType) {
      var duration = timerDTO.getMeasurementsDurationByActivity(activityType);

      return DistributionTimeChartData(getActivityTypeName(activityType),
          duration.inSeconds, _formatDuration(duration));
    }).toList();
    return SfCartesianChart(
        primaryXAxis: CategoryAxis(
          labelRotation: 45,
        ),
        onDataLabelRender: (DataLabelRenderArgs args) {
          args.text =
              activityTypesChartValues[args.pointIndex ?? 0].durationString;
        },
        series: <ChartSeries<DistributionTimeChartData, String>>[
          ColumnSeries<DistributionTimeChartData, String>(
              width: 0.4,
              dataSource: activityTypesChartValues,
              xValueMapper: (DistributionTimeChartData data, _) => data.name,
              yValueMapper: (DistributionTimeChartData data, _) => data.value,
              color: Colors.green,
              dataLabelSettings: const DataLabelSettings(
                isVisible: true,
                textStyle: TextStyle(
                  color: Colors.black, // Set the label text color
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ))
        ]);
  }

  Widget _buildActivityDistributionChart(TimerDTO timerDTO) {
    var activityTypesChartValues = ActivityType.values
        .where((activityType) => activityType != ActivityType.working)
        .map((activityType) {
      var duration =
          timerDTO.getPlanedActivitiesDurationByActivity(activityType);
      return DistributionTimeChartData(getActivityTypeName(activityType),
          duration.inSeconds, _formatDuration(duration));
    }).toList();
    return SfCartesianChart(
        primaryXAxis: CategoryAxis(
          labelRotation: 45,
        ),
        onDataLabelRender: (DataLabelRenderArgs args) {
          args.text =
              activityTypesChartValues[args.pointIndex ?? 0].durationString;
        },
        series: <ChartSeries<DistributionTimeChartData, String>>[
          ColumnSeries<DistributionTimeChartData, String>(
              width: 0.4,
              dataSource: activityTypesChartValues,
              xValueMapper: (DistributionTimeChartData data, _) => data.name,
              yValueMapper: (DistributionTimeChartData data, _) => data.value,
              color: Colors.amber,
              dataLabelSettings: const DataLabelSettings(
                isVisible: true,
                textStyle: TextStyle(
                  color: Colors.black, // Set the label text color
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ))
        ]);
  }

  Widget _buildTimeVsActivityDistributionChart(TimerDTO timerDTO) {
    var activityTypesChartValues = ActivityType.values
        .where((activityType) => activityType != ActivityType.working)
        .map((activityType) {
      var measuredDuration =
          timerDTO.getMeasurementsDurationByActivity(activityType);
      var planedExercisesDuration =
          timerDTO.getPlanedActivitiesDurationByActivity(activityType);
      var duration = measuredDuration - planedExercisesDuration;
      return DistributionTimeChartData(getActivityTypeName(activityType),
          duration.inSeconds, _formatDuration(duration));
    }).toList();
    return SfCartesianChart(
        primaryXAxis: CategoryAxis(
          labelRotation: 45,
        ),
        onDataLabelRender: (DataLabelRenderArgs args) {
          args.text =
              activityTypesChartValues[args.pointIndex ?? 0].durationString;
        },
        series: <ChartSeries<DistributionTimeChartData, String>>[
          ColumnSeries<DistributionTimeChartData, String>(
              width: 0.4,
              dataSource: activityTypesChartValues,
              xValueMapper: (DistributionTimeChartData data, _) => data.name,
              yValueMapper: (DistributionTimeChartData data, _) => data.value,
              color: Colors.cyanAccent,
              dataLabelSettings: const DataLabelSettings(
                isVisible: true,
                textStyle: TextStyle(
                  color: Colors.black, // Set the label text color
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ))
        ]);
  }

  Widget _buildTimer(TimerDTO timerDTO) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              "${formatter.format(timerDTO.start_at)} - ${timerDTO.end_at != null ? formatter.format(timerDTO.end_at!) : '-'}",
              style: const TextStyle(
                fontSize: 14, // Adjust the font size as needed
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
        Row(
          children: [
            Text(
                "Czas pomiaru: ${_formatDuration(timerDTO.getWorkDuration())}"),
          ],
        ),
        Row(
          children: [
            Text("Szacowany czas ćwiczeń: ${_getExerciseDuration(timerDTO)}"),
          ],
        ),
        Row(
          children: [
            Text("Szacowany czas pracy: ${_getWorkingDuration(timerDTO)}"),
          ],
        ),
        Row(
          children: [
            Text(
                "Czas bez pomiarów: ${_getWithoutMeasurementsDuration(timerDTO)}"),
          ],
        ),
        Row(
          children: [
            Text(
                "Planowany czas ćwiczeń: ${_getPlanedExercisesDuration(timerDTO)}"),
          ],
        ),
        Column(
          children: [
            const SizedBox(height: 16),
            const Text("Czas wszystkich aktywności"),
            _buildTimeDistributionChart(timerDTO)
          ],
        ),
        Column(
          children: [
            const SizedBox(height: 16),
            const Text("Planowane ćwiczenia"),
            _buildActivityDistributionChart(timerDTO)
          ],
        ),
        Column(
          children: [
            const SizedBox(height: 16),
            const Text("Planowane ćwiczenia względem aktywności"),
            _buildTimeVsActivityDistributionChart(timerDTO)
          ],
        )
      ],
    );
  }

  Widget _buildTimers() {
    return Column(
      children: timers.map((timerDTO) => _buildTimer(timerDTO)).toList(),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        ElevatedButton(
            onPressed:
                _isPrevEnabled() ? (() => _loadTimers(currentPage - 1)) : null,
            child: const IconTheme(
              data: IconThemeData(size: 30), // Set the size of the icon
              child: Icon(Icons.arrow_left),
            )),
        const SizedBox(width: 10),
        Text("${currentPage + 1}/$totalPages"),
        const SizedBox(width: 10),
        ElevatedButton(
            onPressed:
                _isNextEnabled() ? (() => _loadTimers(currentPage + 1)) : null,
            child: const IconTheme(
              data: IconThemeData(size: 30), // Set the size of the icon
              child: Icon(Icons.arrow_right),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: SingleChildScrollView(
            child: Container(
                margin: EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    _buildButtons(),
                    const SizedBox(height: 16),
                    isLoading
                        ? const CircularProgressIndicator()
                        : _buildTimers()
                  ],
                ))));
  }
}

class DistributionTimeChartData {
  String name;
  int value;
  String durationString;

  DistributionTimeChartData(this.name, this.value, this.durationString);
}
