import 'package:flutter/material.dart';
import 'package:flutter_webrtc_call_chat_messaging/base/base_stateful.dart';
import 'package:flutter_webrtc_call_chat_messaging/navigation_service.dart';
import 'package:flutter_webrtc_call_chat_messaging/view_models/chat_view_model.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const ChatScreen({super.key, required this.arguments});

  @override
  State<StatefulWidget> createState() {
    return _ChatScreenState();
  }
}

class _ChatScreenState extends BaseStateful<ChatScreen, ChatViewModel>
    with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();

  void _handleSubmitted(String text) {
    _textController.clear();
    viewModel.send(text);
  }

  @override
  void initState() {
    super.initState();
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
          const Text("Chat", style: TextStyle(fontSize: 16)),
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
          child: Consumer<ChatViewModel>(builder: (_, chatViewModel, __) {
            var messages = chatViewModel.getMessages();
            print("messages: $messages");
            return ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(messages[index]),
                );
              },
            );
          }),
        ),
        const Divider(height: 1.0),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
          ),
          child: _buildTextComposer(),
        ),
        Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        )
      ],
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.inversePrimary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Type a message',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => _handleSubmitted(_textController.text),
            ),
          ],
        ),
      ),
    );
  }
}
