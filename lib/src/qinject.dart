import 'default_qinjector.dart';
import 'qinjector.dart';
import 'types.dart';

/// Qinject is a fast, flexible IoC (Inversion of Control) library that
/// supports both Service Locator and DI (Dependency Injection)
class Qinject {
  static final Map<String, Resolver<dynamic>> _dependencyRegister = {};
  static T _annotateErrorsFor<T>(T Function() f, String action) {
    try {
      return f();
    } catch (e) {
      throw StateError(
        "error while $action : ${e.toString()}",
      );
    }
  }

  /// Writes logs to the console by default
  /// Override this behavior by setting log to a custom Function(String)
  /// implementation
  static var log = (String message) => print("qinject $message");

  /// Registers `onInit` as the delegate that provides the single instance
  /// of `TDependency` which will be returned from all invocations of
  /// `use<TConsumer, TDependency>`
  ///
  /// Dependencies can be registered in any order, regardless of whether they
  /// depend on each other. This due to the registrations being defined as delegates.
  /// These are not evaluated until `use<TConsumer, TDependency>` is invoked.
  ///
  /// The below example registers an instance of the `DateTimeReader` class as the
  /// single instance returned from all calls to `use<TConsumer, DateTimeReader>`
  ///
  /// ```
  /// Qinject.registerSingleton(() => DateTimeReader();
  ///
  /// class DateTimeReader {
  ///   DateTime now() => DateTime.now();
  /// }
  /// ```
  static registerSingleton<TDependency>(TDependency Function() onInit) {
    TDependency? singleton;
    final dependencyType = typeOf<TDependency>().toString();

    _register<TDependency>((Type _) {
      var s = (singleton ??= _annotateErrorsFor<TDependency>(
          onInit, "invoking singleton init for $dependencyType"));

      log("returned singleton instance of $dependencyType");

      return s;
    });
  }

  /// Registers `resolver` as the delegate that provides all instances
  /// of `TDependency` that will be returned from any invocations of
  /// `use<TConsumer, TDependency>`
  ///
  /// Typically the [Resolver] specified will be a delegate that directly
  /// returns the instance of the `TDependency` required.
  ///
  /// However, dependencies that require `TConsumer`-controlled deferred or
  /// repeated execution, or expose contextual constructor arguments, should use
  /// a `Factory Delegate`.
  ///
  /// A `Factory Delegate` is a function that is invoked by the `TConsumer` itself
  /// to create the `TDependency` instance. Flutter widgets, for example, will
  /// typically be registered with a `Factory Delegate`.
  ///
  /// The [Resolver] delegate accepts a `TConsumer` argument which is set by
  /// the caller, typically to its own type. This is normally ignored, however
  /// it can be useful should the delegate be required to return different `TDependency`
  /// implementations for different `TConsumer`s.
  ///
  /// Dependencies can be registered in any order, regardless of whether they
  /// depend on each other. This due to the registrations being defined as delegates.
  /// These are not evaluated until `use<TConsumer, TDependency>` is invoked.
  ///
  /// The below example registers a [Resolver] for an imaginary `EventTimer` class
  /// which returns a new instance of `EventTimer` for every call to `use<TConsumer, EventTimer>`
  ///
  /// ```
  /// Qinject.register((_) => EventTimer());
  /// ```
  ///
  /// *Note that while the `Qinject.register` signature is `Qinject.register<TConsumer, TDependency>`
  /// the type arguments can be omitted due to Dart's type inference. They need only be specified
  /// explicitly if a type that is derived from the actual type being registered is being returned. Though, in
  /// such a case, casting the returned type in the function to the registered type may be preferable
  /// to specifying type arguments in terms of readability.*
  ///
  /// This next example registers a `Factory Delegate` for the `HelloWorldWidget` flutter widget
  /// constructor. It will be returned by calls to `use<TConsumer, HelloWorldWidget Function()>` and
  /// would then be invoked by the caller whenever it was required to render a HelloWorldWidget.
  ///
  /// ```
  /// Qinject.register((_) => () => HelloWorldWidget());
  ///
  /// class HelloWorldWidget extends StatelessWidget {
  ///   const HelloWorldWidget({Key? key}) : super(key: key);
  ///
  ///   @override
  ///   Widget build(BuildContext context) => const Text("Hello world!");
  /// }
  /// ```
  ///
  /// A further example registers a `Factory Delegate` for the `MessageWidget` flutter widget
  /// constructor. Note that  This `MessageWidget` has a constructor argument, and this is reflected in
  /// the `Factory Delegate` provided in the registration
  ///
  /// ```
  /// Qinject.register((_) => (String m) => MessageWidget(m));
  ///
  /// class MessageWidget extends StatelessWidget {
  ///   final String _message;
  ///
  ///   const MessageWidget(this._message, {Key? key}) : super(key: key);
  ///
  ///   @override
  ///   Widget build(BuildContext context) => Text(_message);
  /// }
  /// ```
  ///
  static register<TDependency>(Resolver<TDependency> resolver) {
    final dependencyType = typeOf<TDependency>().toString();

    _register<TDependency>((Type consumer) {
      log("returned instance of $dependencyType");

      return _annotateErrorsFor(
          () => resolver(consumer), "invoking resolver for $dependencyType");
    });
  }

