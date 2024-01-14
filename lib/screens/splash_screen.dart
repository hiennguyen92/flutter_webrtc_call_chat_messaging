import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_webrtc_call_chat_messaging/app_route.dart';
import 'package:flutter_webrtc_call_chat_messaging/navigation_service.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SplashScreenState();
  }
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this, value: 0.1);
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.bounceInOut);
    _controller.forward();
    SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
      Future.delayed(const Duration(seconds: 2), () {
        Provider.of<NavigationService>(context, listen: false)
            .pushNamedAndRemoveUntil(AppRoute.homeScreen, args: {'isWithoutAnimation': true});
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
      child: ScaleTransition(
        scale: _animation,
        alignment: Alignment.center,
        child: const Image(image: AssetImage('assets/images/logo.png')),
      ),
    );
  }
}