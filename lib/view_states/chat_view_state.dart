import 'package:flutter_webrtc_call_chat_messaging/webrtc/data_connection.dart';

class ChatViewState {

  bool isOpened = false;

  late List<dynamic> _messages = [];

  ChatViewState();

  Future<void> initial(List<dynamic> messages) async {
    _messages = messages;
  }


  List<dynamic> get messages => _messages;

  void addMessage(dynamic data) {
    _messages.insert(0, data);
  }

}
