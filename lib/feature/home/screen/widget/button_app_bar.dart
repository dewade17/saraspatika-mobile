import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/feature/login/data/provider/auth_provider.dart';

class ButtonAppBar extends StatefulWidget {
  const ButtonAppBar({super.key});

  @override
  State<ButtonAppBar> createState() => _ButtonAppBarState();
}

class _ButtonAppBarState extends State<ButtonAppBar> {
  final bool _isProfileComplete = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                                Navigator.pushNamed(context, '/screen-agenda');
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
                              onTap: () async {
                                final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );

                                await authProvider.logout();
                                if (!mounted) return;

                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              },
                              child: const Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.power_settings_new_sharp,
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
    );
  }
}
