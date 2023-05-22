import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:ppiwd_work_breaks_frontend/datetime_helpers.dart';
import 'package:timezone/timezone.dart' as tz;

import '../token_client.dart';

class TimerDTO {
  String user;
  tz.TZDateTime start_at;
  tz.TZDateTime? end_at;
  tz.TZDateTime currentTime;

  TimerDTO(this.user, this.start_at, this.end_at, this.currentTime);
}

class ActivityClient {
  TokenClient _tokenClient;
  ActivityClient(this._tokenClient);

  Future<TimerDTO> startActivity() async {
    var request = Request('GET', Uri.parse('$hostAddress/start'));
    Response response = await _tokenClient.send(request);
    if (response.statusCode != 200) {
      throw Exception(_tokenClient.getErrorMessage(response));
    }
    var body = jsonDecode(response.body);
    return convertToTimerDTO(body);
  }

  Future<TimerDTO> stopActivity() async {
    var request = Request('GET', Uri.parse('$hostAddress/stop'));
    Response response = await _tokenClient.send(request);
    if (response.statusCode != 200) {
      throw Exception(_tokenClient.getErrorMessage(response));
    }
    var body = jsonDecode(response.body);
    return convertToTimerDTO(body);
  }

  Future<TimerDTO?> getActiveActivity() async {
    var request = Request('GET', Uri.parse('$hostAddress/active'));
    Response response = await _tokenClient.send(request);
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      return convertToTimerDTO(body);
    }
    throw Exception(_tokenClient.getErrorMessage(response));
  }

  TimerDTO convertToTimerDTO(dynamic json) {
    return TimerDTO(
        json['user'],
        DateTimeHelpers().parseIsoDateTime(json['start_at']),
        json['end_at'] != null
            ? DateTimeHelpers().parseIsoDateTime(json['end_at'])
            : null,
        DateTimeHelpers().parseIsoDateTime(json['currentTime']));
  }
}
