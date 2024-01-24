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

class _HomeScreenState extends BaseStateful<HomeScreen, HomeViewModel>
    with WidgetsBindingObserver {
  Future? _dialogLogin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDialogLogin());
    WidgetsBinding.instance.addObserver(this);
    viewModel.initial();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _showDialogLogin();
    }
  }

  @override
  AppBar buildAppBarWidget(BuildContext context) {
    return AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Home", style: TextStyle(fontSize: 16)),
            Consumer<HomeViewModel>(builder: (_, homeViewModel, __) {
              return Text(homeViewModel.getStatus(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey));
            })
          ],
        ),
        actions: [
          Consumer<HomeViewModel>(builder: (_, homeViewModel, __) {
            if (homeViewModel.isLogged()) {
              return IconButton(
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
                onPressed: () {
                  _showLogoutDialog();
                },
              );
            } else {
              return const SizedBox.shrink();
            }
          })
        ]);
  }

  void _showLogoutDialog() {
    if (!viewModel.isLogged()) return;

    showDialog(
        context: context,
        builder: (_) => ChangeNotifierProvider.value(
            value: viewModel,
            child: AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('Cancel'),
                ),
                Consumer<HomeViewModel>(builder: (_, homeViewModel, __) {
                  var textLogout = homeViewModel.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator())
                      : const Text("Logout");
                  return TextButton(
                    onPressed: () {
                      viewModel.logout(success: () {
                        _showDialogLogin();
                      }, fail: (error) {
                        _showDialogLogin();
                      });
                    },
                    child: textLogout,
                  );
                })
              ],
            )));
  }

  Future _showDialogLogin() async {
    if (_dialogLogin != null) return;

    if (viewModel.isLogged()) return;

    _dialogLogin = showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ChangeNotifierProvider.value(
            value: viewModel,
            child: AlertDialog(
              title: const Text("Welcome"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      textCapitalization: TextCapitalization.words,
                      onChanged: (text) {
                        viewModel.setDisplayName(text);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Enter Name',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Consumer<HomeViewModel>(builder: (_, homeViewModel, __) {
                  var textLogin = homeViewModel.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator())
                      : const Text("Login");
                  return TextButton(
                    onPressed: (homeViewModel.state.hasDisplayName() &&
                            !homeViewModel.isLoading)
                        ? () {
                            homeViewModel.login(
                                success: () {
                                  _dialogLogin = null;
                                },
                                fail: (error) {});
                          }
                        : null,
                    child: textLogin,
                  );
                })
              ],
            )));
    return _dialogLogin;
  }

  @override
  Widget buildBodyWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Consumer<HomeViewModel>(builder: (_, homeViewModel, __) {
            var currentUser = homeViewModel.getCurrentUserInfo();
            if (currentUser == null) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(10.0),
              height: 80,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueAccent)),
                    child: SizedBox(
                      height: 50,
                      width: 50,
                      child: Image.asset('assets/icons/avatar.jpg'),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.circle, color: Colors.green, size: 15),
                  const SizedBox(width: 5),
                  Text(currentUser['displayName'],
                      style: const TextStyle(fontSize: 18)),
                ],
              ),
            );
          }),
          Consumer<HomeViewModel>(builder: (_, homeViewModel, __) {
            var usersClient = homeViewModel.getUsersClient();
            return Expanded(
                child: Container(
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.blueAccent)),
              child: usersClient.isEmpty
                  ? const Center(child: Text('No Data'))
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: usersClient.length,
                      itemBuilder: (BuildContext context, int index) {
                        var item = usersClient[index];
                        var colorStatus =
                            item['isConnected'] ? Colors.green : Colors.grey;
                        return SizedBox(
                          height: 40,
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.blueAccent)),
                                child: SizedBox(
                                  height: 35,
                                  width: 35,
                                  child: Image.asset('assets/icons/avatar.jpg'),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(Icons.circle, color: colorStatus, size: 15),
                              const SizedBox(width: 5),
                              Text(item['displayName'],
                                  style: const TextStyle(fontSize: 12)),
                              Expanded(
                                  child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: IconButton(
                                      icon: const Icon(Icons.message,
                                          color: Colors.green),
                                      onPressed: () {
                                        viewModel.goToChatScreen(params: item);
                                      },
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  SizedBox(
                                    height: 40,
                                    width: 40,
                                    child: IconButton(
                                      icon: const Icon(Icons.video_call,
                                          color: Colors.green),
                                      onPressed: () {},
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  )
                                ],
                              ))
                            ],
                          ),
                        );
                      }),
            ));
          }),
        ],
      ),
    );
  }
}
