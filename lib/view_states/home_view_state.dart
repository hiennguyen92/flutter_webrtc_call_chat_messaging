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




  void addMessage(String peer, dynamic data) {
    var byPeer = receivedData[peer];
    if(byPeer == null) {
      byPeer = Map.from({});
      receivedData[peer] = byPeer;
    }
    byPeer['messages'] ??= List<dynamic>.from([]);
    (byPeer['messages'] as List<dynamic>).add(data);
  }

  List<dynamic> getMessagesByPeer(String peer) {
    var byPeer = receivedData[peer];
    byPeer ??= Map.from({});
    return  byPeer['messages'] ??= List<dynamic>.from([]);
  }

  void readByPeer(String peer) {
    var byPeer = receivedData[peer];
    byPeer ??= Map.from({});
    byPeer['messages'] = List<dynamic>.from([]);
  }



}
