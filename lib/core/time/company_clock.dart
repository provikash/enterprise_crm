import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

abstract interface class CompanyClock {
  DateTime now();
  DateTime inCompanyTime(DateTime value);
  String formatDate(DateTime value);
}

class TimeZoneCompanyClock implements CompanyClock {
  final tz.Location location;
  final DateFormat _dateFormat;

  TimeZoneCompanyClock({required this.location, DateFormat? dateFormat})
    : _dateFormat = dateFormat ?? DateFormat('dd MMM yyyy');

  @override
  DateTime now() => tz.TZDateTime.now(location);

  @override
  DateTime inCompanyTime(DateTime value) => tz.TZDateTime.from(value, location);

  @override
  String formatDate(DateTime value) => _dateFormat.format(inCompanyTime(value));
}
