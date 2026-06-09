import 'dart:convert';

/// The wire format for every tang0 message on a channel.
///
/// One channel multiplexes many logical message [type]s (presence, rpc, a sync
/// var, ...); [sender] carries the originating tab id for self-echo suppression.
/// Encoded compactly as `{"s":sender,"t":type,"d":data}`.
class T0Envelope {
  final String sender;
  final String type;
  final Object? data;

  const T0Envelope({
    required this.sender,
    required this.type,
    required this.data,
  });

  String encode() => jsonEncode({'s': sender, 't': type, 'd': data});

  /// Decode a raw payload, or `null` if it is not a well-formed envelope.
  static T0Envelope? tryDecode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final sender = decoded['s'];
      final type = decoded['t'];
      if (sender is! String || type is! String) return null;
      return T0Envelope(sender: sender, type: type, data: decoded['d']);
    } catch (_) {
      return null;
    }
  }
}
