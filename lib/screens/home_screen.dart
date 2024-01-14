import 'package:flutter/material.dart';
import 'package:flutter_webrtc_call_chat_messaging/base/base_stateful.dart';
import 'package:flutter_webrtc_call_chat_messaging/view_models/home_view_model.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends BaseStateful<HomeScreen, HomeViewModel> {
  @override
  AppBar buildAppBarWidget(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: const Text("Home"),
    );
  }

  @override
  Widget buildBodyWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Consumer<HomeViewModel>(builder: (_, homeViewModel, __) {
            return SizedBox(
              height: 200.0,
              child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: homeViewModel.state.peers.length,
                  itemBuilder: (BuildContext context, int index) {
                    var item = homeViewModel.state.peers[index];
                    var isMe = homeViewModel.isMe(item);
                    var color = Colors.amber;
                    var name = "Client: $item";
                    if(isMe){
                      color = Colors.red;
                      name = "Me: $item";
                    }
                    return Container(
                      height: 50,
                      color: color,
                      child: TextButton(
                          onPressed: () {
                            viewModel.connect(item);
                          },
                          child: Center(
                              child: Text(name))),
                    );
                  }),
            );
          }),
          Consumer<HomeViewModel>(builder: (_, homeViewModel, __) {
            return Text(
              homeViewModel.state.getStatus(),
              style: Theme.of(context).textTheme.headlineMedium,
            );
          }),
          TextButton(
              onPressed: () {
                viewModel.start();
              },
              child: const Text('Connect')),
          TextButton(
              onPressed: () {
                viewModel.disconnect();
              },
              child: const Text('Disconnect'))
        ],
      ),
    );
  }
}
