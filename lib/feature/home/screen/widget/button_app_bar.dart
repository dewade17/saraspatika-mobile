import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/core/shared_widgets/permission_guard.dart';
import 'package:saraspatika/feature/login/data/provider/auth_provider.dart';

class ButtonAppBar extends StatefulWidget {
  const ButtonAppBar({super.key});

  @override
  State<ButtonAppBar> createState() => _ButtonAppBarState();
}

class _ButtonAppBarState extends State<ButtonAppBar> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userRole = authProvider.me?.role.toUpperCase() ?? '';
    final bool isKerja = userRole == 'PEGAWAI';
    final IconData menuIcon = isKerja
        ? Icons.business_center
        : Icons.assignment_add;
    final String menuTitle = isKerja ? 'Agenda\nKerja' : 'Agenda\nMengajar';
    final String routeName = isKerja
        ? '/screen-agenda-kerja'
        : '/screen-agenda-mengajar';
    final bool isProfileComplete = authProvider.me != null;

    return Column(
      children: [
        Card(
          child: isProfileComplete
              ? Column(
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          PermissionGuard(
                            resource: 'absensi',
                            action: 'create',
                            child: Expanded(
                              child: InkWell(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/absensi-kedatangan',
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.calendar_month,
                                      size: 30,
                                      color: Color(0xFF92E3A9),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Absensi Kedatangan',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          PermissionGuard(
                            resource: 'absensi',
                            action: 'create',
                            child: Expanded(
                              child: InkWell(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/absensi-kepulangan',
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.calendar_month,
                                      size: 30,
                                      color: Colors.red,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Absensi Kepulangan',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          PermissionGuard(
                            resource: 'agenda',
                            action: 'read',
                            child: Expanded(
                              child: InkWell(
                                onTap: () =>
                                    Navigator.pushNamed(context, routeName),
                                child: Column(
                                  children: [
                                    Icon(
                                      menuIcon,
                                      size: 30,
                                      color: Colors.blueAccent,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      menuTitle,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                await authProvider.logout();
                                if (!context.mounted) return;
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              },
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.power_settings_new_sharp,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Logout',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
