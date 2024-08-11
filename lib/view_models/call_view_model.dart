import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_call_chat_messaging/base/base_view_model.dart';
import 'package:flutter_webrtc_call_chat_messaging/firebase/app_firebase.dart';
import 'package:flutter_webrtc_call_chat_messaging/navigation_service.dart';
import 'package:flutter_webrtc_call_chat_messaging/view_states/call_view_state.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_webrtc.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/media_connection.dart';

class CallViewModel extends BaseViewModel<CallViewState> {
  late final NavigationService _navigationService;
  late final AppWebRTC _appWebRTC;
  late final AppFirebase _appFirebase;

  MediaConnection? _mediaConnection;

  CallViewModel(BuildContext context, this._navigationService, this._appWebRTC,
      this._appFirebase)
      : super(context, CallViewState());

  Future<void> initial(dynamic userInfo) async {
    if (_appFirebase.isLogged()) {
      if (_appWebRTC.isConnected()) {
        print("userInfo: $userInfo");
        setupMediaConnection(userInfo?['uuid']);
        state.initial();
      }
    }
  }

  Future<void> setupMediaConnection(String peer) async {
    _mediaConnection = _appWebRTC.connectMedia(peer);
    _onEventListeners();
  }

  void _onEventListeners() {
    _mediaConnection
        ?.on<MediaConnection>(MediaConnectionEvent.Connection.type)
        .listen((event) {
      if (mounted) {
        print("ON CONNECTION MEDIA");
        state.addLocalStream(event.localStream);
        notifyListeners();
      }
    });
    _mediaConnection
        ?.on<MediaConnection>(MediaConnectionEvent.Open.type)
        .listen((event) {
      if (mounted) {
        print("ON OPEN MEDIA");
      }
    });
    _mediaConnection?.on<MediaConnection>(MediaConnectionEvent.Streaming.type).listen((event) {
      if (mounted) {
        print("STREAM");
        state.addRemoteStream(event.remoteStream);
        notifyListeners();
      }
    });
  }


  MediaStream? getLocalStream() {
    return state.localStream;
  }

  MediaStream? getRemoteStream() {
    return state.remoteStream;
  }

  Future<void> getBack() async {
    _appWebRTC.removeConnection(_mediaConnection);
    _mediaConnection?.dispose();
    _navigationService.goBack();
  }
}
