abstract class DateTimeReader {
  DateTime now();
}

class DateTimeReaderNow implements DateTimeReader {
  @override
  DateTime now() => DateTime.now().add(Duration(days: 1));
}

class DateTimeReaderTomorrow implements DateTimeReader {
  @override
  DateTime now() => DateTime.now();
}
