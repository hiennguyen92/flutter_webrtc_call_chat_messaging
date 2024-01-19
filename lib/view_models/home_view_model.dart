import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc_call_chat_messaging/base/base_view_model.dart';
import 'package:flutter_webrtc_call_chat_messaging/firebase/app_firebase.dart';
import 'package:flutter_webrtc_call_chat_messaging/view_states/home_view_state.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_webrtc.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/data_connection.dart';

class HomeViewModel extends BaseViewModel<HomeViewState> {
  late final AppWebRTC _appWebRTC;
  late final AppFirebase _appFirebase;

  HomeViewModel(BuildContext context, this._appWebRTC, this._appFirebase)
      : super(context, HomeViewState()) {
    _onEventListeners();
  }

  void _onEventListeners() {
    _appWebRTC.on(SocketEvent.Connected.type).listen((event) {
      state.status = "Connected";
      _getPeers();
      notifyListeners();
    });
    _appWebRTC.on(SocketEvent.Disconnected.type).listen((event) {
      state.status = "Disconnected";
      _getPeers();
      notifyListeners();
    });
    _appWebRTC.on(SocketEvent.Error.type).listen((event) {
      state.status = "Error";
      _getPeers();
      notifyListeners();
    });
    _appWebRTC
        .on<DataConnection>(DataConnectionEvent.Connection.type)
        .listen((conn) {
      print("nhan duoc connected");
      conn.on<DataConnection>("open").listen((event) {
        // print("ON OPEN");
        // event.send({"data": 'hello'});
      });
      conn.on("data").listen((event) {
        print("received data: $event");
      });
      conn.on<Uint8List>("binary").listen((event) {
        print("received binary: $event");
      });
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
    conn.on<DataConnection>("open").listen((event) {
      print("ON OPEN");
      event.send({"data": 'hello'});
    });
    conn.on("data").listen((event) {
      print("received data: $event");
    });
    conn.on<Uint8List>("binary").listen((event) {
      print("received binary: $event");
    });
  }

  Future<void> disconnect() async {
    _appWebRTC.disconnect();
  }

  bool isMe(String peer) {
    return _appWebRTC.getCurrentId() == peer;
  }

  @override
  void dispose() {
    _appWebRTC.dispose();
    super.dispose();
  }

  Future<void> login(String displayName) async {
    state.isLoading = true;
    _appFirebase.signInAnonymously(displayName).then((value) {
      state.isLoading = false;
    }).catchError((error) {
      state.isLoading = false;
    });
  }
}
