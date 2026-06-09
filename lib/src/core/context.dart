import '../platform/platform.dart';
import '../platform/web_platform.dart';
import 'dispatch_pool.dart';
import 'identity.dart';

/// The tang0 runtime: a platform + this tab's identity + a shared dispatch pool.
///
/// Almost every tang0 component takes a [Tang0] (defaulting to [Tang0.instance],
/// which is bound to the real browser). Tests pass a context built on a fake
/// platform. One [Tang0] per platform; share it across components in a tab.
class Tang0 {
  final T0Platform platform;
  final T0Identity identity;
  final T0DispatchPool pool;

  Tang0(this.platform)
      : identity = T0Identity(platform),
        pool = T0DispatchPool(platform.channels);

  static Tang0? _instance;

  /// The default browser-bound runtime (lazily created).
  static Tang0 get instance => _instance ??= Tang0(webPlatform());

  /// Override the default runtime (e.g. in tests). Pass `null` to reset.
  static void overrideInstance(Tang0? value) => _instance = value;

  String get tabId => identity.tabId;
}
