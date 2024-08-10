import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallViewState {

  bool isOpened = false;

  MediaStream? _localStream;
  MediaStream? _remoteStream;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;



  CallViewState();

  Future<void> initial() async {

  }

  void addLocalStream(MediaStream? stream) {
    _localStream = stream;
  }

  void addRemoteStream(MediaStream? stream) {
    _remoteStream = stream;
  }



}
