import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:ppiwd_work_breaks_frontend/datetime_helpers.dart';
import 'package:ppiwd_work_breaks_frontend/sensor_client.dart';

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
}

class PackedMeasurementsDto {
  static const PACKED_SIZE = 50;

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

  @override
  String toString() {
    return 'PackedMeasurementsDto[size: ${data.length}]';
  }

  Map<String, dynamic> toJson() {
    return {'data': List<dynamic>.from(data.map((entry) => entry.toJson()))};
  }
}

class PackedMeasurementClient {
  final TokenClient _tokenClient;
  PackedMeasurementClient(this._tokenClient);

  Future<String> getMeasurement(
      PackedMeasurementsDto packedMeasurements) async {
    var request = Request('POST', Uri.parse('$hostAddress/measurement/packed'));
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
