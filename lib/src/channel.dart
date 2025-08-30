import 'dart:convert';
import 'dart:js_interop';
import 'package:tang0/src/top0.dart';
import 'package:web/web.dart' as web;

abstract class Tang0Receive {
  final bool isJson;

  Tang0Receive({this.isJson = true});

  void receive(dynamic data, web.MessageEvent event);

  dynamic prehandle(String data) {
    if (isJson) {
      return jsonDecode(data);
    }
    return data;
  }

  void handle(String data, web.MessageEvent event) {
    final parsed = prehandle(data);
    // Handle the parsed data
    receive(parsed, event);
  }
}

class Tang0Channel {
  final String name;
  final Map<String, Tang0Receive> _receivers = {};
  late final web.BroadcastChannel _channel;

  Tang0Channel({this.name = "untitled"}) {
    _channel = web.BroadcastChannel("tang0_$name");
    _channel.addEventListener("message", _handleMessage.toJS);
  }

  void registerReceiver(String command, Tang0Receive receiver) {
    _receivers[command] = receiver;
  }

  void _handleMessage(web.MessageEvent event) {
    // Use proper JS interop conversion with type safety
    final jsData = event.data;
    if (jsData == null) return;

    // Convert JSAny? to String safely with fallback
    String data;
    try {
      if (jsData.typeofEquals('string')) {
        data = (jsData as JSString).toDart;
      } else {
        // Handle case where data might be sent as different type
        data = jsData.toString();
      }
    } catch (e) {
      // If conversion fails completely, ignore the message
      return;
    }

    final matched = matchCommand(data, _receivers.keys.toList());
    if (matched == null) {
      return;
    }

    // Extract data and forward to appropriate receiver
    final extractedData = verifyData(data);
    if (extractedData != null) {
      final receiver = _receivers[matched];
      if (receiver != null) {
        receiver.handle(extractedData, event);
      }
    }
  }

  void send(String command, dynamic data, {bool isJson = true}) {
    // if is json, convert to string
    final message = isJson ? jsonEncode(data) : data.toString();
    final payload = sign(command, message);
    _channel.postMessage(payload.toJS);
  }
}
