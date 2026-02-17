import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/core/shared_widgets/permission_guard.dart';
import 'package:saraspatika/feature/login/data/provider/auth_provider.dart';
import 'package:saraspatika/feature/profile/data/provider/user_profile_provider.dart';

class ButtonAppBar extends StatefulWidget {
  const ButtonAppBar({super.key});

  @override
  State<ButtonAppBar> createState() => _ButtonAppBarState();
}

class _ButtonAppBarState extends State<ButtonAppBar> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<UserProfileProvider>();
    final user = profileProvider.selectedUser;
    final userRole = user?.role.toUpperCase() ?? '';
    final bool isKerja = userRole == 'PEGAWAI';
    final IconData menuIcon = isKerja
        ? Icons.business_center
        : Icons.assignment_add;
    final String menuTitle = isKerja ? 'Agenda\nKerja' : 'Agenda\nMengajar';
    const String routeName = '/screen-agenda';

    final bool canAccessMenu =
        user != null &&
        (user.name.isNotEmpty) &&
        (user.email.isNotEmpty) &&
        (user.nomorHandphone?.isNotEmpty ?? false);

    return Column(
      children: [
        Card(
          child: canAccessMenu
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
                                      color: AppColors.secondaryBackgroundColor,
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
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  routeName,
                                  arguments: {
                                    'title': menuTitle.replaceAll('\n', ' '),
                                    'role': userRole,
                                  },
                                ),
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
                                    color: AppColors.hintColor,
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
              : Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          await authProvider.logout();
                          if (!context.mounted) return;
                          Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil('/login', (route) => false);
                        },
                        child: const Column(
                          children: [
                            Icon(
                              Icons.power_settings_new_sharp,
                              size: 30,
                              color: AppColors.hintColor,
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
                      const Padding(
                        padding: EdgeInsets.all(13),
                        child: Text(
                          "Silakan lengkapi profil untuk mengakses menu.",
                          style: TextStyle(
                            color: AppColors.hintColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
