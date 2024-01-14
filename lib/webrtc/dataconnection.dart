import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart' as flutter_webrtc;
import 'package:flutter_webrtc_call_chat_messaging/webrtc/baseconnecttion.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/message.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/negotiator.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/options.dart';
//import 'package:flutter_webrtc_call_chat_messaging/webrtc/options.dart';

const _DEFAULT_CONFIG = {
  'iceServers': [
    {'urls': "stun:stun.bethesda.net:3478"},
    {
      "urls": [
        "turn:eu-0.turn.peerjs.com:3478",
        "turn:us-0.turn.peerjs.com:3478",
      ],
      "username": "peerjs",
      "credential": "peerjsp",
    },
  ],
  'sdpSemantics': "unified-plan"
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

  return 'dc_${generateRandomString(10)}';
}

class DataConnection extends BaseConnection {
  DataConnection(super.peer, super.provider, super.options) {
    connectionId = options?.connectionId ?? generateConnectId();
    label = connectionId;
    serialization = options?.serialization ?? SerializationType.JSON;
    reliable = options?.reliable ?? false;

    //Start Connection
    startConnection(options?.payload ?? PeerConnectOption(originator: true));
  }

  Future<void> startConnection(PeerConnectOption options) async {
    peerConnection =
        await flutter_webrtc.createPeerConnection(_DEFAULT_CONFIG ?? {});

    final candidates = [];
    peerConnection?.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;

      print("Received ICE candidates for $peer: $candidate");

      /// If the second peer is connected and ready to receive candidates,
      /// Else, we store the received candidates and store them in the array
      /// above and send them when the second peer is ready
      final cdt = {
        "type": MessageType.Candidate.type,
        "payload": {
          "candidate": candidate.toMap(),
          "type": type,
          "connectionId": connectionId,
        },
        "dst": peer,
      };
      if (peerConnection?.connectionState != null) {
        provider?.socket.send(cdt);
      } else {
        candidates.add(cdt);
      }
    };

    peerConnection?.onIceConnectionState = (state) {
      switch (state) {
        case flutter_webrtc
              .RTCIceConnectionState.RTCIceConnectionStateCompleted:
          peerConnection?.onIceCandidate = (_) {};
          break;

        case flutter_webrtc.RTCIceConnectionState.RTCIceConnectionStateFailed:
          print(
            "iceConnectionState is failed, closing connections to $peer",
          );
          emit<Exception>(
            "error",
            Exception("${"Negotiation of connection to $peer"} failed."),
          );
          closeRequest();
          dispose();
          break;
        case flutter_webrtc
              .RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          print(
            "iceConnectionState changed to disconnected on the connection with $peer",
          );
          closeRequest();
          dispose();
          break;
        case flutter_webrtc.RTCIceConnectionState.RTCIceConnectionStateClosed:
          print(
            "iceConnectionState is closed, closing connections to $peer",
          );
          emit<Exception>(
            "error",
            Exception("Connection to $peer closed."),
          );
          closeRequest();
          dispose();
          break;
        case flutter_webrtc.RTCIceConnectionState.RTCIceConnectionStateNew:
          // TODO: Handle this case.
          break;
        case flutter_webrtc.RTCIceConnectionState.RTCIceConnectionStateChecking:
          // TODO: Handle this case.
          break;
        case flutter_webrtc
              .RTCIceConnectionState.RTCIceConnectionStateConnected:
          // TODO: Handle this case.
          break;
        case flutter_webrtc.RTCIceConnectionState.RTCIceConnectionStateCount:
          // TODO: Handle this case.
          break;
      }
      print(
        "iceConnectionState: ${peerConnection?.iceConnectionState}",
      );
      emit<flutter_webrtc.RTCIceConnectionState?>(
        "iceStateChanged",
        peerConnection?.iceConnectionState,
      );
    };

    // DATACONNECTION.
    print("Listening for data channel");
    // Fired between offer and answer, so options should already be saved
    // in the options hash.

    peerConnection?.onDataChannel = (channel) {
      print("Received data channel ${channel.label}");

      final dataChannel = channel;

      final DataConnection connection =
          provider?.getConnection(peer, connectionId);

      connection.initialize(dataChannel);
    };

