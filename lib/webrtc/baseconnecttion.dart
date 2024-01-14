

import 'package:events_emitter/emitters/stream_event_emitter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_webrtc.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/message.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/options.dart';

abstract class  BaseConnection extends StreamEventEmitter {

  BaseConnection(this.peer, this.provider, this.options);

  bool open = false;
  late String connectionId;
  RTCPeerConnection? peerConnection;
  dynamic metadata;
  late AppWebRTC? provider;
  late String peer;
  late PeerConnectOption? options;
  late ConnectionType type;

  void dispose();
  void handleMessage(Message message);

  void closeRequest() {
    emit("close", null);
  }

}