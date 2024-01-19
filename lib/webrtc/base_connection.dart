

import 'package:events_emitter/emitters/stream_event_emitter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_webrtc.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/message.dart';

abstract class  BaseConnection extends StreamEventEmitter {

  BaseConnection(this.peer, this.provider, this.payload);

  bool open = false;
  late String connectionId;
  RTCPeerConnection? peerConnection;
  dynamic metadata;
  late AppWebRTC? provider;
  late String peer;
  late ConnectionType type;

  late dynamic payload;


  void dispose();

  void makeOffer();
  void handleOffer(Message message);
  void handleAnswer(Message message);
  void handleCandidate(Message message);

  void closeRequest() {
    emit("close", null);
  }

}