import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/feature/absensi/data/provider/get_face_provider.dart';
import 'package:saraspatika/feature/login/data/provider/auth_provider.dart';
import 'package:saraspatika/feature/login/screen/login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

enum _AuthNextRoute { login, home, registrasi, error }

class _GuardDecision {
  final _AuthNextRoute next;
  final String? message;

  const _GuardDecision(this.next, {this.message});
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<_GuardDecision> _guardFuture;
  bool _didRedirect = false;

  @override
  void initState() {
    super.initState();
    _guardFuture = Future<void>.delayed(Duration.zero).then((_) => _runGuard());
  }

  Future<_GuardDecision> _runGuard() async {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      final restored = await authProvider.restoreSession();
      final isAuthenticated = restored && authProvider.isAuthenticated;

      if (!isAuthenticated) {
        return const _GuardDecision(_AuthNextRoute.login);
      }
    }

    var userId = (authProvider.me?.idUser ?? '').trim();
    if (userId.isEmpty) {
      try {
        userId = (await ApiService().getUserId() ?? '').trim();
      } catch (_) {}
    }

    if (userId.isEmpty) {
      return const _GuardDecision(
        _AuthNextRoute.error,
        message: 'ID user tidak ditemukan.',
      );
    }

    final getFaceProvider = context.read<GetFaceProvider>();

    try {
      final face = await getFaceProvider.fetchFaceData(userId, maxRetries: 5);
      final hasFace = (face != null && face.items.isNotEmpty);
      if (!hasFace) {
        return const _GuardDecision(_AuthNextRoute.registrasi);
      }
      return const _GuardDecision(_AuthNextRoute.home);
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        return const _GuardDecision(_AuthNextRoute.registrasi);
      }

      final msg = getFaceProvider.errorMessage ?? 'Gagal mengambil data wajah.';
      return _GuardDecision(_AuthNextRoute.error, message: msg);
    }
  }

  Widget _loadingScaffold() {
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

  void _redirectOnce(String routeName) {
    if (_didRedirect) return;
    _didRedirect = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_GuardDecision>(
      future: _guardFuture,
      builder: (context, snapshot) {
        final s = snapshot.connectionState;
        if (s == ConnectionState.waiting || s == ConnectionState.active) {
          return _loadingScaffold();
        }

        final decision = snapshot.data;

        if (decision == null) {
          return const LoginScreen();
        }

        switch (decision.next) {
          case _AuthNextRoute.home:
            return widget.child;

          case _AuthNextRoute.registrasi:
            _redirectOnce('/registrasi-wajah');
            return _loadingScaffold();

          case _AuthNextRoute.login:
            _redirectOnce('/login');
            return _loadingScaffold();

          case _AuthNextRoute.error:
            _redirectOnce('/login');
            return _loadingScaffold();
        }
      },
    );
  }
}
