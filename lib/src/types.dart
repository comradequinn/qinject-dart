/// A delegate that accepts a type and, optionally, uses it to return an
/// instance of `TDependency`
typedef Resolver<TDependency> = TDependency Function(Type consumer);

Type typeOf<T>() => T;
