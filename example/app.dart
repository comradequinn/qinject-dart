import 'dart:io';

import 'package:qinject/qinject.dart';

import 'greeter.dart';

class App {
  // Below the service locator style of resolution is used. This may be
  // preferable for some trivial dependencies even when DI is being used elsewhere
  final Stdout _stdout = Qinject.use<void, Stdout>();
  final Stdin _stdin = Qinject.use<void, Stdin>();

  // Here the DI style of dependency resolution is used. This is typically
  // more flexible when writing unit tests. In this case, the dependency is
  // a factory function, allowing the consumer to create multiple instances of
  // the dependency itself
  final Greeter Function(String) _greeter;

  App(Qinjector qinjector)
      : _greeter = qinjector.use<App, Greeter Function(String)>();

  void run() {
    while (true) {
      _stdout.writeln("Enter a name, CTRL+C to quit: ");

      var input = _stdin.readLineSync();

      if (input != null) {
        var greeter = _greeter(input);
        _stdout.writeln(greeter.greet());
      }
    }
  }
}
