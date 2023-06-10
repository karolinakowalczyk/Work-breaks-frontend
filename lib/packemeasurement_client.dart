import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:ppiwd_work_breaks_frontend/activity_client.dart';
import 'package:ppiwd_work_breaks_frontend/datetime_helpers.dart';
import 'package:ppiwd_work_breaks_frontend/sensor_client.dart';
import 'dart:developer' as developer;
import '../token_client.dart';
import 'package:timezone/timezone.dart' as tz;

enum ActivityType {
  walking,
  inPlaceRunning,
  forwardFolding,
  jumpingJacks,
  squats,
  working,
  noActivity
}

class MeasurementResponseDto {
  tz.TZDateTime measuredAt;
  ActivityType type;

  MeasurementResponseDto(this.measuredAt, this.type);
}

class MeasurementDto {
  String timestamp;
  CoordinatesDto accelerator;
  CoordinatesDto? gyroscope;

  MeasurementDto(this.timestamp, this.accelerator);

  void setGyroscope(CoordinatesDto gyroscope) {
    this.gyroscope = gyroscope;
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'accelerator': accelerator.toJson(),
      'gyroscope': gyroscope?.toJson()
    };
  }

  MeasurementDto clone() {
    var newMeasurementDto = MeasurementDto(timestamp, accelerator);
    if (gyroscope != null) {
      newMeasurementDto.setGyroscope(gyroscope!.clone());
    }
    return newMeasurementDto;
  }
}

class PackedMeasurementsDto {
  static const PACKED_SIZE = 250;
  static const CLEAR_INDEX = 250;
  static const MEASUREMENTS_PER_SECOND = 50;

  List<MeasurementDto> data = [];

  static Duration getPackageDuration() {
    return Duration(
        milliseconds: (CLEAR_INDEX / MEASUREMENTS_PER_SECOND * 1000).toInt());
  }

  void clear() {
    if (data.length >= CLEAR_INDEX) {
      data = [...data.sublist(CLEAR_INDEX)];
    } else {
      data = [];
    }
  }

  void add(MeasurementDto measurement) {
    data.add(measurement);
  }

  bool isProperLength() {
    return data.length >= PACKED_SIZE;
  }

  PackedMeasurementsDto clone() {
    var newPackedMeasurementsDto = PackedMeasurementsDto();
    for (MeasurementDto element in data) {
      newPackedMeasurementsDto.add(element.clone());
    }
    return newPackedMeasurementsDto;
  }

  @override
  String toString() {
    return 'PackedMeasurementsDto[size: ${data.length}]';
  }

  Map<String, dynamic> toJson() {
    return {'data': List<dynamic>.from(data.map((entry) => entry.toJson()))};
  }

  PackedMeasurementsDto getAndClear() {
    var cloned = clone();
    clear();
    return cloned;
  }
}

class PackedMeasurementClient {
  final TokenClient _tokenClient;
  PackedMeasurementClient(this._tokenClient);

  Future<MeasurementResponseDto> getMeasurement(
      PackedMeasurementsDto packedMeasurements) async {
    var request = Request('POST', Uri.parse('$hostAddress/measurement'));
    developer.log(packedMeasurements.toString());
    request.body = jsonEncode(packedMeasurements.toJson());
    Response response = await _tokenClient.send(request);
    if (response.statusCode != 200) {
      throw Exception(_tokenClient.getErrorMessage(response));
    }
    var json = jsonDecode(response.body);
    return convertToActivityResponseDto(json);
  }

  MeasurementResponseDto convertToActivityResponseDto(dynamic json) {
    return MeasurementResponseDto(
        DateTimeHelpers().parseIsoDateTime(json['measuredAt']),
        ActivityClient.convertToActivityType(json['type']));
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
    case ActivityType.noActivity:
      return 'Brak aktywności';
    default:
      return '';
  }
}

List<ActivityType> getMeasurableActivityTypes() {
  return [
    ActivityType.walking,
    ActivityType.inPlaceRunning,
    ActivityType.forwardFolding,
    ActivityType.jumpingJacks,
    ActivityType.squats,
    ActivityType.working
  ];
}

List<ActivityType> getExerciseActivityTypes() {
  return [
    ActivityType.walking,
    ActivityType.inPlaceRunning,
    ActivityType.forwardFolding,
    ActivityType.jumpingJacks,
    ActivityType.squats
  ];
}
