import 'qinjector.dart';
import 'types.dart';

/// Provides an implementation of `Qinjector` that is intended to support Unit
/// Testing
///
/// A [TestQinjector] is created within a Unit Testing context `Test Doubles` are
/// registered by calling the `registerTestDouble` method.
///
/// Classes that use Dependency Injection with [Qinjector] can then be instantiated
/// with the [TestQinjector] instance instead of that returned from [Qinject.instance]
class TestQinjector implements Qinjector {
  final Map<String, Resolver<dynamic>> _testDoubles = {};

  registerTestDouble<TDependency>(Resolver<TDependency> resolver) {
    _testDoubles[typeOf<TDependency>().toString()] = resolver;
  }

  @override
  TDependency use<TConsumer, TDependency>() {
    final resolver = _testDoubles[typeOf<TDependency>().toString()];

    if (resolver == null) {
      throw ArgumentError(
        "no test double was registered for the requested type '${typeOf<TDependency>().toString()}'",
      );
    }

    return resolver(typeOf<TConsumer>());
  }
}
