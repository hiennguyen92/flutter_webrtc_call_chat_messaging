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
          const Text(
            'You have pushed the button this many times:',
          ),
          Consumer<HomeViewModel>(builder: (_, homeViewModel, __) {
            return Text(
              homeViewModel.state.getStatus(),
              style: Theme.of(context).textTheme.headlineMedium,
            );
          }),
          TextButton(
              onPressed: () {
                  viewModel.connect();
              },
              child: const Text('Connect')
          ),
          TextButton(
              onPressed: () {
                viewModel.disconnect();
              },
              child: const Text('Disconnect')
          )
        ],
      ),
    );
  }



  
}