import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/feature/absensi/data/provider/offline_provider.dart';
import 'package:saraspatika/feature/absensi/screen/absensi_kepulangan/absensi_kepulangan_screen.dart';
import 'package:saraspatika/feature/agenda/data/provider/agenda_provider.dart';
import 'package:saraspatika/feature/agenda/screens/agenda_home_screen.dart';
import 'package:saraspatika/feature/home/data/provider/history_kehadiran_provider.dart';
import 'package:saraspatika/feature/home/screen/view_all/view_all_history.dart';
import 'package:saraspatika/feature/izin_sakit_cuti/data/provider/pengajuan_absensi_provider.dart';
import 'package:saraspatika/feature/registrasi_wajah/data/provider/enroll_face_provider.dart';
import 'package:saraspatika/feature/absensi/data/provider/get_face_provider.dart';
import 'package:saraspatika/feature/absensi/screen/absensi_kedatangan/absensi_kedatangan_screen.dart';
import 'package:saraspatika/feature/auth_wrapper.dart';
import 'package:saraspatika/feature/home/screen/home_screen.dart';
import 'package:saraspatika/feature/login/data/provider/auth_provider.dart';
import 'package:saraspatika/feature/login/screen/login_screen.dart';
import 'package:saraspatika/feature/profile/data/provider/user_profile_provider.dart';
import 'package:saraspatika/feature/registrasi_wajah/screen/registrasi_wajah.dart';
import 'package:saraspatika/feature/request_wajah/data/provider/request_wajah_provider.dart';
import 'package:saraspatika/feature/reset_password/data/provider/reset_password_provider.dart';
import 'package:saraspatika/feature/reset_password/screen/reset_password.dart';
import 'package:saraspatika/feature/splash_screen/splash_screen.dart';
import 'package:saraspatika/feature/absensi/data/provider/absensi_provider.dart';
import 'package:saraspatika/feature/absensi/data/provider/jadwal_shift_provider.dart';
import 'package:saraspatika/feature/absensi/data/provider/lokasi_provider.dart';

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
        ChangeNotifierProvider<GetFaceProvider>(
          create: (_) => GetFaceProvider(),
        ),
        ChangeNotifierProvider<EnrollFaceProvider>(
          create: (_) => EnrollFaceProvider(),
        ),
        ChangeNotifierProvider<ResetPasswordProvider>(
          create: (_) => ResetPasswordProvider(),
        ),
        ChangeNotifierProvider<UserProfileProvider>(
          create: (_) => UserProfileProvider(),
        ),
        ChangeNotifierProvider<AbsensiProvider>(
          create: (_) => AbsensiProvider(),
        ),
        ChangeNotifierProvider<LokasiProvider>(create: (_) => LokasiProvider()),
        ChangeNotifierProvider<JadwalShiftProvider>(
          create: (_) => JadwalShiftProvider(),
        ),
        ChangeNotifierProvider<RequestWajahProvider>(
          create: (_) => RequestWajahProvider(),
        ),
        ChangeNotifierProvider<OfflineProvider>(
          create: (_) => OfflineProvider(),
        ),
        ChangeNotifierProvider<HistoryKehadiranProvider>(
          create: (_) => HistoryKehadiranProvider(),
        ),
        ChangeNotifierProvider<PengajuanAbsensiProvider>(
          create: (_) => PengajuanAbsensiProvider(),
        ),
        ChangeNotifierProvider<AgendaProvider>(create: (_) => AgendaProvider()),
      ],
      child: MaterialApp(
        title: 'Saraspatika',
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/reset-password': (context) => const ResetPassword(),
          '/registrasi-wajah': (context) => const RegistrasiWajah(),
          '/home-screen': (context) => const AuthWrapper(child: HomeScreen()),
          '/absensi-kedatangan': (context) => const AbsensiKedatanganScreen(),
          '/absensi-kepulangan': (context) => const AbsensiKepulanganScreen(),
          '/data-absensi': (context) => const ViewAllHistory(),
          '/screen-agenda': (context) => const AgendaHomeScreen(),
        },
      ),
    );
  }
}
