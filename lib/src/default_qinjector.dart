import 'qinject.dart';
import 'qinjector.dart';

class DefaultQinjector implements Qinjector {
  @override
  TDependency use<TConsumer, TDependency>() {
    return Qinject.use<TConsumer, TDependency>();
  }
}
