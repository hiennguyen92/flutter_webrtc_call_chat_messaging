import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/base_connection.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/message.dart';

const _DEFAULT_CONFIG = {
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

String generateConnectId() {
  String generateRandomString(int len) {
    var r = Random();
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => chars[r.nextInt(chars.length)])
        .join()
        .toLowerCase();
  }

  return 'mc_${generateRandomString(10)}';
}

class MediaConnection extends BaseConnection {
  late String label;
  late webrtc.MediaStream? localStream;
  late webrtc.MediaStream? remoteStream;

  MediaConnection(super.peer, super.provider, super.payload) {
    connectionId = payload?['connectionId'] ?? generateConnectId();
    label = connectionId;
  }

  void _initialize([webrtc.MediaStream? ms]) async {
    if (ms != null) {
      ms.getTracks().forEach((track) => peerConnection?.addTrack(track, ms));
    }
    _dataChannelListeners();
  }

  void _sendIceCandidate(webrtc.RTCIceCandidate candidate) {
    var payload = {
      "candidate": candidate.toMap(),
      "type": type.type,
      "connectionId": connectionId
    };
    provider.socket.send(
        {"type": MessageType.Candidate.type, "payload": payload, "dst": peer});
  }

  void _setUpListeners() {
    peerConnection?.onIceCandidate = (candidate) {
      print("onIceCandidate");
      _sendIceCandidate(candidate);
    };
    peerConnection?.onIceConnectionState = (state) {
      switch (state) {
        case webrtc.RTCIceConnectionState.RTCIceConnectionStateCompleted:
          peerConnection?.onIceCandidate = (_) {};
          break;
        case webrtc.RTCIceConnectionState.RTCIceConnectionStateFailed:
          print(
            "iceConnectionState is failed, closing connections to $peer",
          );
          closeRequest();
          dispose();
          break;
        case webrtc.RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          print(
              "iceConnectionState changed to disconnected on the connection with $peer");
          closeRequest();
          dispose();
          break;
        case webrtc.RTCIceConnectionState.RTCIceConnectionStateClosed:
          print("iceConnectionState is closed, closing connections to $peer");
          closeRequest();
          dispose();
          break;
        case webrtc.RTCIceConnectionState.RTCIceConnectionStateNew:
          // TODO: Handle this case.
          break;
        case webrtc.RTCIceConnectionState.RTCIceConnectionStateChecking:
          // TODO: Handle this case.
          break;
        case webrtc.RTCIceConnectionState.RTCIceConnectionStateConnected:
          // TODO: Handle this case.
          break;
        case webrtc.RTCIceConnectionState.RTCIceConnectionStateCount:
          // TODO: Handle this case.
          break;
      }
    };
  }


  void addStream(webrtc.MediaStream remoteStream) {
    print('Receiving stream $remoteStream');

    this.remoteStream = remoteStream;
    // provider?.emit('stream', null, remoteStream); // Should we call this `open`?
    // emit('stream', null, remoteStream); // Should we call this `open`?
    super.emit<webrtc.MediaStream>('stream', remoteStream); // Should we call this `open`?
  }

  void _dataChannelListeners() {
      peerConnection?.onTrack = (track) {
        print("Received remote stream");
        final stream = track.streams[0];
        addStream(stream);
      };
  }

  Future<void> _makeOffer() async {
    try {
      webrtc.RTCSessionDescription offer = await peerConnection!.createOffer();
      print("Created offer.");

      await peerConnection!.setLocalDescription(offer);
      var payload = {
        "label": label,
        "sdp": offer.toMap(),
        "type": type.type,
        "connectionId": connectionId,
        "metadata": metadata,
        "browser": "ds",
      };
      provider.socket.send({
        "type": MessageType.Offer.type,
        "payload": payload,
        "dst": peer,
      });
    } catch (error) {
      print("_makeOffer error: $error");
    }
  }

  Future<void> _makeAnswer() async {
    try {
      var sdp = super.payload["sdp"];
      final description = webrtc.RTCSessionDescription(sdp["sdp"], sdp["type"]);
      await peerConnection?.setRemoteDescription(description);

      final answer = await peerConnection?.createAnswer();
      print("Created answer.");

      await peerConnection?.setLocalDescription(answer!);

      var payload = {
        "sdp": answer?.toMap(),
        "type": type.type,
        "connectionId": connectionId,
        "browser": "s"
      };
      provider.socket.send({
        "type": MessageType.Answer.type,
        "payload": payload,
        "dst": peer,
      });
    } catch (error) {
      print("_makeAnswer error: $error");
    }
  }


  @override
  void dispose() {
    print("Cleaning up PeerConnection to $peer");
    if (peerConnection == null) {
      return;
    }
    peerConnection?.close();
    peerConnection?.dispose();

    if (!open) {
      return;
    }
    open = false;
    close();
  }

  @override
  Future<void> makeOffer() async {
    peerConnection = await webrtc.createPeerConnection(_DEFAULT_CONFIG ?? {});
    localStream = await webrtc.navigator.mediaDevices.getUserMedia({ "video": true, "audio": true });
    _initialize(localStream);
    _setUpListeners();
    _makeOffer();
    provider.emit<MediaConnection>(MediaConnectionEvent.Connection.type, this);
  }

  @override
  Future<void> handleOffer(Message message) async {
    provider.emit<MediaConnection>(MediaConnectionEvent.Connection.type, this);
    peerConnection = await webrtc.createPeerConnection(_DEFAULT_CONFIG ?? {});
    _setUpListeners();
    _makeAnswer();
  }

  @override
  Future<void> handleAnswer(Message message) async {
    var sdp = message.payload["sdp"];
    final description = webrtc.RTCSessionDescription(sdp["sdp"], sdp["type"]);
    await peerConnection?.setRemoteDescription(description);
  }

  @override
  Future<void> handleCandidate(Message message) async {
    try {
      final payload = message.payload;
      var iceCandidate = webrtc.RTCIceCandidate(
          payload["candidate"]["candidate"],
          payload["candidate"]["sdpMid"],
          payload["candidate"]["sdpMLineIndex"]);

      await peerConnection?.addCandidate(iceCandidate);
      print("Added ICE candidate for:$peer");
    } catch (err) {
      print("Failed to handleCandidate, $err");
    }
  }

  @override
  ConnectionType get type => ConnectionType.Media;

}
