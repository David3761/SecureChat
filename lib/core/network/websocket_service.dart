import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socks5_proxy/socks_client.dart';

class WebSocketService {
  WebSocket? _socket;
  StreamController<Map<String, dynamic>>? _streamController;
  Stream<Map<String, dynamic>>? _broadcastStream;
  final List<Map<String, dynamic>> _messageQueue = [];

  Stream<Map<String, dynamic>>? get incomingMessages => _broadcastStream;

  Stream<String>? get ackStream => incomingMessages
      ?.where((msg) => msg['type'] == 'ack')
      .map((msg) => msg['message_id'] as String);

  bool get isConnected =>
      _socket != null && _socket!.readyState == WebSocket.open;

  Future<void> connect(String myPublicKey, {int? torProxyPort}) async {
    final String host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    final String wsUrl = 'ws://$host:8080/ws?pubkey=$myPublicKey';

    try {
      if (torProxyPort != null) {
        _socket = await _connectViaTor(wsUrl, torProxyPort);
      } else {
        _socket = await WebSocket.connect(
          wsUrl,
          headers: {"X-App-Secret": dotenv.env['APP_SECRET'] ?? ''},
        );
      }

      _socket!.pingInterval = const Duration(seconds: 30);
      _setupStream();
      debugPrint('WebSocket Connected: $wsUrl (tor: ${torProxyPort != null})');
    } catch (e) {
      debugPrint('WebSocket Connection Failed: $e');
      throw Exception('Failed to conncet: $e');
    }
  }

  Future<WebSocket> _connectViaTor(String wsUrl, int proxyPort) async {
    final uri = Uri.parse(wsUrl);
    final client = HttpClient();

    SocksTCPClient.assignToHttpClient(client, [
      ProxySettings(InternetAddress.loopbackIPv4, proxyPort, password: null),
    ]);

    final request = await client.openUrl('GET', uri);
    request.headers.set('X-App-Secret', dotenv.env['APP_SECRET'] ?? '');
    request.headers.set('Connection', 'Upgrade');
    request.headers.set('Upgrade', 'websocket');
    request.headers.set('Sec-WebSocket-Version', '13');
    final key = base64Encode(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    );
    request.headers.set('Sec-WebSocket-Key', key);

    final response = await request.close();
    return WebSocket.fromUpgradedSocket(
      await response.detachSocket(),
      serverSide: false,
    );
  }

  void _setupStream() {
    _streamController = StreamController<Map<String, dynamic>>.broadcast(
      onListen: () {
        for (final msg in _messageQueue) {
          _streamController?.add(msg);
        }
        _messageQueue.clear();
      },
    );

    _socket!.listen(
      (event) {
        if (event is String) {
          try {
            final decoded = jsonDecode(event) as Map<String, dynamic>;
            if (_streamController!.hasListener) {
              _streamController?.add(decoded);
            } else {
              _messageQueue.add(decoded);
            }
          } catch (e) {
            debugPrint('Failed to decode message: $e');
          }
        }
      },
      onError: (e) {
        debugPrint('WebSocket error: $e');
        _streamController?.addError(e);
      },
      onDone: () {
        debugPrint('WebSocket Disconnected');
        _streamController?.close();
      },
    );

    _broadcastStream = _streamController!.stream;
  }

  int sendMessage({
    required String messageId,
    required String senderPubKey,
    required String recipientPubKey,
    required String encryptedBlob,
  }) {
    if (_socket == null || _socket!.readyState != WebSocket.open) {
      debugPrint('Cannot send message: WebSocket disconnected.');
      throw Exception('WebSocket is not connected.');
    }

    final payload = jsonEncode({
      'type': 'message',
      'message_id': messageId,
      'sender_pub_key': senderPubKey,
      'recipient_pub_key': recipientPubKey,
      'encrypted_blob': encryptedBlob,
    });

    _socket!.add(payload);
    debugPrint('Message payload dispatched to server.');
    return payload.length;
  }

  void sendGroupMessage({
    required String messageId,
    required String groupId,
    required String senderPubKey,
    required List<Map<String, String>> recipients,
  }) {
    if (_socket == null || _socket!.readyState != WebSocket.open) {
      throw Exception('WebSocket is not connected.');
    }

    final payload = jsonEncode({
      'type': 'group_message',
      'message_id': messageId,
      'group_id': groupId,
      'sender_pub_key': senderPubKey,
      'recipients': recipients,
    });

    _socket!.add(payload);
    debugPrint('Group message payload dispatched to server.');
  }

  void sendDummy(String blob) {
    if (!isConnected) return;
    _socket!.add(jsonEncode({'type': 'dummy', 'blob': blob}));
    debugPrint("Sent dummy.");
  }

  Future<void> disconnectGracefully(String publicKeyHex) async {
    if (_socket == null) return;

    try {
      _socket!.add(
        jsonEncode({'type': 'disconnect', 'sender_pub_key': publicKeyHex}),
      );
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      debugPrint('Failed to send disconnect notice: $e');
    } finally {
      disconnect();
    }
  }

  void disconnect() {
    _socket?.close();
    _socket = null;
    _streamController?.close();
    _streamController = null;
    _broadcastStream = null;
    _messageQueue.clear();
    debugPrint('WebSocket Disconnected');
  }
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.disconnect());
  return service;
});
