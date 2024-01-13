import 'package:flutter_webrtc_call_chat_messaging/webrtc/events.dart';

class Message {
  Message({
    required this.type,
    this.src,
    this.payload,
  });

  MessageType type;
  dynamic payload;
  String? src;

  factory Message.fromMap(Map<String, dynamic> json) => Message(
        type: MessageType.values
            .singleWhere((element) => element.type == json["type"]),
        payload: json["payload"],
        src: json["src"],
      );

  Map<String, dynamic> toMap() => {
        "type": type,
        "payload": payload,
        "src": src,
      };
}
