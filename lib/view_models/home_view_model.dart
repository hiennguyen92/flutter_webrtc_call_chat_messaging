import 'package:flutter/material.dart';
import 'package:flutter_webrtc_call_chat_messaging/base/base_view_model.dart';
import 'package:flutter_webrtc_call_chat_messaging/view_states/home_view_state.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_webrtc.dart';

class HomeViewModel extends BaseViewModel<HomeViewState> {

  late final AppWebRTC _appWebRTC;

  HomeViewModel(BuildContext context, this._appWebRTC): super(context, HomeViewState());


  Future<void> connect() async {
    _appWebRTC.on(AppEvent.Connected.type).listen((event) {
      state.status = "Connected";
      print("Vao day");
      notifyListeners();
    });
    _appWebRTC.on(AppEvent.Disconnected.type).listen((event) {
      state.status = "Disconnected";
      notifyListeners();
    });
    _appWebRTC.on(AppEvent.Error.type).listen((event) {
      state.status = "Error";
      notifyListeners();
    });
    _appWebRTC.start();
  }

  Future<void> disconnect() async {
    _appWebRTC.disconnect();
  }


}