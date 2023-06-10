import 'package:timezone/timezone.dart' as tz;

class DateTimeHelpers {
  final tz.Location location = tz.getLocation("Europe/Warsaw");

  tz.TZDateTime parseIsoDateTime(String isoDateTime) {
    DateTime dateTime = DateTime.parse(isoDateTime);
    return tz.TZDateTime.from(dateTime, location);
  }

  Duration getDurationFromNow(
      tz.TZDateTime dateTime, tz.TZDateTime currentServerTime) {
    tz.TZDateTime phoneDateTime = tz.TZDateTime.now(location);
    Duration phoneServerDifference =
        phoneDateTime.difference(currentServerTime);

    tz.TZDateTime adjustedDateTime = dateTime.add(phoneServerDifference);
    tz.TZDateTime currentDateTime = tz.TZDateTime.now(dateTime.location);

    return currentDateTime.difference(adjustedDateTime);
  }

  tz.TZDateTime now() {
    return tz.TZDateTime.now(location);
  }
}
