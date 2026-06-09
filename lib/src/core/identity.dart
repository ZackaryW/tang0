import 'package:uuid/uuid.dart';

import '../platform/platform.dart';

/// Stable identity for the current browser tab.
///
/// The id is generated once and stored in sessionStorage, so it survives a page
/// reload within the same tab but is distinct from every other tab (each tab has
/// its own sessionStorage). Used for self-echo suppression and presence keys.
class T0Identity {
  final String tabId;

  const T0Identity._(this.tabId);

  factory T0Identity(T0Platform platform, {String key = 'tang0.tabId'}) {
    final existing = platform.session.read(key);
    if (existing != null && existing.isNotEmpty) return T0Identity._(existing);
    final id = const Uuid().v4();
    platform.session.write(key, id);
    return T0Identity._(id);
  }
}
