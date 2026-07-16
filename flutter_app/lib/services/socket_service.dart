import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

/// Wraps the Socket.IO connection used for real-time messaging, typing
/// indicators, presence (online/offline/last-seen) and call signaling.
/// Mirrors the events defined in backend/src/sockets/index.js.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  IO.Socket? get socket => _socket;

  Future<void> connect() async {
    final token = await ApiService().getToken();
    if (token == null) return;

    _socket = IO.io(
      'https://api.duochat.app',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) => print('[Socket] connected'));
    _socket!.onDisconnect((_) => print('[Socket] disconnected'));
    _socket!.onConnectError((err) => print('[Socket] connect error: $err'));
  }

  void openChat(String chatId) => _socket?.emit('chat:open', chatId);
  void closeChat(String chatId) => _socket?.emit('chat:close', chatId);

  void startTyping(String chatId) => _socket?.emit('typing:start', {'chatId': chatId});
  void stopTyping(String chatId) => _socket?.emit('typing:stop', {'chatId': chatId});

  void sendMessage(Map<String, dynamic> payload, Function(dynamic) ack) {
    _socket?.emitWithAck('message:send', payload, ack: ack);
  }

  void markDelivered(String messageId) => _socket?.emit('message:delivered', {'messageId': messageId});
  void markRead(String messageId, String chatId) => _socket?.emit('message:read', {'messageId': messageId, 'chatId': chatId});

  // ---- Calling (WebRTC signaling relay) ----
  void callInvite(String toUserId, String chatId, String callType, dynamic offer) =>
      _socket?.emit('call:invite', {'toUserId': toUserId, 'chatId': chatId, 'callType': callType, 'offer': offer});
  void callAnswer(String toUserId, dynamic answer) => _socket?.emit('call:answer', {'toUserId': toUserId, 'answer': answer});
  void callIceCandidate(String toUserId, dynamic candidate) =>
      _socket?.emit('call:ice-candidate', {'toUserId': toUserId, 'candidate': candidate});
  void callDecline(String toUserId) => _socket?.emit('call:decline', {'toUserId': toUserId});
  void callEnd(String toUserId) => _socket?.emit('call:end', {'toUserId': toUserId});

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
