import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:ppiwd_work_breaks_frontend/datetime_helpers.dart';
import 'package:ppiwd_work_breaks_frontend/sensor_client.dart';
import 'dart:developer' as developer;

import '../token_client.dart';

class ActivityResponseDto {
  String type;

  ActivityResponseDto(this.type);
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

  List<MeasurementDto> data = [];

  void clear() {
    data.clear();
  }

  void add(MeasurementDto measurement) {
    data.add(measurement);
  }

  bool isProperLength() {
    return data.length >= PACKED_SIZE;
  }

  PackedMeasurementsDto clone() {
    var newPackedMeasurementsDto = PackedMeasurementsDto();
    data.forEach((element) {
      newPackedMeasurementsDto.add(element.clone());
    });
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

  Future<String> getMeasurement(
      PackedMeasurementsDto packedMeasurements) async {
    var request = Request('POST', Uri.parse('$hostAddress/measurement'));
    developer.log(packedMeasurements.toString());
    request.body = jsonEncode(packedMeasurements.toJson());
    Response response = await _tokenClient.send(request);
    if (response.statusCode != 200) {
      throw Exception(_tokenClient.getErrorMessage(response));
    }
    var json = jsonDecode(response.body);
    return json['type'];
  }

  ActivityResponseDto convertToActivityResponseDto(dynamic json) {
    return ActivityResponseDto(json['type']);
  }
}