    if (options.originator != null && options.originator!) {
      final flutter_webrtc.RTCDataChannelInit config =
          flutter_webrtc.RTCDataChannelInit();

      final dataChannel = await peerConnection?.createDataChannel(
          DataChannels.data.name, config);

      initialize(dataChannel!);

      await _makeOffer();
    } else {
      await handleSDP("OFFER", options.sdp!);
    }
  }

  Future<void> handleSDP(String type, Map<String, dynamic> sdp) async {
    final description =
        flutter_webrtc.RTCSessionDescription(sdp["sdp"], sdp["type"]);

    print("Setting remote description $sdp");

    try {
      await peerConnection?.setRemoteDescription(description);
      print("Set remoteDescription:$type for:$peer");
      if (type == "OFFER") {
        await _makeAnswer();
      }
    } catch (err) {
      //provider?.emitError(PeerErrorType.WebRTC, err);
      print("Failed to setRemoteDescription, $err");
    }
  }

  Future<void> _makeOffer() async {
    try {
      flutter_webrtc.RTCSessionDescription offer;

      offer = await peerConnection!.createOffer();

      print("Created offer.");

      try {
        await peerConnection!.setLocalDescription(offer);

        print("Set localDescription: $offer for $peer");

        var payload = {
          "sdp": offer.toMap(),
          "type": type.type,
          "connectionId": connectionId,
          "metadata": "metadata-test",
          "browser": "ds",
        };

        payload = {
          ...payload,
          "label": label,
          "reliable": reliable,
          "serialization": serialization.type,
        };

        provider?.socket.send({
          "type": MessageType.Offer.type,
          "payload": payload,
          "dst": peer,
        });
      } catch (e) {
        //provider?.emitError(PeerErrorType.WebRTC, e);
        print("Failed to setLocalDescription, $e");
      }
    } catch (err) {
      //provider?.emitError(PeerErrorType.WebRTC, err);
      print("Failed to createOffer, $err");
    }
  }

  Future<void> _makeAnswer() async {
    try {
      final answer = await peerConnection?.createAnswer();
      print("Created answer.");

      try {
        await peerConnection?.setLocalDescription(answer!);

        print("Set localDescription: $answer for $peer");

        provider?.socket.send({
          "type": MessageType.Answer.type,
          "payload": {
            "sdp": answer?.toMap(),
            "type": type.type,
            "connectionId": connectionId,
            "browser": "s",
          },
          "dst": peer,
        });
      } catch (err) {
        //provider?.emitError(PeerErrorType.WebRTC, err);
        print("Failed to setLocalDescription, $err");
      }
    } catch (e) {
      print("Failed to create answer, $e");
    }
  }

  late String label;
  late bool reliable;

  SerializationType serialization = SerializationType.JSON;

  flutter_webrtc.RTCDataChannel? _dc;

  flutter_webrtc.RTCDataChannel? get dataChannel {
    return _dc;
  }

  @override
  void dispose() {
    print("Cleaning up PeerConnection to $peer");

    final peerConnectionNotClosed = peerConnection?.signalingState !=
        flutter_webrtc.RTCSignalingState.RTCSignalingStateClosed;
    bool dataChannelNotClosed = false;

    if (peerConnection == null) {
      return;
    }

    if (peerConnectionNotClosed || dataChannelNotClosed) {
      peerConnection?.close();
    }

    peerConnection?.dispose();

    dataChannel?.onDataChannelState = null;
    dataChannel?.onMessage = null;
    _dc = null;

    if (!open) {
      return;
    }

    open = false;

    close();
  }

  @override
  Future<void> handleMessage(Message message) async {
    final payload = message.payload;
    print("Vao Day: ${message.type}");
    switch (message.type) {
      case MessageType.Answer:
        handleSDP(payload["sdp"]["type"], payload["sdp"]);
        break;

      case MessageType.Candidate:
        var ice = flutter_webrtc.RTCIceCandidate(
            payload["candidate"]["candidate"],
            payload["candidate"]["sdpMid"],
            payload["candidate"]["sdpMLineIndex"]);
        print("handleCandidate: $ice");
        try {
          await peerConnection?.addCandidate(ice);
          print("Added ICE candidate for:$peer");
        } catch (err) {
          //provider?.emitError(PeerErrorType.WebRTC, err);
          print("Failed to handleCandidate, $err");
        }
        break;
      default:
        print(
          "Unrecognized message type:${message.type.type} from peer: $peer",
        );
        break;
    }
  }

  @override
  ConnectionType get type => ConnectionType.Data;

  /// Called by the Negotiator when the DataChannel is ready. */
  void initialize(flutter_webrtc.RTCDataChannel dc) {
    _dc = dc;
    _configureDataChannel();
  }

  void _handleRTCEvents(flutter_webrtc.RTCDataChannelState state) {
    switch (state) {
      case flutter_webrtc.RTCDataChannelState.RTCDataChannelOpen:
        print('DC#$connectionId dc connection success');
        open = true;
        super.emit<void>('open', null);
        break;

      case flutter_webrtc.RTCDataChannelState.RTCDataChannelClosed:
        print('DC#$connectionId dc closed for:$peer');
        closeRequest();
        dispose();
        break;
      case flutter_webrtc.RTCDataChannelState.RTCDataChannelConnecting:
        // TODO: Handle this case.
        break;
      case flutter_webrtc.RTCDataChannelState.RTCDataChannelClosing:
        // TODO: Handle this case.
        break;
    }
  }

  void _configureDataChannel() {
    dataChannel?.onDataChannelState = (state) {
      _handleRTCEvents(state);

      dataChannel?.onMessage = (message) {
        String? msg;

        if (!message.isBinary) {
          msg = message.text;
        }

        print('DC#$connectionId dc onmessage:$msg');
        _handleDataMessage(message);
      };
    };
  }

  void _handleDataMessage(flutter_webrtc.RTCDataChannelMessage message) {
    final datatype = message.type;

    if (datatype == flutter_webrtc.MessageType.text) {
      dynamic deserializedData = jsonDecode(message.text);

      super.emit('data', deserializedData);
    }

    if (datatype == flutter_webrtc.MessageType.binary) {
      super.emit<Uint8List>('binary', message.binary);
    }
  }

  Future<void> send(dynamic data) async {
    if (!open) {
      print(
        "Connection is not open. You should listen for the `open` event before sending messages.",
      );
      super.emit(
        "error",
        Exception(
          "Connection is not open. You should listen for the `open` event before sending messages.",
        ),
      );
      return;
    }

    if (serialization == SerializationType.JSON) {
      await dataChannel
          ?.send(flutter_webrtc.RTCDataChannelMessage(jsonEncode(data)));
    }
  }

  Future<void> sendBinary(Uint8List binary) async {
    if (!open) {
      print(
        "Connection is not open. You should listen for the `open` event before sending messages.",
      );
      super.emit(
        "error",
        Exception(
          "Connection is not open. You should listen for the `open` event before sending messages.",
        ),
      );
      return;
    }

    final message = flutter_webrtc.RTCDataChannelMessage.fromBinary(binary);

    await dataChannel?.send(message);
  }
}
