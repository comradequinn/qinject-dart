import 'dart:io';

import 'package:qinject/qinject.dart';

import 'app.dart';
import 'datetime_reader.dart';
import 'greeter.dart';
import 'name_formatter.dart';

main() {
  // Use the Qinject instance to support DI by passing it as a constructor
  // argument to classes defining dependencies
  final qinjector = Qinject.instance();

  // The below is a 'Transient Resolver' registration
  Qinject.register((_) => NameFormatter());

  // The below is 'Factory Resolver' registration
  // Note how it returns a function that creates an instance, not an actual instance
  // directly
  //
  // This is often used for Flutter Widgets but other classes with variable run-time
  // constructors may also use this approach
  //
  // Note how the Qinjector argument is hidden from the consumer by closing
  // around it; this is optional, but recommended for brevity and clarity in the consumer
  Qinject.register((_) => (String target) => Greeter(qinjector, target));

  // The below is a `Type Senstive Resolver` registration
  // Note how it returns a different implementation of DateTimeReader depending on the type
  // of the consumer. Switch these round to see a different greeting
  Qinject.register((Type consumer) => consumer.runtimeType == Greeter
      ? DateTimeReaderNow()
      : DateTimeReaderTomorrow());

  // The below are singleton registrations.
  // Note that regardless of how many times use<T, Stdout|Stdin> is called, the same
  // instance will always be returned
  Qinject.registerSingleton(() => stdout);
  Qinject.registerSingleton(() => stdin);

  App(qinjector).run();
}
