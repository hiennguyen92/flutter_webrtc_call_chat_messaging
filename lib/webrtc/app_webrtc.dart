import 'package:events_emitter/emitters/stream_event_emitter.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_api.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_socket.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/base_connection.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/data_connection.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/message.dart';

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
          .catchError((error) => emit<dynamic>(SocketEvent.Error.type, error));
    }
  }

  void _onSocketEvent() {
    _socket.on<Map<String, dynamic>>(SocketEvent.Message.type).listen((event) {
      final message = Message.fromMap(event);
      _handleMessage(message);
    });
    _socket.on<String>(SocketEvent.Error.type).listen((event) {
      emit<String?>(SocketEvent.Error.type, "error");
    });
    _socket.on(SocketEvent.Disconnected.type).listen((event) {
      emit<String?>(SocketEvent.Disconnected.type, "disconnected");
    });
  }

  void _handleMessage(Message message) {
    final type = message.type;
    final payload = message.payload;
    final peerId = message.src;
    print("payload $payload");
    switch (type) {
      case MessageType.Open:
        emit<String?>(SocketEvent.Connected.type, "open");
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
        final connection = getConnection(peerId!, message);
        if (connection != null) {
          connection.close();
          removeConnection(connection);
          print(
            "Offer received for existing Connection ID:${payload['connectionId']}",
          );
        }
        //Create Connection
        DataConnection dataConnection = DataConnection(peerId, this, payload);
        _addConnection(peerId, dataConnection: dataConnection);
        dataConnection.handleOffer(message);
        break;
      case MessageType.Answer:
        if (payload == null) {
          print("You received a message from $peerId of type $type");
          return;
        }
        print("ANSWER $peerId $payload");
        BaseConnection? connection = getConnection(peerId!, message);
        if (connection != null && connection.peerConnection != null) {
          connection.handleAnswer(message);
        }
        break;
      case MessageType.Candidate:
        if (payload == null) {
          print("You received a message from $peerId of type $type");
          return;
        }
        BaseConnection? connection = getConnection(peerId!, message);
        if (connection != null && connection.peerConnection != null) {
          connection.handleCandidate(message);
        }
        break;
      default:
        print("You received a malformed message from $peerId of type $type");
    }
  }

  AppSocket get socket {
    return _socket;
  }

  AppAPI get api {
    return _api;
  }

  String? getCurrentId() {
    return socket.getId();
  }

  bool isConnected() {
    return _socket.isConnected();
  }

  void disconnect() {
    _socket.disconnect();
  }

  void dispose() {
    emit<String?>(SocketEvent.Disconnected.type, _socket.getId());
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

  DataConnection connect(String peer, {dynamic payload}) {
    if (!_socket.isConnected()) {
      print(
        'You cannot connect to a new Peer because you called .disconnect() on this Peer and ended your connection with the server. You can create a new Peer to reconnect, or call reconnect on this peer if you believe its ID to still be available.',
      );
    }
    final dataConnection = DataConnection(peer, this, payload);
    dataConnection.makeOffer();
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
  dynamic getConnection(String peerId, Message message) {
    final payload = message.payload;
    if (!_connections.containsKey(peerId)) {
      print("Could not get connection with id: $peerId");
      return null;
    }
    final connections = _connections[peerId];

    if (connections != null) {
      for (final connection in connections) {
        if (connection.connectionId == payload['connectionId']) {
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
}
