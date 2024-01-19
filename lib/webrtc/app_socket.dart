// ignore_for_file: empty_catches

import 'dart:convert';
import 'package:events_emitter/emitters/stream_event_emitter.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/events.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AppSocket extends StreamEventEmitter {
  bool _connected = false;
  late String? _id;
  late List<Map<String, dynamic>> _messagesQueue = [];
  late WebSocketChannel? _socket;

  late String _baseUrl;

  AppSocket({baseUrl}) {
    _baseUrl = baseUrl;
  }

  void start(String id, String token) {
    _id = id;
    print("MY ID: $_id");
    final wsUrl = "$_baseUrl&id=$id&token=$token&version=1";

    if (_connected) {
      return;
    }

    _socket = WebSocketChannel.connect(Uri.parse(wsUrl));
    _connected = true;

    _socket?.stream.listen((event) {
      dynamic data;
      try {
        data = jsonDecode(event);
        print("Received message: $data");
      } catch (error) {
        print("Invalid message: $event");
      }
      emit<Map<String, dynamic>>(SocketEvent.Message.type, data);
    }, onDone: () {
      print("Socket closed.");
      _connected = false;
      try {
        emit<String?>(SocketEvent.Disconnected.type, _id);
      } catch (error) {
      } finally {}
    }, onError: (error) {
      _connected = false;
      print("Socket error: $error");
      try {
        emit<String>(SocketEvent.Error.type, "Invalid socket");
      } catch (error) {
      } finally {}
    });

    _scheduleMessages();

    print("Socket open");

    _scheduleHeartbeat();
  }

  void _scheduleHeartbeat() {
    Future.delayed(const Duration(milliseconds: 5000), () => _sendHeartbeat());
  }

  void _sendHeartbeat() {
    if (!_connected) {
      print("Cannot send heartbeat. Socket closed");
      return;
    }
    final message = jsonEncode({"type": MessageType.Heartbeat.type});
    //print("Send heartbeat.");
    _socket?.sink.add(message);

    _scheduleHeartbeat();
  }

  bool isConnected() {
    return _connected;
  }

  String? getId() {
    return _id;
  }

  void disconnect() {
    _connected = false;
    _socket?.sink.close();
  }

  void dispose() {
    disconnect();
    close();
  }

  void send(Map<String, dynamic> data) {
    if (!_connected) {
      print("Socket disconnected!");
      return;
    }

    if (_id == null) {
      _messagesQueue.add(data);
      return;
    }

    if (data["type"] == null) {
      emit<String>(SocketEvent.Error.type, "Invalid message, missing type");
      return;
    }

    final message = jsonEncode(data);
    _socket?.sink.add(message);
  }

  void _scheduleMessages() {
    final copiedQueue = [..._messagesQueue];
    _messagesQueue = [];

    for (var message in copiedQueue) {
      send(message);
    }
  }
}
