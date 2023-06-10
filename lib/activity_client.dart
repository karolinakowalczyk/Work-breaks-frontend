import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:ppiwd_work_breaks_frontend/datetime_helpers.dart';
import 'package:ppiwd_work_breaks_frontend/packemeasurement_client.dart';
import 'package:ppiwd_work_breaks_frontend/shared/page_dto.dart';
import 'package:timezone/timezone.dart' as tz;

import '../token_client.dart';

enum ActivityType {
  walking,
  inPlaceRunning,
  forwardFolding,
  jumpingJacks,
  squats,
  working,
  noActivity
}

class TimerDTO {
  tz.TZDateTime start_at;
  tz.TZDateTime? end_at;
  tz.TZDateTime currentTime;
  List<ActivityDto> activities;
  List<MeasurementDto> measurements;

  TimerDTO(this.start_at, this.end_at, this.currentTime, this.activities,
      this.measurements);

  Duration getWorkDuration() {
    var to = end_at ?? DateTimeHelpers().now();
    return to.difference(start_at);
  }

  Duration getMeasurementsDurationByActivity(ActivityType activityType) {
    var measurementsLength = measurements
        .where((measurement) => measurement.type == activityType)
        .length;
    return PackedMeasurementsDto.getPackageDuration() * measurementsLength;
  }

  Duration getPlanedActivitiesDurationByActivity(ActivityType activityType) {
    return activities
        .where((activity) => activity.exercise == activityType)
        .map((activity) {
      return activity.endAt.difference(activity.startAt);
    }).reduce((activity1, activity2) => activity1 + activity2);
  }
}

class ActivityDto {
  ActivityType exercise;
  tz.TZDateTime startAt;
  tz.TZDateTime endAt;
  tz.TZDateTime currentTime;

  ActivityDto(this.exercise, this.startAt, this.endAt, this.currentTime);
}

class MeasurementDto {
  tz.TZDateTime measuredAt;
  ActivityType type;

  MeasurementDto(this.measuredAt, this.type);
}

class ActivityClient {
  final TokenClient _tokenClient;
  ActivityClient(this._tokenClient);

  Future<TimerDTO> startActivity() async {
    var request = Request('POST', Uri.parse('$hostAddress/timer/start'));
    Response response = await _tokenClient.send(request);
    if (response.statusCode != 200) {
      throw Exception(_tokenClient.getErrorMessage(response));
    }
    var body = jsonDecode(response.body);
    return convertToTimerDTO(body);
  }

  Future<TimerDTO> stopActivity() async {
    var request = Request('POST', Uri.parse('$hostAddress/timer/stop'));
    Response response = await _tokenClient.send(request);
    if (response.statusCode != 200) {
      throw Exception(_tokenClient.getErrorMessage(response));
    }
    var body = jsonDecode(response.body);
    return convertToTimerDTO(body);
  }

  Future<TimerDTO?> getActiveActivity() async {
    var request = Request('GET', Uri.parse('$hostAddress/timer/active'));
    Response response = await _tokenClient.send(request);
    if (response.statusCode == 400) {
      return null;
    }
    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      return convertToTimerDTO(body);
    }
    throw Exception(_tokenClient.getErrorMessage(response));
  }

  Future<PageDto<TimerDTO>> getAllTimers(int page, int size) async {
    var request = Request(
        'GET',
        Uri.parse(
            '$hostAddress/timer?page=$page&size=$size&sort=startAt,desc'));
    Response response = await _tokenClient.send(request);
    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      return convertToPageTimerDto(body);
    }
    throw Exception(_tokenClient.getErrorMessage(response));
  }

  Future<ActivityDto> getNextActivity() async {
    var request = Request('GET', Uri.parse('$hostAddress/activity/next'));
    Response response = await _tokenClient.send(request);
    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      return convertToActivityDto(body);
    }
    throw Exception(_tokenClient.getErrorMessage(response));
  }

  PageDto<TimerDTO> convertToPageTimerDto(dynamic json) {
    var timers = (json['content'] as List<dynamic>)
        .map((timer) => convertToTimerDTO(timer))
        .toList();
    return PageDto(timers, json['totalPages']);
  }

  TimerDTO convertToTimerDTO(dynamic json) {
    var activities = (json['activities'] as List<dynamic>)
        .map((activity) => convertToActivityDto(activity))
        .toList();
    var measurements = (json['measurements'] as List<dynamic>)
        .map((measurement) => convertToMeasurementDto(measurement))
        .toList();
    return TimerDTO(
        DateTimeHelpers().parseIsoDateTime(json['start_at']),
        json['end_at'] != null
            ? DateTimeHelpers().parseIsoDateTime(json['end_at'])
            : null,
        DateTimeHelpers().parseIsoDateTime(json['currentTime']),
        activities,
        measurements);
  }

  ActivityType convertToActivityType(String type) {
    switch (type) {
      case "WALKING":
        return ActivityType.walking;
      case "IN_PLACE_RUNNING":
        return ActivityType.inPlaceRunning;
      case "FORWARD_FOLDING":
        return ActivityType.forwardFolding;
      case "JUMPING_JACKS":
        return ActivityType.jumpingJacks;
      case "SQUATS":
        return ActivityType.squats;
      case "WORKING":
        return ActivityType.working;
      case "":
        return ActivityType.noActivity;
      default:
        throw Exception("Invalid input: $type");
    }
  }

  ActivityDto convertToActivityDto(dynamic json) {
    return ActivityDto(
        convertToActivityType(json['exercise']),
        DateTimeHelpers().parseIsoDateTime(json['startAt']),
        DateTimeHelpers().parseIsoDateTime(json['endAt']),
        DateTimeHelpers().parseIsoDateTime(json['currentTime']));
  }

  MeasurementDto convertToMeasurementDto(dynamic json) {
    return MeasurementDto(
        DateTimeHelpers().parseIsoDateTime(json['measuredAt']),
        convertToActivityType(json['type']));
  }
}

String getActivityTypeName(ActivityType activityType) {
  switch (activityType) {
    case ActivityType.walking:
      return 'Chodzenie';
    case ActivityType.inPlaceRunning:
      return 'Bieganie w miejscu';
    case ActivityType.forwardFolding:
      return 'Skłony w przód';
    case ActivityType.jumpingJacks:
      return 'Pajacyki';
    case ActivityType.squats:
      return 'Przysiady';
    case ActivityType.working:
      return 'Praca';
    default:
      return '';
  }
}
