import 'package:flutter/material.dart';
import 'package:flutter_webrtc_call_chat_messaging/base/base_view_model.dart';
import 'package:flutter_webrtc_call_chat_messaging/view_states/home_view_state.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_webrtc.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/dataconnection.dart';

class HomeViewModel extends BaseViewModel<HomeViewState> {
  late final AppWebRTC _appWebRTC;

  HomeViewModel(BuildContext context, this._appWebRTC)
      : super(context, HomeViewState()) {
    _onEventListeners();
  }

  void _onEventListeners() {
    _appWebRTC.on(AppEvent.Connected.type).listen((event) {
      state.status = "Connected";
      _getPeers();
      notifyListeners();
    });
    _appWebRTC.on(AppEvent.Disconnected.type).listen((event) {
      state.status = "Disconnected";
      _getPeers();
      notifyListeners();
    });
    _appWebRTC.on(AppEvent.Error.type).listen((event) {
      state.status = "Error";
      _getPeers();
      notifyListeners();
    });
  }

  Future<void> _getPeers() async {
    _appWebRTC.api.getPeers().then((value) {
      print("peers: $value");
      state.peers = value;
      notifyListeners();
    }).catchError((error) {
      print("Error get peers");
    });
  }

  Future<void> start() async {
    _appWebRTC.start();
  }

  Future<void> connect(String peer) async {
    var conn = _appWebRTC.connect(peer);
    conn.on<DataConnection>("connection").listen((event) {
      print("ON connection");
    });
    conn.on("open").listen((event) {
      print("ON open");
    });
    conn.on("data").listen((event) {
      print("ON data");
    });
    conn.on("binary").listen((event) {
      print("ON binary");
    });
  }

  Future<void> disconnect() async {
    _appWebRTC.disconnect();
  }

  bool isMe(String peer) {
    return _appWebRTC.socket.getId() == peer;
  }
}
