/// A last-write-wins register: the conflict-resolution core shared by synced
/// values. Pure logic, no transport — given two writes it deterministically
/// picks a winner so every tab converges on the same value.
///
/// Ordering is `(version, timestamp, origin)`: a higher version wins; ties break
/// on the newer timestamp; remaining ties break on the larger origin id. The
/// origin tiebreak guarantees total order even when two tabs write the same
/// version at the same millisecond — without it tabs could diverge.
class T0LwwRegister<T> {
  T _value;
  int _version;
  int _ts;
  String _origin;

  T0LwwRegister(
    this._value, {
    int version = 0,
    int ts = 0,
    String origin = '',
  })  : _version = version,
        _ts = ts,
        _origin = origin;

  T get value => _value;
  int get version => _version;
  int get ts => _ts;
  String get origin => _origin;

  /// Apply a local write: bumps the version, stamps [ts]/[origin]. Always wins
  /// over the current value (it is strictly newer).
  void localSet(T newValue, {required int ts, required String origin}) {
    _value = newValue;
    _version += 1;
    _ts = ts;
    _origin = origin;
  }

  /// Merge a write observed from another tab. Returns whether it was applied
  /// (i.e. it dominated the current value).
  bool merge(T value, {required int version, required int ts, required String origin}) {
    if (!_dominates(version, ts, origin)) return false;
    _value = value;
    _version = version;
    _ts = ts;
    _origin = origin;
    return true;
  }

  bool _dominates(int version, int ts, String origin) {
    if (version != _version) return version > _version;
    if (ts != _ts) return ts > _ts;
    return origin.compareTo(_origin) > 0;
  }
}
