# Qinject
A fast, flexible, IoC library for Dart and Flutter

Qinject helps you easily develop applications using `DI` (Dependency Injection) and `Service Locator` based approaches to `IoC` (Inversion of Control), or often a mix of the two.

[![Makefile CI](https://github.com/comradequinn/qinject-dart/actions/workflows/makefile.yml/badge.svg)](https://github.com/comradequinn/qinject-dart/actions/workflows/makefile.yml)

## Key Features
* Support for `DI` (Dependency Injection)
* Support for `Service Locator` 
* Implicit dependency chain resolution; no need to define and maintain `depends on` relationships between registered dependencies
* Simple, yet extremely flexible dependency registration and resolution mechanics
* Register any type as a dependency, from `Flutter` Widgets and functions to simple classes
* Simple, but powerful, unit testing tooling

## Quick Start
The following example shows a basic application making use of both `DI` and `Service Locator` patterns alongside `Singleton` and `Resolver` dependency registration. These topics are covered in more detail later in this document.

*Note:* A fully featured demonstration application is provided in the [./example](./example) directory. This can be run by executing `make example` from the repo root.

```dart
main() {
  // Use the Qinject instance to support DI by passing it as a constructor
  // argument to classes defining dependencies
  final qinjector = Qinject.instance();

  Qinject.registerSingleton(() => stdout);
  Qinject.register((_) =>
      DateTimeReader()); // Note the type argument is ignored as the resolver does not use it and the type arguments required by `register` are omitted due to dart's type inference
  Qinject.register((_) => Greeter(qinjector));

  Qinject.use<void, Greeter>().greet(); // Resolve a Greeter instance and invoke its greet method
}

class Greeter {
  // Below the service locator style of resolution is used. This may be
  // preferable for some trivial dependencies even when DI is being used elsewhere
  final Stdout _stdout = Qinject.use<Greeter, Stdout>();

  // Here the DI style of dependency resolution is used. This is typically
  // more flexible when writing unit tests
  final DateTimeReader _dateTimeReader;

  Greeter(Qinjector qinjector)
      : _dateTimeReader = qinjector.use<Greeter, DateTimeReader>();

  void greet() => _stdout.writeln("Right now it's ${_dateTimeReader.now()}");
}

class DateTimeReader {
  DateTime now() => DateTime.now();
}

```

## Dependency Registration
There are two high level types of dependency; `Singleton` and `Resolver`. `Resolver`s are covered in detail in the dedicated [Resolvers](#resolvers) section. A `Singleton` is evaluated once, the first time it is resolved, and then the same instance is returned for the lifetime of the application.

## Dependency Usage
All dependencies of any type are resolved with the same method: `use<TConsumer, TDependency>`. This may be invoked off the `Qinject` Service Locator or an via instance of `Qinjector` injected into a class. Both approaches can be used interchangeably as any dependencies registered are accesible via either route.

### Using Service Locator
The `Service Locator` is a simple pattern for decoupling dependencies. Its usage is predicated on a globally accessible `Service Locator` instance; in the case of `Qinject` this is the `Qinject` type itself which exposes a static `use<TConsumer, TDependency>` method. 

Dependencies can be resolved in below manner from anywhere that can access the `Qinject` type:

```dart
    final DependencyType _dependency = Qinject.use<ConsumerType, DependencyType>();
```

Some complex applications may become difficult to test when `Service Locator` is used to decouple dependencies. Especially where concurrently executing logic is concerned. This is due to the single global instance, which needs configuring with test doubles appropriate for all tests in a given test run, or at least repeatedly configured and cleared down. For such applications, `DI` may be a better choice, with `Service Locator` either not used, or reserved for trivial dependencies, such as `stdout` as shown in the [Quick Start](#quick-start) example

For many applications however, `Service Locator` is a time-served, simple and effective choice.

### Using DI (Dependency Injection)
Adopting `DI` sees classes declare their dependencies as variables, typically of some abstract type, and expose setters to these variables in their constructors (typically). These variables are then set by an external entity which is responsible for choosing, creating and managing the lifetime of the concrete implementations of those abstract dependency types. 

Done naively, this quickly becomes a very complex dependency graph to manage, so the majority of projects that adopt this approach use an IoC Library or Framework to manage this complexity. This is what `Qinject` offers for `Dart` and `Flutter` projects.

`Qinject` takes a slightly different appoach to this than comparable frameworks in other languages, however, by injecting an abstract `Service Locator` instance into the constructor. This is then immediately used by the constructor to acquire any dependencies.

An example is shown below illustrating how dependencies are declared in the constructor and populated by the injected `Qinjector` instance. 

```dart
main() {
    // Access the Qinjector instance
    final qinjector = Qinject.instance();

    Qinject.register((_) => ConsumerClass(qinjector)); // Note the ConsumerClass can be registered before its dependencies
    Qinject.register((_) => DependencyA(qinjector)); // Note that DependencyA requires a Qinjector also. We hide this from ConsumerClass by providing it in the Resolver closure; this is purely for brevity and clarity however
    Qinject.register((_) => DependencyB());
    Qinject.register((_) => DependencyC(qinjector));
    
    final consumerClass = Qinject.use<void, ConsumerClass>(); // Resolve an instance of ConsumerClass

    // do something with consumerClass
}


class ConsumerClass {
  final DependencyA _dependencyA;
  final DependencyB _dependencyB;
  final DependencyC _dependencyC;

  ConsumerClass(Qinjector qinjector)
      : _dependencyA = qinjector.use<ConsumerClass, DependencyA>(),
        _dependencyB = qinjector.use<ConsumerClass, DependencyB>(),
        _dependencyC = qinjector.use<ConsumerClass, DependencyC>();

  // Do something with dependencies
}
```
Complex applications can be easier to test when `DI` is used to decouple dependencies. In `Qinject` this is due to the interface representing the mechanism of dependency resolution that is passed into each consuming class. In testing scenarios, this can be replaced with a different implementation of [Qinjector](#unit-testing-with-qinjector) created specifically for the test and scoped to it, and it alone. This prevents the config for one test leaking into an other and brittle dependencies forming around the ordering of test execution. These are subtle benefits, but on larger projects they often dividends.

## Unit Testing with Qinjector
A `TestQinjector` instance can be used to register `Test Doubles` for dependencies to assist in Unit Testing. The `TestQinjector` instance can then be passed to dependency consumers instead of the default `Qinjector` instance returned from `Qinject.instance()`.

For example, if testing the sample Qinjector application [above](#using-di-dependency-injection), the following may be defined

```dart
main() {
    test('ConsumerClass behaves as expected', () {
        // Create a TestQinjector instance that implements the Qinjector interface
        final qinjector = TestQinjector();

        // Register stubs or mocks as required against the TestQinjector instance
        qinjector.registerTestDouble<DependencyA>((_) => DependencyAStub()); // Note the TDependency type argument is set explictly here to DependencyA otherwise Dart's type inference would cause the registration to be assigned to the type DependencyAStub and then dependency resolution would fail in ConsumerClass
        qinjector.registerTestDouble<DependencyB>((_) => DependencyBMock()); 
        qinjector.registerTestDouble<DependencyC>((_) => DependencyCStub());
        
        final consumerClass = ConsumerClass(qinjector); // Create instance of ConsumerClass using the TestQInjector

        // do some assertions against consumerClass
    }
}
```

## Resolvers
Dependencies are registered by assigning a `Resolver` delegate to a dependency type, labelled as `TDependency`. A `Resolver` delegate is any function that accepts a single `Type` argument and returns an instance of `TDependency`. 

This takes the form: 

```dart
    Qinject.register<TDependency>(TDependency Function (Type consumer));
```

The type of `TDependency` can be any `Type` recognised by the type system; not just a class. For example, functions are often registered as [Factory Resolvers](#factory-resolvers)

The `Resolver` delegate is not invoked at the point of registration. As such, any dependencies that the `TDependency` requires need not yet be registered within `Qinject`. The only requirement for successful resolution is that the full dependency graph of a given `TDependency` is registered, in any order, before `use<TConsumer, TDependency>()` is called for that particular `TDependency`.

The `Type` argument can often be ignored during the dependency resolution process; it is available purely to allow different implementations of the same interface to be returned to different consumers, should that be required. The argument passed to `Type` is the type that was passed as `TConsumer` in the call to `use<TConsumer, TDependency>` that caused the `Resolver` delegate to be invoked. This is typically set to the `Type` of the consumer itself, however it can be any `type`. 

In cases where there is no meaningful enclosing `Type`, or it is not relevant, `void` may be passed. 

It is important to remember that there is only one fundamental type of `Resolver`; and that is any function that meets the `Resolver` signature. This means your dependency resolution process and lifetime management can be as simple or as complex as your needs require. However, some common forms of `Resolver` are described in the following sections:

### Transient Resolvers
A `Transient Resolver` is the simplest form of `Resolver`. It looks like the below

```dart
    Qinject.register((_) => MyClass()); // note the Type argument is ignored with _ as it is not used in this example (though it could be required if the resolution process)
```

Whenever `use<MyClass>()` is invoked, a new instance of `MyClass` is returned.

### Type Sensitive Resolvers
A `Type Sensitive Resolver` returns a different implementation of an interface depending on the type passed as the `consumer` argument.

```dart
      Qinject.register((Type consumer) => consumer.runtimeType == TypeA
      ? ImplementationA()
      : ImplementationB());
```

Whenever `use<TConsumer, TypeA>()` is invoked, a new instance of `ImplementationA` is returned. When `use<TConsumer, NotTypeA>()` is invoked where the `NotTypeA` is, as the name suggests, anything other than `TypeA`, then a new instance of `ImplementationB` is returned. 

Note that both `ImplementationA` and `ImplementationB` must implement the same interface.

### Factory Resolvers
A `Factory Resolver` returns a factory function rather than a dependency instance. This is commonly used for classes with runtime-variable constructor arguments, such as `Flutter Widgets`.

```dart
    Qinject.register((_) => (String variableArg) => MyClass(variableArg));
```

Whenever `use<TConsumer, MyClass Function(String)>()` is invoked, a function is returned that accepts a `String` argument and returns an instance of `MyClass`. This function would typically be assigned to a variable in the consumer and repeatedly invoked with different arguments; in the manner a `Flutter Widget` constructor may be invoked many times within a parent `Widget`. 

For example:

```dart

Qinject.register((_) => (String msg) => MessageWidget(msg)); // Register the MessageWidget Factory Resolver

class ConsumerWidget extends StatelessWidget {
  final MessageWidget Function(String) _messageWidget; // The ConsumerWidget has a dependency on the MessageWidget expressed as a Factory Function

  ConsumerWidget(Qinjector qinjector, {Key? key})
      : _messageWidget =
            // Resolve the MessageWidget dependency using Qinjector
            qinjector.use<ConsumerWidget, MessageWidget Function(String)>(), // 
        super(key: key);

  @override
  Widget build(BuildContext context) => {
     // Use the _messageWidget factory function as many times as required, in place of the MessageWidget constructor
     _messageWidget("Hello you!"); 
     _messageWidget("Hello World!");
     _messageWidget("Hello Universe!");
}

class MessageWidget extends StatelessWidget {
  final String _message;

  const MessageWidget(this._message, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Text(_message);
}

```

### Cached Resolvers
A `Cached Resolver` returns the same instance of `TDependency` for a defined period, before refreshing it and using the new instance for the next defined period, ad infinitum. This form of `Resolver` is a good example of the simple, flexible nature of `Qinject`'s approach to dependency resolution.

```dart

  // In registration section of app
  var cachedDataTimeStamp = DateTime.now();
  var cachedData = populateCachedData();

  Qinject.register((_) {
    if (DateTime.now().difference(cachedDataTimeStamp).inSeconds > 60) {
      var cachedDataTimeStamp = DateTime.now();
      var cachedData = populateCachedData();
    }

    return cachedData;
  });

  // Elsewhere in main app codebase
  CachedData populateCachedData() {
    // omitted for brevity; maybe fetched from a network service or local db
    CachedData();
  }

  class CachedData {
    // omitted for brevity; would house various data attributes
  }
```


## Logging & Diagnostics
By default, `Qinject` logs records of potentially relevant activity to `stdout`. In some cases, this may need to be overridden to redirect logs or to apply some form of pre-processing to them. 

This can be achieved by setting the `Quinject.log` field to a custom logging delegate.

The below example routes logs to Flutter's `debugPrint`

```dart
  Qinject.log = (message) => debugPrint(message);
```

## Contributions
Pull requests are welcome, particularly for any bug fixes or efficiency improvements. 

API changes will be considered, however, while there are a number of shorthand or helper methods that can readily be imagined, the aim is to keep `Qinject` light, simple, and flexible. As such, changes of that manner may be rejected, but not with any negative judgement associated with the contribution
