import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/base_connection.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/message.dart';

class DataConnection extends BaseConnection {
  late String label;
  late bool reliable;
  SerializationType serialization = SerializationType.JSON;
  webrtc.RTCDataChannel? _dc;

  DataConnection(super.peer, super.provider, super.payload) {
    connectionId = payload?['connectionId'] ?? generateConnectId('dc');
    label = connectionId;
    serialization = SerializationType.JSON;
    reliable = false;
  }

  void _initialize([webrtc.RTCDataChannel? dc]) async {
    _dc = dc;
    if (_dc == null) {
      webrtc.RTCDataChannelInit config = webrtc.RTCDataChannelInit();
      _dc = await peerConnection?.createDataChannel(label, config);
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
    peerConnection?.onDataChannel = (channel) {
      print("onDataChannel");
      _initialize(channel);
    };
  }

  void _dataChannelListeners() {
    _dc?.onDataChannelState = (state) {
      switch (state) {
        case webrtc.RTCDataChannelState.RTCDataChannelOpen:
          open = true;
          super.emit<DataConnection>(DataConnectionEvent.Open.type, this);
          break;
        case webrtc.RTCDataChannelState.RTCDataChannelClosed:
          super.emit<DataConnection>(DataConnectionEvent.Closed.type, this);
          closeRequest();
          dispose();
          break;
        case webrtc.RTCDataChannelState.RTCDataChannelConnecting:
          super.emit<DataConnection>(DataConnectionEvent.Connecting.type, this);
          break;
        case webrtc.RTCDataChannelState.RTCDataChannelClosing:
          super.emit<DataConnection>(DataConnectionEvent.Closing.type, this);
          break;
      }
    };
    _dc?.onMessage = (message) {
      final datatype = message.type;
      if (datatype == webrtc.MessageType.text) {
        dynamic deserializedData = jsonDecode(message.text);
        super.emit<dynamic>(
            DataConnectionEvent.Data.type, _buildData(deserializedData, peer));
      }
      if (datatype == webrtc.MessageType.binary) {
        super.emit<dynamic>(
            DataConnectionEvent.Binary.type, _buildData(message.binary, peer));
      }
    };
  }

  Future<void> _makeOffer() async {
    try {
      webrtc.RTCSessionDescription offer = await peerConnection!.createOffer();
      print("Created offer.");

      await peerConnection!.setLocalDescription(offer);
      var payload = {
        "label": label,
        "reliable": reliable,
        "serialization": serialization.type,
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

  webrtc.RTCDataChannel? get dataChannel {
    return _dc;
  }

  @override
  void dispose() {
    print("Cleaning up PeerConnection to $peer");
    if (peerConnection == null) {
      return;
    }
    peerConnection?.close();
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
  Future<void> makeOffer() async {
    peerConnection = await webrtc.createPeerConnection(DEFAULT_CONFIG ?? {});
    _initialize();
    _setUpListeners();
    _makeOffer();
    provider.emit<DataConnection>(DataConnectionEvent.Connection.type, this);
  }

  @override
  Future<void> handleOffer(Message message) async {
    provider.emit<DataConnection>(DataConnectionEvent.Connection.type, this);
    peerConnection = await webrtc.createPeerConnection(DEFAULT_CONFIG ?? {});
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
  ConnectionType get type => ConnectionType.Data;

  Future<dynamic> send(dynamic text) async {
    if (!open) {
      print(
          "Connection is not open. You should listen for the `open` event before sending messages.");
      return;
    }
    if (serialization == SerializationType.JSON) {
      await dataChannel?.send(webrtc.RTCDataChannelMessage(jsonEncode(text)));
    }
    return _buildData(text, provider.getCurrentId());
  }

  dynamic _buildData(dynamic data, String? cPeer) {
    dynamic builder = Map.from({});
    builder['data'] = data;
    builder['peer'] = cPeer;
    return builder;
  }

  Future<void> sendBinary(Uint8List binary) async {}
}
