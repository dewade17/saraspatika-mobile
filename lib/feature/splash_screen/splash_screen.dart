// lib/src/screens/splash_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saraspatika/core/constanta/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });

    // UI-only: dummy delay selesai splash (tanpa cek login / token)
    _timer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;

      // Placeholder: tidak melakukan navigasi (UI only)
      // Kalau kamu mau tetap ada "next screen" dummy, bisa ganti jadi pushReplacementNamed('/login')
      // Navigator.of(context).pushReplacementNamed('/login');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Splash selesai (UI dummy)')),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.backgroundColor,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/assets/images/logo_saraspatika.png',
                  width: 400,
                  height: 400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
