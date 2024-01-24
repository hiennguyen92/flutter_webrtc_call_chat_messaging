import 'package:flutter_webrtc_call_chat_messaging/webrtc/data_connection.dart';

class ChatViewState {

  DataConnection? _dataConnection;
  bool isOpened = false;

  final List<String> _messages = [];

  ChatViewState();

  void send(String text) {
    _messages.insert(0, text);
  }

  List<String> get messages => _messages;


  void setDataConnection(DataConnection? dataConnection) {
    _dataConnection = dataConnection;
  }

  DataConnection? get dataConnection => _dataConnection;





}
