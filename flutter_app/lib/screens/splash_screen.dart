import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'otp_login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.easeIn));
    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final token = await ApiService().getToken();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => token != null ? const HomeScreen() : const OtpLoginScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: DuoColors.splashGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: DuoColors.brandGradient,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(color: DuoColors.violet.withOpacity(0.5), blurRadius: 40, spreadRadius: 4),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 52),
                      Positioned(
                        right: 22,
                        bottom: 22,
                        child: Icon(Icons.bolt_rounded, color: Colors.white.withOpacity(0.95), size: 26),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    Text(
                      'DuoChat',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect Instantly, Chat Seamlessly',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.65)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              FadeTransition(
                opacity: _fade,
                child: const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: DuoColors.cyan),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
