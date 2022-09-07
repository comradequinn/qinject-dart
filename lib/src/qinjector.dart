/// Provides an interface representting access to the [Qinject] Service Locator
///
/// This interface can be used in class constructors where the Dependency Injection
/// approach is favoured over Service Locator.
///
/// Using Dependency Injection with `Qinjector` allows a class to be isolated entirely
/// from its dependencies more readily than using the `Qinject` Service Locator.
///
/// This is especially useful for unit testing purposes where the test can provide a
/// different implementation of [Qinjector] to the class under test rather than the one
/// returned from [Qinject.instance]. Such as the [TestQinjector] class provided in
/// this library for such purposes
abstract class Qinjector {
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
  ///   HostWidget(Qinjector qinjector, {Key? key})
  ///     : _messageWidget = qinjector.use<HostWidget, MessageWidget Function(String)>(),
  ///       super(key: key);
  ///
  ///   @override
  ///   Widget build(BuildContext context) => _messageWidget("Hello World!");
  /// }
  /// ```
  TDependency use<TConsumer, TDependency>();
}