  static _register<TDependency>(Resolver<TDependency> resolver) {
    var dependencyType = typeOf<TDependency>().toString();

    log("registered resolver for $dependencyType");

    _dependencyRegister[dependencyType] = resolver;
  }

  /// Returns the `TDependency` configured for `TConsumer`
  ///
  /// The value of `TConsumer` is typically the type of the caller
  /// class. However this can be any type that assists with describing
  /// the consumer to the configured [Resolver]. To skip passing types, pass
  /// `void`. For example  `var _eventTimer = use<void, EventTimer>()`
  ///
  /// The value of `TDependency` should match the registration type for the
  /// `TDependency` required. For example, where a Flutter widget,
  /// `MessageWidget` is registered with a `Factory Delegate`, such
  ///  as `Qinject.register((_) => (String m) => MessageWidget(m));` then to
  /// resolve the dependency, the caller should specify the type of the
  /// `Factory Delegate`. For example:
  ///
  /// ```
  /// class HostWidget extends StatelessWidget {
  ///   final MessageWidget Function(String) _messageWidget;
  ///
  ///   HostWidget({Key? key})
  ///     : _messageWidget = Qinject.use<HostWidget, MessageWidget Function(String)>(),
  ///       super(key: key);
  ///
  ///   @override
  ///   Widget build(BuildContext context) => _messageWidget("Hello World!");
  /// }
  /// ```
  static TDependency use<TConsumer, TDependency>() {
    final resolver = _dependencyRegister[typeOf<TDependency>().toString()];

    if (resolver == null) {
      throw ArgumentError(
        "the requested type '${typeOf<TDependency>().toString()}' was not registered",
      );
    }

    return resolver(typeOf<TConsumer>());
  }

  /// Provides an interface representting access to the [Qinject] Service Locator
  ///
  /// This interface can be used in class constructors where the Dependency Injection
  /// approach is favoured over Service Locator.
  ///
  /// Using Dependency Injection with `Qinjector` allows a class to be isolated entirely
  /// from its dependencies more readily than using the `Qinject` Service Locator.
  ///
  /// This is especially useful for unit testing purposes where the test can provide a
  /// different implementation of `Qinjector` to the class under test than the one
  /// returned from this method
  ///
  /// The below example shows a dependency being acquired using Dependency Injection
  /// with `Qinjector`:
  ///
  /// ```
  /// class HostWidget extends StatelessWidget {
  ///   final MessageWidget Function(String) _messageWidget;
  ///
  ///   HostWidget(Qinjector qinjector, {Key? key})
  ///     : _messageWidget = qinjector.use<HostWidget, MessageWidget Function(String)>(),
  ///       super(key: key);
  ///
  ///   @override
  ///   Widget build(BuildContext context) => _messageWidget("Hello World!");
  /// }
  static Qinjector instance() {
    return DefaultQinjector();
  }

  /// Removes all dependency registrations
  static void reset() {
    _dependencyRegister.clear();
  }
}
