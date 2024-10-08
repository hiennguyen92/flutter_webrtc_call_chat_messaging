import 'package:flutter/material.dart';
import 'package:flutter_webrtc_call_chat_messaging/firebase/app_firebase.dart';
import 'package:flutter_webrtc_call_chat_messaging/navigation_service.dart';
import 'package:flutter_webrtc_call_chat_messaging/screens/call_screen.dart';
import 'package:flutter_webrtc_call_chat_messaging/screens/chat_screen.dart';
import 'package:flutter_webrtc_call_chat_messaging/screens/home_screen.dart';
import 'package:flutter_webrtc_call_chat_messaging/screens/splash_screen.dart';
import 'package:flutter_webrtc_call_chat_messaging/view_models/call_view_model.dart';
import 'package:flutter_webrtc_call_chat_messaging/view_models/chat_view_model.dart';
import 'package:flutter_webrtc_call_chat_messaging/view_models/home_view_model.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_webrtc.dart';
import 'package:provider/provider.dart';

class AppRoute {
  static const splashScreen = '/splashScreen';
  static const homeScreen = '/homeScreen';
  static const chatScreen = '/chatScreen';
  static const callScreen = '/callScreen';

  static final AppRoute _instance = AppRoute._private();
  factory AppRoute() {
    return _instance;
  }
  AppRoute._private();

  static AppRoute get instance => _instance;

  static Widget createProvider<P extends ChangeNotifier>(
    P Function(BuildContext context) provider,
    Widget child,
  ) {
    return ChangeNotifierProvider<P>(
      create: provider,
      builder: (_, __) {
        return child;
      },
    );
  }

  Route<Object>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashScreen:
        return AppPageRoute(builder: (_) => const SplashScreen());
      case homeScreen:
        Duration? duration;
        if (settings.arguments != null) {
          final args = settings.arguments as Map<String, dynamic>;
          if (args['isWithoutAnimation'] != null && (args['isWithoutAnimation'] as bool)) {
            duration = Duration.zero;
          }
        }
        return AppPageRoute(
            appTransitionDuration: duration,
            appSettings: settings,
            builder: (_) => ChangeNotifierProvider(
                create: (context) => HomeViewModel(
                    context,
                    Provider.of<NavigationService>(context, listen: false),
                    Provider.of<AppWebRTC>(context, listen: false),
                    Provider.of<AppFirebase>(context, listen: false)),
                builder: (_, __) => const HomeScreen()));
      case chatScreen:
        Duration? duration;
        if (settings.arguments != null) {
          final args = settings.arguments as Map<String, dynamic>;
          if (args['isWithoutAnimation'] != null && (args['isWithoutAnimation'] as bool)) {
            duration = Duration.zero;
          }
        }
        var arguments = settings.arguments as Map<String, dynamic>;
        return AppPageRoute(
            appTransitionDuration: duration,
            appSettings: settings,
            builder: (_) => ChangeNotifierProvider(
                create: (context) => ChatViewModel(
                    context,
                    Provider.of<NavigationService>(context, listen: false),
                    Provider.of<AppWebRTC>(context, listen: false),
                    Provider.of<AppFirebase>(context, listen: false)),
                builder: (_, __) => ChatScreen(arguments: arguments)));
      case callScreen:
        Duration? duration;
        if (settings.arguments != null) {
          final args = settings.arguments as Map<String, dynamic>;
          if (args['isWithoutAnimation'] != null && (args['isWithoutAnimation'] as bool)) {
            duration = Duration.zero;
          }
        }
        var arguments = settings.arguments as Map<String, dynamic>;
        return AppPageRoute(
            appTransitionDuration: duration,
            appSettings: settings,
            builder: (_) => ChangeNotifierProvider(
                create: (context) => CallViewModel(
                    context,
                    Provider.of<NavigationService>(context, listen: false),
                    Provider.of<AppWebRTC>(context, listen: false),
                    Provider.of<AppFirebase>(context, listen: false)),
                builder: (_, __) => CallScreen(arguments: arguments)));
      default:
        return null;
    }
  }
}

class AppPageRoute extends MaterialPageRoute<Object> {
  Duration? appTransitionDuration;

  RouteSettings? appSettings;

  AppPageRoute(
      {required WidgetBuilder builder,
      this.appSettings,
      this.appTransitionDuration})
      : super(builder: builder);

  @override
  Duration get transitionDuration =>
      appTransitionDuration ?? super.transitionDuration;

  @override
  RouteSettings get settings => appSettings ?? super.settings;
}
