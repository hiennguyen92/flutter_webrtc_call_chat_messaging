import 'dart:convert';

import 'package:events_emitter/emitters/stream_event_emitter.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_api.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_socket.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/message.dart';

class AppWebRTC extends StreamEventEmitter {
  late AppAPI _api;
  late AppSocket _socket;


  AppWebRTC() {
    _api = AppAPI(baseUrl: "https://peerjs.upket.com/server/client");
    _socket = AppSocket(
        baseUrl: "wss://peerjs.upket.com:443/server/peerjs?key=client");
    _onSocketEvent();
  }

  void start([String? userId]) {
    const token = "auth-token";
    print("userId: $userId");
    if (userId != null) {
      _socket.start(userId, token);
    } else {
      _api
          .getId()
          .then((value) => _socket.start(value, token))
          .catchError((error) => emit<dynamic>(APIType.Error.type, error));
    }
  }

  void _onSocketEvent() {
    _socket
        .on<Map<String, dynamic>>(SocketEventType.Message.type)
        .listen((event) {
      //Handle Message
      final message = Message.fromMap(event);
      _handleMessage(message);
    });
    _socket.on<String>(SocketEventType.Error.type).listen((event) {
      //Handle Error
      print("SOCKET ERROR");
      emit<String?>(AppEvent.Error.type, "error");
    });
    _socket.on(SocketEventType.Disconnected.type).listen((event) {
      //Handle Disconnected
      print("SOCKET DISCONNECTED");
      emit<String?>(AppEvent.Disconnected.type, "disconnected");
    });
  }

  void _handleMessage(Message message) {
    final type = message.type;
    final payload = message.payload;
    final peerId = message.src;

    switch (type) {
      case MessageType.Open:
        print("OPEN OPEN");
        emit<String?>(AppEvent.Connected.type, "open");
        break;
      case MessageType.Error:
        print("ERROR ERROR");
        break;
      case MessageType.IdTaken:
        print("ID TAKEN ${_socket.getId()}");
        break;
      case MessageType.InvalidKey:
        print("Invalid Key");
        break;
      case MessageType.Leave:
        print("LEAVE $peerId");
        break;
      case MessageType.Expire:
        print("EXPIRE $peerId");
        break;
      case MessageType.Offer:
        print("OFFER $peerId");
        break;
      default:
        print("You received an unrecognized message:$message");
    }
  }


  void disconnect() {
    _socket.disconnect();
  }

  void dispose() {
    emit<String?>(SocketEventType.Disconnected.type, _socket.getId());
    _socket.dispose();
  }

}
