import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_call_chat_messaging/base/base_stateful.dart';
import 'package:flutter_webrtc_call_chat_messaging/navigation_service.dart';
import 'package:flutter_webrtc_call_chat_messaging/view_models/call_view_model.dart';
import 'package:flutter_webrtc_call_chat_messaging/view_models/chat_view_model.dart';
import 'package:provider/provider.dart';

class CallScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const CallScreen({super.key, required this.arguments});

  @override
  State<StatefulWidget> createState() {
    return _CallScreenState();
  }
}

class _CallScreenState extends BaseStateful<CallScreen, CallViewModel>
    with WidgetsBindingObserver {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    initRenderers();

    if (widget.arguments != null) {
      viewModel.initial(widget.arguments);
    }
  }

  initRenderers() async {
    await _localRenderer.initialize();
    _localRenderer.onFirstFrameRendered = () {
      _localRenderer.srcObject = viewModel.getLocalStream();
    };
    await _remoteRenderer.initialize();
  }

  @override
  AppBar buildAppBarWidget(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      centerTitle: true,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("Calling", style: TextStyle(fontSize: 16)),
          Text(widget.arguments?['displayName'],
              style: const TextStyle(fontSize: 12, color: Colors.grey))
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () {
          viewModel.getBack();
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  @override
  Widget buildBodyWidget(BuildContext context) {
    return Column(
      children: <Widget>[
        Flexible(
          child: Consumer<CallViewModel>(builder: (_, callViewModel, __) {
            return Container(
              decoration:
              BoxDecoration(border: Border.all(color: Colors.blueAccent)),
              child: SizedBox(
                height: double.infinity,
                width: double.infinity,
                child: RTCVideoView(_localRenderer),
              ),
            );
          }),
        ),
        Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        ),
        Consumer<CallViewModel>(builder: (_, callViewModel, __) {
            return Container(
              decoration:
              BoxDecoration(border: Border.all(color: Colors.blueAccent)),
              child: SizedBox(
                height: 100,
                width: 100,
                child: RTCVideoView(_localRenderer, mirror: true),
              ),
            );
        }),
      ],
    );
  }
}
