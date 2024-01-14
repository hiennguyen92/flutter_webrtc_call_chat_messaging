import 'package:flutter_webrtc/flutter_webrtc.dart' as flutter_webrtc;
import 'package:flutter_webrtc_call_chat_messaging/webrtc/baseconnecttion.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/dataconnection.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/mediaconnection.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/options.dart';

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

class Negotiator<T extends BaseConnection> {
  T connection;
  Negotiator(this.connection);

  Future<void> startConnection(PeerConnectOption options) async {
    final peerConnection = await _startPeerConnection();
    connection.peerConnection = peerConnection;

    // if (connection.type == ConnectionType.Media && options.stream != null) {
    //   _addTracksToConnection(options.stream!, peerConnection);
    // }

    if (options.originator != null && options.originator!) {
      if (connection.type == ConnectionType.Data) {
        final dataConnection = connection as DataConnection;

        final flutter_webrtc.RTCDataChannelInit config =
            flutter_webrtc.RTCDataChannelInit();

        final dataChannel = await peerConnection.createDataChannel(
            DataChannels.data.name, config);

        dataConnection.initialize(dataChannel);
      }
      await _makeOffer();
    } else {
      await handleSDP("OFFER", options.sdp!);
    }
  }

  Future<flutter_webrtc.RTCPeerConnection> _startPeerConnection() async {
    print("Creating RTCpeerConnection?.");

    final peerConnection =
        await flutter_webrtc.createPeerConnection(_DEFAULT_CONFIG ?? {});

    _setupListeners(peerConnection);

    return peerConnection;
  }

  Future<void> handleSDP(String type, Map<String, dynamic> sdp) async {
    final description =
        flutter_webrtc.RTCSessionDescription(sdp["sdp"], sdp["type"]);

    final peerConnection = connection.peerConnection;
    final provider = connection.provider;
    print("Setting remote description $sdp");

    try {
      await peerConnection?.setRemoteDescription(description);
      print("Set remoteDescription:$type for:${connection.peer}");
      if (type == "OFFER") {
        await _makeAnswer();
      }
    } catch (err) {
      //provider?.emitError(PeerErrorType.WebRTC, err);
      print("Failed to setRemoteDescription, $err");
    }
  }

  Future<void> _makeAnswer() async {
    final peerConnection = connection.peerConnection;
    final provider = connection.provider;

    try {
      final answer = await peerConnection?.createAnswer();
      print("Created answer.");

      try {
        await peerConnection?.setLocalDescription(answer!);

        print("Set localDescription: $answer for ${connection.peer}");

        provider?.socket.send({
          "type": MessageType.Answer.type,
          "payload": {
            "sdp": answer?.toMap(),
            "type": connection.type.type,
            "connectionId": connection.connectionId,
            "browser": "s",
          },
          "dst": connection.peer,
        });
      } catch (err) {
        //provider?.emitError(PeerErrorType.WebRTC, err);
        print("Failed to setLocalDescription, $err");
      }
    } catch (e) {
      print("Failed to create answer, $e");
    }
  }

