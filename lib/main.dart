import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/feature/auth_wrapper.dart';
import 'package:saraspatika/feature/home/screen/home_screen.dart';
import 'package:saraspatika/feature/login/data/provider/auth_provider.dart';
import 'package:saraspatika/feature/login/screen/login_screen.dart';
import 'package:saraspatika/feature/reset_password/data/provider/reset_password_provider.dart';
import 'package:saraspatika/feature/reset_password/screen/reset_password.dart';
import 'package:saraspatika/feature/splash_screen/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ResetPasswordProvider>(
          create: (_) => ResetPasswordProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'bank_sampah App',
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/reset-password': (context) => const ResetPassword(),
          '/home-screen': (context) => const AuthWrapper(child: HomeScreen()),
        },
      ),
    );
  }
}
