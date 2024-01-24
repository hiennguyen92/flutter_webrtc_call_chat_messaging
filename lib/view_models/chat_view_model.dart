import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc_call_chat_messaging/base/base_view_model.dart';
import 'package:flutter_webrtc_call_chat_messaging/firebase/app_firebase.dart';
import 'package:flutter_webrtc_call_chat_messaging/navigation_service.dart';
import 'package:flutter_webrtc_call_chat_messaging/view_states/chat_view_state.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_webrtc.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/data_connection.dart';

class ChatViewModel extends BaseViewModel<ChatViewState> {
  late final NavigationService _navigationService;
  late final AppWebRTC _appWebRTC;
  late final AppFirebase _appFirebase;

  ChatViewModel(BuildContext context, this._navigationService, this._appWebRTC,
      this._appFirebase)
      : super(context, ChatViewState());



  Future<void> initial(dynamic userInfo) async {
    if (_appFirebase.isLogged()) {
      if (_appWebRTC.isConnected()) {
        print("userInfo: $userInfo");
        chat(userInfo?['uuid']);
      }
    }
  }

  void send(String text) {
    state.send(text);
    state.dataConnection?.send(text);
    notifyListeners();
  }

  List<String> getMessages() {
    return state.messages;
  }

  Future<void> chat(String peer) async {
    var connection = _appWebRTC.connect(peer);
    state.setDataConnection(connection);
  }

  void _onEventListeners() {
    state.dataConnection?.on<DataConnection>("open").listen((event) {
      if (mounted) {
        print("ON OPEN");
        //event.send({"data": 'hello'});
      }
    });
    state.dataConnection?.on("data").listen((event) {
      if (mounted) {
        print("received data: $event");
      }
    });
    state.dataConnection?.on<Uint8List>("binary").listen((event) {
      if (mounted) {
        print("received binary: $event");
      }
    });
  }

  Future<void> getBack() async {
    _navigationService.goBack();
  }
}
