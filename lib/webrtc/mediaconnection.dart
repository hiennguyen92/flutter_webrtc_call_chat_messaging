

import 'package:flutter_webrtc_call_chat_messaging/webrtc/baseconnecttion.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/message.dart';

class MediaConnection extends BaseConnection {

  MediaConnection(super.peer, super.provider, super.options);

  @override
  void dispose() {
    // TODO: implement dispose
  }

  @override
  void handleMessage(Message message) {
    // TODO: implement handleMessage
  }


}