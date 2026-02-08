import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/feature/home/screen/widget/button_app_bar.dart';
import 'package:saraspatika/feature/home/screen/widget/content_riwayat_absensi.dart';
import 'package:saraspatika/feature/home/screen/widget/header_user_appbar.dart';
import 'package:saraspatika/feature/izin_sakit_cuti/screen/izin_sakit_cuti.dart';
import 'package:saraspatika/feature/profile/data/provider/user_profile_provider.dart';
import 'package:saraspatika/feature/profile/screen/profile_screen.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:saraspatika/feature/absensi/data/provider/offline_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreenContent(),
    IzinSakitCuti(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        items: const [
          Icon(Icons.home, color: AppColors.backgroundColor),
          Icon(Icons.notifications, color: AppColors.backgroundColor),
          Icon(Icons.person, color: AppColors.backgroundColor),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.transparent,
        color: AppColors.primaryColor,
        buttonBackgroundColor: AppColors.primaryColor,
      ),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // Panggil fetchCurrentUser agar data profil terbaru selalu diambil saat home dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().fetchCurrentUser();
      final offlineProvider = context.read<OfflineProvider>();
      offlineProvider.syncPendingData();
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
        results,
      ) {
        final hasInternet = !results.contains(ConnectivityResult.none);
        if (hasInternet) {
          offlineProvider.syncPendingData();
        }
      });
    });
  }

  Future<void> _profileRefresh() async {
    await context.read<UserProfileProvider>().fetchCurrentUser();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<UserProfileProvider>();
    final user = profileProvider.selectedUser;

    // Logika dinamis berdasarkan data dari provider
    final bool isProfileComplete = user?.isProfileComplete ?? false;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(300),
        child: AppBar(
          backgroundColor: AppColors.primaryColor,
          automaticallyImplyLeading: false,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          flexibleSpace: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 110.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [HeaderUserAppbar(), ButtonAppBar()],
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child:
                        (user?.fotoProfilUrl != null &&
                            user!.fotoProfilUrl!.trim().isNotEmpty)
                        ? Image.network(
                            user.fotoProfilUrl!,
                            width: 70, // Menyesuaikan diameter avatar (35 * 2)
                            height: 70,
                            fit: BoxFit.cover,
                            // Menangani error jika URL gambar rusak
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.broken_image,
                                size: 35,
                                color: AppColors.primaryColor,
                              );
                            },
                            // Menampilkan loading saat gambar sedang diunduh
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          )
                        : const Icon(
                            Icons.person,
                            size: 35,
                            color: AppColors.primaryColor,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _profileRefresh,
        child: profileProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : isProfileComplete
            ? const ContentRiwayatAbsensi() // Pastikan di dalam ini juga scrollable
            : SingleChildScrollView(
                // <--- Tambahkan ini
                physics:
                    const AlwaysScrollableScrollPhysics(), // <--- WAJIB agar bisa ditarik
                child: Container(
                  // Mengatur tinggi minimal agar memenuhi layar supaya bisa di-pull
                  height:
                      MediaQuery.of(context).size.height -
                      500, // dikurangi tinggi AppBar
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: 0.5,
                        child: Image.asset(
                          'lib/assets/images/Profile-empty.png',
                          width: 200,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Lengkapi Profil Anda \n Untuk Membuka Fitur Lainnya.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
