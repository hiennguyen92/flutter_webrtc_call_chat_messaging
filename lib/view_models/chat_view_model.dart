import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc_call_chat_messaging/base/base_view_model.dart';
import 'package:flutter_webrtc_call_chat_messaging/firebase/app_firebase.dart';
import 'package:flutter_webrtc_call_chat_messaging/navigation_service.dart';
import 'package:flutter_webrtc_call_chat_messaging/view_states/chat_view_state.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_webrtc.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/data_connection.dart';

class ChatViewModel extends BaseViewModel<ChatViewState> {
  late final NavigationService _navigationService;
  late final AppWebRTC _appWebRTC;
  late final AppFirebase _appFirebase;

  DataConnection? _dataConnection;

  ChatViewModel(BuildContext context, this._navigationService, this._appWebRTC,
      this._appFirebase)
      : super(context, ChatViewState());

  Future<void> initial(dynamic userInfo) async {
    if (_appFirebase.isLogged()) {
      if (_appWebRTC.isConnected()) {
        print("userInfo: $userInfo");
        setupDataConnection(userInfo?['uuid']);
        state.initial(userInfo['messages']);
      }
    }
  }

  Future<void> send(String text) async {
    var message = await _dataConnection?.send(text);
    state.addMessage(message);
    notifyListeners();
  }

  List<dynamic> getMessages() {
    return state.messages;
  }

  Future<void> setupDataConnection(String peer) async {
    _dataConnection = _appWebRTC.connectData(peer);
    _onEventListeners();
  }

  void _onEventListeners() {
    _dataConnection
        ?.on<DataConnection>(DataConnectionEvent.Open.type)
        .listen((event) {
      if (mounted) {
        print("ON OPEN");
      }
    });
    _dataConnection?.on<dynamic>(DataConnectionEvent.Data.type).listen((event) {
      if (mounted) {
        state.addMessage(event);
        print("received data chatView: $event");
        notifyListeners();
      }
    });
    _dataConnection
        ?.on<dynamic>(DataConnectionEvent.Binary.type)
        .listen((event) {
      if (mounted) {
        print("received binary chatView: $event");
      }
    });
  }

  Future<void> getBack() async {
    _navigationService.goBack();
  }
}
