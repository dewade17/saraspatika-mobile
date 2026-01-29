import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
// Import provider bisa dihapus dulu jika tidak dipakai
// import 'package:provider/provider.dart';
import 'package:saraspatika/feature/home/screen/home_screen.dart';
import 'package:saraspatika/feature/splash_screen/splash_screen.dart';

void main() async {
  // 3. Pastikan binding Flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Inisialisasi data format tanggal untuk Indonesia ('id_ID')
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Hapus MultiProvider dan langsung return MaterialApp
    return MaterialApp(
      title: 'bank_sampah App',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {'/home-screen': (context) => const HomeScreen()},
    );
  }
}