  Future<void> _makeOffer() async {
    final peerConnection = connection.peerConnection;
    final provider = connection.provider;

    try {
      flutter_webrtc.RTCSessionDescription offer;

      offer = await peerConnection!.createOffer();

      print("Created offer.");

      try {
        await peerConnection.setLocalDescription(offer);

        print("Set localDescription: $offer for ${connection.peer}");

        var payload = {
          "sdp": offer.toMap(),
          "type": connection.type.type,
          "connectionId": connection.connectionId,
          "metadata": connection.metadata,
          "browser": "ds",
        };

        if (connection.type == ConnectionType.Data) {
          final dataConnection = connection as DataConnection;

          payload = {
            ...payload,
            "label": dataConnection.label,
            "reliable": dataConnection.reliable,
            "serialization": dataConnection.serialization.type,
          };
        }

        provider?.socket.send({
          "type": MessageType.Offer.type,
          "payload": payload,
          "dst": connection.peer,
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

  void _setupListeners(flutter_webrtc.RTCPeerConnection peerConnection) {
    final peerId = connection.peer;
    final connectionId = connection.connectionId;
    final connectionType = connection.type;
    final provider = connection.provider;
    final candidates = [];

    // ICE CANDIDATES.
    print("Listening for ICE candidates.");

    peerConnection.onIceCandidate = (candidate) {
      print("Received ICE candidates for $peerId: $candidate");

      /// If the second peer is connected and ready to receive candidates,
      /// Else, we store the received candidates and store them in the array
      /// above and send them when the second peer is ready
      final cdt = {
        "type": MessageType.Candidate.type,
        "payload": {
          "candidate": candidate.toMap(),
          "type": connectionType.type,
          "connectionId": connectionId,
        },
        "dst": peerId,
      };
      if (connection is! MediaConnection) {
        provider?.socket.send(cdt);
      } else if (peerConnection.connectionState != null) {
        provider?.socket.send(cdt);
      } else {
        candidates.add(cdt);
      }
    };

    /// The second peer is connected and ready to receive candidates
    if (connection is MediaConnection) {
      connection.on('stream').listen((event) {
        for (var data in candidates) {
          provider?.socket.send(data);
        }
        candidates.clear();
      });
    }

    peerConnection.onIceConnectionState = (state) {
      switch (state) {
        case flutter_webrtc
              .RTCIceConnectionState.RTCIceConnectionStateCompleted:
          peerConnection.onIceCandidate = (_) {};
          break;

        case flutter_webrtc.RTCIceConnectionState.RTCIceConnectionStateFailed:
          print(
            "iceConnectionState is failed, closing connections to $peerId",
          );
          connection.emit<Exception>(
            "error",
            Exception("${"Negotiation of connection to $peerId"} failed."),
          );
          connection.closeRequest();
          connection.dispose();
          break;
        case flutter_webrtc
              .RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          print(
            "iceConnectionState changed to disconnected on the connection with $peerId",
          );
          connection.closeRequest();
          connection.dispose();
          break;
        case flutter_webrtc.RTCIceConnectionState.RTCIceConnectionStateClosed:
          print(
            "iceConnectionState is closed, closing connections to $peerId",
          );
          connection.emit<Exception>(
            "error",
            Exception("Connection to $peerId closed."),
          );
          connection.closeRequest();
          connection.dispose();
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

      connection.emit<flutter_webrtc.RTCIceConnectionState?>(
        "iceStateChanged",
        peerConnection.iceConnectionState,
      );
    };

    // DATACONNECTION.
    print("Listening for data channel");
    // Fired between offer and answer, so options should already be saved
    // in the options hash.

    peerConnection.onDataChannel = (channel) {
      print("Received data channel ${channel.label}");

      final dataChannel = channel;

      final DataConnection connection =
          provider?.getConnection(peerId, connectionId);

      connection.initialize(dataChannel);
    };

    // MEDIACONNECTION.
    // print("Listening for remote stream");
    //
    // peerConnection.onTrack = (track) {
    //   print("Received remote stream");
    //
    //   final stream = track.streams[0];
    //   final connection = provider?.getConnection(peerId, connectionId);
    //
    //   if (connection.type == ConnectionType.Media) {
    //     final mediaConnection = connection as MediaConnection;
    //
    //     _addStreamToMediaConnection(stream, mediaConnection);
    //   }
    // };
  }

  void cleanup() {
    print("Cleaning up PeerConnection to ${connection.peer}");

    final peerConnection = connection.peerConnection;
    final peerConnectionNotClosed = peerConnection?.signalingState !=
        flutter_webrtc.RTCSignalingState.RTCSignalingStateClosed;
    bool dataChannelNotClosed = false;

    if (peerConnection == null) {
      return;
    }

    if (peerConnectionNotClosed || dataChannelNotClosed) {
      peerConnection.close();
    }

    connection.peerConnection?.dispose();
  }

  // void _addStreamToMediaConnection(
  //     MediaStream stream,
  //     MediaConnection mediaConnection,
  //     ) {
  //   logger.log(
  //       "add stream ${stream.id} to media connection ${mediaConnection.connectionId}");
  //
  //   mediaConnection.addStream(stream);
  // }

  Future<void> handleCandidate(flutter_webrtc.RTCIceCandidate ice) async {
    print("handleCandidate: $ice");

    final peerConnection = connection.peerConnection;
    final provider = connection.provider;

    try {
      await peerConnection?.addCandidate(ice);
      print("Added ICE candidate for:${connection.peer}");
    } catch (err) {
      //provider?.emitError(PeerErrorType.WebRTC, err);
      print("Failed to handleCandidate, $err");
    }
  }
}
