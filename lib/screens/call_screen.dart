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
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    if (widget.arguments != null) {
      viewModel.initial(widget.arguments);
    }

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
  Widget buildBodyWidget(BuildContext context) {
    return Column(
      children: <Widget>[
        Flexible(
          child: Consumer<CallViewModel>(builder: (_, callViewModel, __) {
            //var messages = chatViewModel.getMessages();
            //print("messages: $messages");
            return Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent)),
              child: SizedBox(
                height: double.infinity,
                width: double.infinity,
                child: RTCVideoView(
                  _localRenderer,
                ),
              ),
            );
          }),
        ),
        Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        )
      ],
    );
  }

}
