import 'dart:convert';
import 'dart:typed_data';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saraspatika/core/constanta/colors.dart';
import 'package:saraspatika/feature/izin_sakit_cuti/screen/izin_sakit_cuti.dart';
import 'package:saraspatika/feature/profile/screen/profile_screen.dart';

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

// =====================
// UI ONLY (Dummy Data)
// =====================

class AttendanceDay {
  final DateTime tanggal;
  final DateTime? jamMasuk;
  final DateTime? jamKeluar;

  const AttendanceDay({required this.tanggal, this.jamMasuk, this.jamKeluar});
}

class DummyUser {
  final String name;
  final String? fotoProfilBase64;

  const DummyUser({required this.name, this.fotoProfilBase64});
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  late final ScrollController _scrollController;

  // Toggle ini untuk simulasi UI saat profil lengkap / belum lengkap
  // (UI only, bukan logic bisnis)
  final bool _isProfileComplete = true;

  // Dummy user
  final DummyUser _user = const DummyUser(
    name: 'I Putu Hendy Pradika, S.Pd',
    // Kalau mau test base64 foto, isi string base64 valid di sini (boleh dengan prefix data:image/...;base64,)
    fotoProfilBase64: '',
  );

  // Dummy history (paling baru di atas)
  late List<AttendanceDay> _history = [
    AttendanceDay(
      tanggal: DateTime.now().subtract(const Duration(days: 0)),
      jamMasuk: DateTime.now().subtract(
        Duration(hours: DateTime.now().hour - 8, minutes: 10),
      ),
      jamKeluar: DateTime.now().subtract(
        Duration(hours: DateTime.now().hour - 16, minutes: 5),
      ),
    ),
    AttendanceDay(
      tanggal: DateTime.now().subtract(const Duration(days: 1)),
      jamMasuk: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      jamKeluar: DateTime.now().subtract(const Duration(days: 1, hours: -5)),
    ),
    AttendanceDay(
      tanggal: DateTime.now().subtract(const Duration(days: 2)),
      jamMasuk: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      jamKeluar: null,
    ),
    AttendanceDay(
      tanggal: DateTime.now().subtract(const Duration(days: 3)),
      jamMasuk: null,
      jamKeluar: null,
    ),
  ];

  Future<void> _fakeRefresh() async {
    // UI-only: refresh palsu (tanpa API/provider)
    await Future<void>.delayed(const Duration(milliseconds: 700));

    // Optional: biar terasa “refresh”, kita reorder/replace dummy data sedikit
    setState(() {
      _history = List<AttendanceDay>.from(_history);
    });
  }

  void _scrollListener() {
    // UI-only: kalau kamu mau simulasikan infinite scroll,
    // kamu bisa append dummy data saat scroll mendekati bawah.
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Simulasi load data tambahan (dummy)
      // Biar tidak kebanyakan nambah terus, batasi jumlah
      if (_history.length < 15) {
        final lastDate = _history.isNotEmpty
            ? _history.last.tanggal
            : DateTime.now().subtract(const Duration(days: 1));

        setState(() {
          _history.add(
            AttendanceDay(
              tanggal: lastDate.subtract(const Duration(days: 1)),
              jamMasuk: null,
              jamKeluar: null,
            ),
          );
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Uint8List? _tryDecodeBase64Image(String? base64) {
    if (base64 == null) return null;
    final trimmed = base64.trim();
    if (trimmed.isEmpty) return null;

    try {
      final cleaned = trimmed.contains(',') ? trimmed.split(',').last : trimmed;
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarBytes = _tryDecodeBase64Image(_user.fotoProfilBase64);

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
                  children: [
                    Text(
                      'Selamat Datang',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _user.name,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: _isProfileComplete
                          ? Column(
                              children: [
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            // UI-only: placeholder route
                                            Navigator.pushNamed(
                                              context,
                                              '/absensi-kedatangan',
                                            );
                                          },
                                          child: const Center(
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.calendar_month,
                                                  size: 30,
                                                  color: Color(0xFF92E3A9),
                                                ),
                                                Text(
                                                  'Absensi Kedatangan',
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            // UI-only: placeholder route
                                            Navigator.pushNamed(
                                              context,
                                              '/absensi-kepulangan',
                                            );
                                          },
                                          child: const Center(
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.calendar_month,
                                                  size: 30,
                                                  color: Colors.red,
                                                ),
                                                Text(
                                                  'Absensi Kepulangan',
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            // UI-only: placeholder route
                                            Navigator.pushNamed(
                                              context,
                                              '/screen-agenda',
                                            );
                                          },
                                          child: const Center(
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons.assignment_add,
                                                  size: 30,
                                                  color: Colors.blueAccent,
                                                ),
                                                Text(
                                                  'Agenda\nMengajar',
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () {
                                            // UI-only: placeholder action
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Logout (UI dummy)',
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Center(
                                            child: Column(
                                              children: [
                                                Icon(
                                                  Icons
                                                      .power_settings_new_sharp,
                                                  size: 30,
                                                ),
                                                Text('Logout'),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            )
                          : const SizedBox(),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    // UI-only: placeholder action
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Foto Profil diklik')),
                    );
                  },
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: avatarBytes != null
                        ? MemoryImage(avatarBytes)
                        : null,
                    child: avatarBytes == null
                        ? const Icon(
                            Icons.person,
                            size: 35,
                            color: AppColors.primaryColor,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fakeRefresh,
        child: _isProfileComplete
            ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "History\nKehadiran",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // UI-only: placeholder route
                            Navigator.pushNamed(context, '/data-absensi');
                          },
                          child: const Text(
                            "View All",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _history.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: 200,
                                      height: 200,
                                      child: Opacity(
                                        opacity: 0.5,
                                        child: Image.asset(
                                          'assets/images/Empty-data.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'Kamu belum melakukan absensi.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _history.length,
                            itemBuilder: (context, index) {
                              final item = _history[index];
                              final tanggal = item.tanggal.toLocal();
                              final jamMasuk = item.jamMasuk?.toLocal();
                              final jamKeluar = item.jamKeluar?.toLocal();

                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Card(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 26,
                                        ),
                                        child: Text(
                                          DateFormat(
                                            'EEEE, dd MMMM yyyy',
                                            'id_ID',
                                          ).format(tanggal),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                color: Colors.red,
                                                size: 30,
                                              ),
                                              const SizedBox(width: 5),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text("Jam Masuk"),
                                                  Text(
                                                    jamMasuk != null
                                                        ? DateFormat(
                                                            'HH:mm',
                                                          ).format(jamMasuk)
                                                        : "-",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                color: Colors.red,
                                                size: 30,
                                              ),
                                              const SizedBox(width: 5),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text("Jam Pulang"),
                                                  Text(
                                                    jamKeluar != null
                                                        ? DateFormat(
                                                            'HH:mm',
                                                          ).format(jamKeluar)
                                                        : "-",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 70),
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: Opacity(
                            opacity: 0.5,
                            child: Image.asset(
                              'assets/images/Profile-empty.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const Text(
                          'Lengkapi Profil Anda \n Untuk Membuka Fitur Lainnya.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
