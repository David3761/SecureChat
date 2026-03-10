import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  Stream<Map<String, dynamic>>? get incomingMessages =>
      _channel?.stream.map((event) {
        return jsonDecode(event as String) as Map<String, dynamic>;
      }).asBroadcastStream();

  Future<void> connect(String myPublicKey) async {
    //TODO: real server
    final String host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    final String wsUrl = 'ws://$host:8080/ws?pubkey=$myPublicKey';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel!.ready;

      debugPrint('WebSocket Connected: $wsUrl');
    } catch (e) {
      debugPrint('WebSocket Connection Failed: $e');

      throw Exception('Failed to connect: $e');
    }
  }

  void sendMessage({
    required String messageId,
    required String senderPubKey,
    required String recipientPubKey,
    required String encryptedBlob,
  }) {
    if (_channel == null) {
      debugPrint('Cannot send message: WebSocket disconnected.');
      return;
    }

    final payload = {
      'type': 'message',
      'message_id': messageId,
      'sender_pub_key': senderPubKey,
      'recipient_pub_key': recipientPubKey,
      'encrypted_blob': encryptedBlob,
    };

    _channel!.sink.add(jsonEncode(payload));
    debugPrint('Message payload dispatched to server.');
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    debugPrint('WebSocket Disconnected');
  }
}
