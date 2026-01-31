import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/feature/login/data/provider/auth_provider.dart';
import 'package:saraspatika/feature/login/screen/login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Future<bool> _restoreFuture;

  @override
  void initState() {
    super.initState();
    _restoreFuture = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _restoreFuture,
      builder: (context, snapshot) {
        final s = snapshot.connectionState;
        if (s == ConnectionState.waiting || s == ConnectionState.active) {
          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(
              child: Image.asset(
                'lib/assets/images/logo_saraspatika.png',
                width: 400,
                height: 400,
              ),
            ),
          );
        }

        final isAuthenticated =
            (snapshot.data ?? false) &&
            Provider.of<AuthProvider>(context, listen: false).isAuthenticated;

        if (isAuthenticated) {
          return widget.child;
        }

        return const LoginScreen();
      },
    );
  }
}
