import 'package:flutter/material.dart';
import 'package:flutter_webrtc_call_chat_messaging/app_route.dart';
import 'package:flutter_webrtc_call_chat_messaging/firebase/app_firebase.dart';
import 'package:flutter_webrtc_call_chat_messaging/navigation_service.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/app_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


FirebaseMessaging messaging = FirebaseMessaging.instance;


Future<void> _requestPermission() async {
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}





void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  _requestPermission();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MultiProvider(
    providers: <SingleChildWidget>[
      Provider<AppRoute>(create: (_) => AppRoute()),
      Provider<NavigationService>(create: (_) => NavigationService()),
      Provider<AppWebRTC>(create: (_) => AppWebRTC()),
      Provider<AppFirebase>(create: (_) => AppFirebase()),
    ],
    child: const Application(),
  ));
}

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    final AppRoute appRoute = Provider.of<AppRoute>(context, listen: false);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      onGenerateRoute: appRoute.generateRoute,
      initialRoute: AppRoute.splashScreen,
        navigatorKey: NavigationService.navigationKey,
        navigatorObservers: <NavigatorObserver>[
          NavigationService.routeObserver
        ]
    );
  }
}

