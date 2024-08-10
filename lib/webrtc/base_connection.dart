

import 'dart:math';

import 'package:events_emitter/emitters/stream_event_emitter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_webrtc.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/message.dart';

const DEFAULT_CONFIG = {
  "iceServers": [
    {"urls": "stun:stun.l.google.com:19302"},
    {
      "urls": [
        "turn:eu-0.turn.peerjs.com:3478",
        "turn:us-0.turn.peerjs.com:3478",
      ],
      "username": "peerjs",
      "credential": "peerjsp",
    },
  ],
  "sdpSemantics": "unified-plan",
};

abstract class  BaseConnection extends StreamEventEmitter {


  BaseConnection(this.peer, this.provider, this.payload);

  bool open = false;
  late String connectionId;
  RTCPeerConnection? peerConnection;
  dynamic metadata;
  late AppWebRTC provider;
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

  String generateConnectId(String prefix) {
    String generateRandomString(int len) {
      var r = Random();
      const chars =
          'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
      return List.generate(len, (index) => chars[r.nextInt(chars.length)])
          .join()
          .toLowerCase();
    }

    return '${prefix}_${generateRandomString(10)}';
  }

}