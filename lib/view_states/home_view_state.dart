import 'package:flutter_webrtc_call_chat_messaging/webrtc/data_connection.dart';

class HomeViewState {
  String? displayName;
  String? status;

  List<String> peers = [];
  List<dynamic> users = [];

  Map<String, dynamic> receivedData = Map.from({});

  HomeViewState();

  String getStatus() {
    return status ?? "None";
  }

  bool hasDisplayName() {
    return displayName != null && displayName!.isNotEmpty;
  }

  void addReceivedMessage(String peer, dynamic data) {
    var byPeer = receivedData[peer];
    byPeer ??= Map.from({});
    byPeer['messages'] ??= List<dynamic>.from([]);
    (byPeer['messages'] as List<dynamic>).add(data);
  }

  void addDataConnection(DataConnection dataConnection) {
    var byPeer = receivedData[dataConnection.peer];
    byPeer ??= Map.from({});
    byPeer['dataConnection'] = dataConnection;
  }


}
