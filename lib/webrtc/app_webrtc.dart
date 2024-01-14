import 'dart:convert';

import 'package:events_emitter/emitters/stream_event_emitter.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_api.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_socket.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/baseconnecttion.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/dataconnection.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/message.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/options.dart';

class AppWebRTC extends StreamEventEmitter {
  late AppAPI _api;
  late AppSocket _socket;

  final Map<String, List<dynamic>> _connections = {};
  final Map<String, List<Message>> _lostMessages = {};

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
        print("OFFER $peerId $payload");
        print("XXX ${payload["connectionId"]}");
        final connectionId = payload["connectionId"];
        if (peerId != null) {
          DataConnection? connection = getConnection(peerId, connectionId);
          if (connection != null) {
            connection.close();
            print(
              "Offer received for existing Connection ID:$connectionId",
            );
          }
          if (payload["type"] == ConnectionType.Data.type) {

            final serializedPayload = PeerConnectOption.fromMap(payload);

            final data = PeerConnectOption(
              connectionId: connectionId,
              payload: serializedPayload,
              metadata: payload["metadata"],
              label: payload["label"],
              serialization: SerializationType.values.singleWhere(
                      (element) => element.type == payload["serialization"]),
              reliable: payload["reliable"],
            );


            connection = DataConnection(peerId, this, data);
            _addConnection(peerId, dataConnection: connection);
            emit<DataConnection>("connection", connection);
          } else {
            print("Received malformed connection type:${payload.type}");
            return;
          }
          // Find messages.
          final messages = getMessages(connectionId);
          for (var message in messages) {
            connection.handleMessage(message);
          }
        }
        break;
      default:
        {
          if (payload == null) {
            print(
              "You received a malformed message from $peerId of type $type",
            );
            return;
          }

          final connectionId = payload["connectionId"];
          DataConnection connection = getConnection(peerId!, connectionId);

          if (connection != null && connection.peerConnection != null) {
            // Pass it on.
            connection.handleMessage(message);
          } else if (connectionId != null) {
            // Store for possible later use
            _storeMessage(connectionId, message);
          } else {
            print("You received an unrecognized message:$message");
          }
        }
    }
  }

  AppSocket get socket {
    return _socket;
  }

  AppAPI get api {
    return _api;
  }

  void disconnect() {
    _socket.disconnect();
  }

  void dispose() {
    emit<String?>(SocketEventType.Disconnected.type, _socket.getId());
    _socket.dispose();
    _cleanup();
  }

  void _cleanup() {
    final List<String> toRemove = [];
    for (var peer in _connections.keys) {
      toRemove.add(peer);
    }

    for (var peer in toRemove) {
      _cleanupPeer(peer);
      _connections.removeWhere((key, value) => key == peer);
    }
  }

  DataConnection connect(String peer, {PeerConnectOption? options}) {
    if (!_socket.isConnected()) {
      print(
        'You cannot connect to a new Peer because you called .disconnect() on this Peer and ended your connection with the server. You can create a new Peer to reconnect, or call reconnect on this peer if you believe its ID to still be available.',
      );
    }
    final dataConnection =
        DataConnection(peer, this, options);
    _addConnection(peer, dataConnection: dataConnection);
    return dataConnection;
  }

  /// Add a data/media connection to this peer. */
  /// connection: DataConnection / MediaConnection
  void _addConnection(String peerId, {DataConnection? dataConnection}) {
    late BaseConnection connection;

    if (dataConnection != null) {
      connection = dataConnection;
    }

    print(
      'add connection ${connection.type}:${connection.connectionId} to peerId:$peerId',
    );

    if (!_connections.containsKey(peerId)) {
      _connections[peerId] = [];
    }

    _connections[peerId]?.add(connection);
  }

  /// connection: DataConnection / MediaConnection
  void removeConnection(dynamic connection) {
    final connections = _connections[connection.peer] as List<dynamic>;

    final index = connections
        .indexWhere((c) => c.connectionId == connection.connectionId);

    connections.removeAt(index);

    //remove from lost messages
    _lostMessages.removeWhere((k, v) => k == connection.connectionId);
  }

  /// Retrieve a data/media connection for this peer. */
  dynamic getConnection(String peerId, String connectionId) {
    if (!_connections.containsKey(peerId)) {
      print("Could not get connection with id: $peerId");
      return null;
    }
    final connections = _connections[peerId];

    if (connections != null) {
      for (final connection in connections) {
        if (connection.connectionId == connectionId) {
          return connection;
        }
      }
    }
    return null;
  }

  void _cleanupPeer(String peerId) {
    final connections = _connections[peerId];

    if (connections == null) return;

    for (var connection in connections) {
      connection?.dispose();
    }
  }

  /// Stores messages without a set up connection, to be claimed later. */
  List<Message> getMessages(String connectionId) {
    final messages = _lostMessages[connectionId];

    if (messages != null) {
      _lostMessages.removeWhere((key, value) => key == connectionId);

      return messages;
    }

    return [];
  }

  /// Stores messages without a set up connection, to be claimed later. */
  void _storeMessage(String connectionId, Message message) {
    if (!_lostMessages.containsKey(connectionId)) {
      _lostMessages[connectionId] = [];
    }

    _lostMessages[connectionId]?.add(message);
  }
}
