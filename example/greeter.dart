import 'package:qinject/qinject.dart';

import 'datetime_reader.dart';
import 'name_formatter.dart';

class Greeter {
  final DateTimeReader _dateTimeReader;
  final NameFormatter _nameFormatter;
  final String _target;

  Greeter(Qinjector qinjector, this._target)
      : _dateTimeReader = qinjector.use<Greeter, DateTimeReader>(),
        _nameFormatter = qinjector.use<Greeter, NameFormatter>();

  String greet() =>
      "Hello ${_nameFormatter.format(_target)} from Qinject, right now it's ${_dateTimeReader.now()}";
}
