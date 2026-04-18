import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? socket;
  
  // Use http://10.0.2.2:5000 for Android emulator, http://localhost:5000 for web/desktop
  final String _socketUrl = kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000';

  void connect() {
    if (socket != null && socket!.connected) return;

    socket = io.io(_socketUrl, io.OptionBuilder()
      .setTransports(['websocket']) // for Flutter or static platforms
      .enableAutoConnect()
      .build());

    socket!.onConnect((_) {
      debugPrint('Connected to Socket server');
    });

    socket!.onDisconnect((_) {
      debugPrint('Disconnected from Socket server');
    });

    socket!.onConnectError((data) {
      debugPrint('Socket Connection Error: $data');
    });
  }

  void joinRoom(String roomName) {
    if (socket == null || !socket!.connected) connect();
    socket!.emit('join', roomName);
    debugPrint('Joined room: $roomName');
  }

  void leaveRoom(String roomName) {
    socket?.emit('leave', roomName);
    debugPrint('Left room: $roomName');
  }

  void on(String event, Function(dynamic) callback) {
    socket?.on(event, callback);
  }

  void off(String event) {
    socket?.off(event);
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }
}
