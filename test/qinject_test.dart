import 'package:qinject/qinject.dart';
import 'package:test/test.dart';

class Svc1RequiresSvc2 {
  final svc2 = Qinject.use<Svc1RequiresSvc2, Svc2RequiresSvc3>();
}

class Svc2RequiresSvc3 {
  final svc3 = Qinject.use<Svc2RequiresSvc3, Svc3>();
}

class Svc3 {
  var value = 0;
}

class Svc4RequiresQinjector {
  // ignore: unused_field
  final Qinjector _qinjector;

  Svc4RequiresQinjector(this._qinjector);
}

void main() {
  final qinjector = Qinject.instance();

  group("dependency resolution", () {
    test('dependency with no chain is resolved', () {
      Qinject.reset();
      Qinject.register((_) => Svc3());

      expect(Qinject.use<void, Svc3>().runtimeType, Svc3);
      expect(qinjector.use<void, Svc3>().runtimeType, Svc3);
    });

    test(
        'dependency with chain is resolved with sympathetically ordered registration',
        () {
      Qinject.reset();
      Qinject.register((_) => Svc3());
      Qinject.register((_) => Svc2RequiresSvc3());
      Qinject.register((_) => Svc1RequiresSvc2());

      expect(
          Qinject.use<void, Svc2RequiresSvc3>().runtimeType, Svc2RequiresSvc3);
      expect(qinjector.use<void, Svc2RequiresSvc3>().runtimeType,
          Svc2RequiresSvc3);
      expect(
          Qinject.use<void, Svc1RequiresSvc2>().runtimeType, Svc1RequiresSvc2);
      expect(qinjector.use<void, Svc1RequiresSvc2>().runtimeType,
          Svc1RequiresSvc2);
    });

    test(
        'dependency with chain is resolved with unsympathetically ordered registration',
        () {
      Qinject.reset();
      Qinject.register((_) => Svc1RequiresSvc2());
      Qinject.register((_) => Svc2RequiresSvc3());
      Qinject.register((_) => Svc3());

      expect(
          Qinject.use<void, Svc1RequiresSvc2>().runtimeType, Svc1RequiresSvc2);
      expect(qinjector.use<void, Svc1RequiresSvc2>().runtimeType,
          Svc1RequiresSvc2);
      expect(
          Qinject.use<void, Svc2RequiresSvc3>().runtimeType, Svc2RequiresSvc3);
      expect(qinjector.use<void, Svc2RequiresSvc3>().runtimeType,
          Svc2RequiresSvc3);
    });

    test(
        'dependency chain is not resolved when a required dependency is not registered',
        () {
      Qinject.reset();

      expect(() => Qinject.use<void, Svc3>(), throwsArgumentError);
      expect(() => qinjector.use<void, Svc3>(), throwsArgumentError);
    });
  });

  group("singleton dependency resolution", () {
    test(
        'dependency chain is resolved with same instance when it is registered as a singleton',
        () {
      Qinject.reset();

      var svc3 = Svc3();
      svc3.value = 1;

      Qinject.registerSingleton(() => svc3);

      expect(Qinject.use<void, Svc3>().value, 1);
      expect(qinjector.use<void, Svc3>().value, 1);

      svc3 =
          Svc3(); // set svc3 reference to a new instance with default value set at 0

      expect(Qinject.use<void, Svc3>().value,
          1); // ensure our singleton dependency does not reflect the change
      expect(qinjector.use<void, Svc3>().value, 1);
    });
  });

  group("async dependency resolution", () {
    test('async dependency is resolved based on configured resolver', () async {
      Qinject.reset();

      Qinject.register((_) async {
        await Future.delayed(Duration(milliseconds: 100));
        return Svc3();
      });

      expect((await Qinject.use<void, Future<Svc3>>()).runtimeType, Svc3);
    });
  });

  group("testqinjector dependency resolution", () {
    test('test-double is resolved based on configured resolver', () {
      final testQinjector = TestQinjector();

      testQinjector.registerTestDouble((_) => Svc3());

      expect(testQinjector.use<void, Svc3>().runtimeType, Svc3);
    });

    test('test-double errors when no resolver configured', () {
      final testQinjector = TestQinjector();
      expect(() => testQinjector.use<void, Svc3>(), throwsArgumentError);
    });

    test('testQinjector satisfies Qinjector interface', () {
      Svc4RequiresQinjector(
          TestQinjector()); // this won't compile if the interface is no longer satisfied
    });
  });
}
