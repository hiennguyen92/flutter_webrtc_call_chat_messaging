import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc_call_chat_messaging/app_route.dart';
import 'package:flutter_webrtc_call_chat_messaging/base/base_view_model.dart';
import 'package:flutter_webrtc_call_chat_messaging/firebase/app_firebase.dart';
import 'package:flutter_webrtc_call_chat_messaging/navigation_service.dart';
import 'package:flutter_webrtc_call_chat_messaging/view_states/home_view_state.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_events.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_webrtc.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/data_connection.dart';

class HomeViewModel extends BaseViewModel<HomeViewState> {
  late final NavigationService _navigationService;
  late final AppWebRTC _appWebRTC;
  late final AppFirebase _appFirebase;

  HomeViewModel(BuildContext context, this._navigationService, this._appWebRTC,
      this._appFirebase)
      : super(context, HomeViewState()) {
    _onEventListeners();
  }

  void _onEventListeners() {
    _appWebRTC.on(SocketEvent.Connected.type).listen((event) async {
      if (mounted) {
        state.status = "Connected";
        await getUsers();
        notifyListeners();
      }
    });
    _appWebRTC.on(SocketEvent.Disconnected.type).listen((event) async {
      if (mounted) {
        state.status = "Disconnected";
        await getUsers();
        notifyListeners();
      }
    });
    _appWebRTC.on(SocketEvent.Error.type).listen((event) async {
      if (mounted) {
        state.status = "Error";
        await getUsers();
        notifyListeners();
      }
    });
    _appWebRTC
        .on<DataConnection>(DataConnectionEvent.Connection.type)
        .listen((conn) {
      if (mounted) {
        print("nhan duoc connected");
        conn.on<DataConnection>(DataConnectionEvent.Open.type).listen((event) {
          print("DataConnection: OPEN");
        });
        conn
            .on<DataConnection>(DataConnectionEvent.Connecting.type)
            .listen((event) {
          //TODO:
          print("DataConnection: Connecting");
        });
        conn
            .on<DataConnection>(DataConnectionEvent.Closing.type)
            .listen((event) {
          //TODO:
          print("DataConnection: Closing");
        });
        conn
            .on<DataConnection>(DataConnectionEvent.Closed.type)
            .listen((event) {
          print("DataConnection: Closed");
        });
        conn.on<dynamic>(DataConnectionEvent.Data.type).listen((event) {
          print("received data: $event");
          var peer = event['peer'];
          if (peer != state.peerCurrent) {
            state.addMessage(event['peer'], event);
            notifyListeners();
          }
        });
        conn.on<dynamic>(DataConnectionEvent.Binary.type).listen((event) {
          print("received binary: $event");
        });
      }
    });
  }

  Future<void> initial() async {
    if (isLogged()) {
      if (!_appWebRTC.isConnected()) {
        Map<String, dynamic>? userInfo =
            await _appFirebase.getCurrentUserInfo();
        start(userInfo?['uuid']);
      }
    }
  }

  dynamic getCurrentUserInfo() {
    return _appFirebase.currentUserInfo;
  }

  Future<List<String>> _getPeers() async {
    try {
      List<String> peers = await _appWebRTC.api.getPeers();
      state.peers = peers;
      return peers;
    } catch (error) {
      throw Exception("getPeers error: $error");
    }
  }

  Future<void> start([String? userId]) async {
    _appWebRTC.start(userId);
  }

  Future<void> disconnect() async {
    _appWebRTC.disconnect();
  }

  bool isMe(String peer) {
    return _appWebRTC.getCurrentId() == peer;
  }

  String getStatus() {
    return state.getStatus();
  }

  Future<void> setDisplayName(String? name) async {
    if (name != null) {
      state.displayName = name;
    }
    notifyListeners();
  }

  Future<void> login(
      {void Function()? success, void Function(dynamic)? fail}) async {
    isLoading = true;
    _appFirebase.signInAnonymously(state.displayName!).then((value) async {
      Map<String, dynamic>? userInfo = await _appFirebase.getCurrentUserInfo();
      start(userInfo?['uuid']);
      isLoading = false;
      _navigationService.goBack();
      success?.call();
    }).catchError((error) {
      print("$error");
      isLoading = false;
      fail?.call(error);
    });
  }

  bool isLogged() {
    return _appFirebase.isLogged();
  }

  Future<void> logout(
      {void Function()? success, void Function(dynamic)? fail}) async {
    isLoading = true;
    await _appFirebase.deleteUserInfo();
    await _appFirebase.getCurrentUser()?.delete();
    _appFirebase.logout().then((value) {
      _appFirebase.cleanUp();
      _appWebRTC.disconnect();
      isLoading = false;
      _navigationService.goBack();
      success?.call();
    }).catchError((error) {
      isLoading = false;
      fail?.call(error);
    });
  }

  Future<List<dynamic>> getUsers() async {
    try {
      List<String> peers = await _getPeers();
      List<dynamic> users = await _appFirebase.getUsers();

      for (Map<String, dynamic> user in users) {
        user["isConnected"] = peers.contains(user['uuid']);
        user['isMe'] = isMe(user['uuid']);
      }
      state.peers = peers;
      state.users = users;
      return users;
    } catch (error) {
      throw Exception("getUsers error: $error");
    }
  }

  List<dynamic> getUsersClient() {
    var usersClient = state.users.where((user) => !isMe(user['uuid'])).toList();

    return usersClient;
  }

  List<dynamic> getMessagesByPeer(String peer) {
    return state.getMessagesByPeer(peer);
  }

  int getCountMessagesByPeer(String peer) {
    return getMessagesByPeer(peer).length;
  }

  void readByPeer(String peer) {
    state.readByPeer(peer);
    notifyListeners();
  }

  void setCurrentPeer(String? peer) {
    state.peerCurrent = peer;
    notifyListeners();
  }

  void goToChatScreen({dynamic params}) {
    var peer = params['uuid'];
    setCurrentPeer(peer);
    var messages = getMessagesByPeer(peer);
    params['messages'] = List.from(messages);
    readByPeer(peer);
    _navigationService
        .pushNamed(AppRoute.chatScreen, args: params)
        .then((value) {
      setCurrentPeer(null);
    });
  }

  void gotoVideoCall({dynamic params}) {
    var peer = params['uuid'];
    print('peer call ${peer}');
    _navigationService
        .pushNamed(AppRoute.callScreen, args: params)
        .then((value) {
      //setCurrentPeer(null);
    });
  }
}
