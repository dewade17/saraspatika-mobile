import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:saraspatika/core/shared_widgets/app_button_widget.dart';
import 'package:saraspatika/core/shared_widgets/app_text_field.dart';
import 'package:saraspatika/feature/reset_password/data/provider/reset_password_provider.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailC = TextEditingController();
  final _tokenC = TextEditingController();
  final _newPasswordC = TextEditingController();

  bool _tokenRequested = false;

  @override
  void dispose() {
    _emailC.dispose();
    _tokenC.dispose();
    _newPasswordC.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Email wajib diisi';
    if (!s.contains('@')) return 'Format email tidak valid';
    return null;
  }

  String? _validateToken(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Token wajib diisi';
    return null;
  }

  String? _validateNewPassword(String? v) {
    final s = (v ?? '');
    if (s.isEmpty) return 'Password baru wajib diisi';
    if (s.length < 6) return 'Minimal 6 karakter';
    return null;
  }

  Future<void> _onRequestToken() async {
    final p = context.read<ResetPasswordProvider>();
    FocusScope.of(context).unfocus();

    if (!(_emailFormKey.currentState?.validate() ?? false)) return;

    try {
      await p.requestResetToken(email: _emailC.text.trim());
      if (!mounted) return;

      setState(() => _tokenRequested = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jika email terdaftar, token reset sudah dikirim.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      final msg = p.errorMessage ?? 'Gagal kirim token.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _onResetPassword() async {
    final p = context.read<ResetPasswordProvider>();
    FocusScope.of(context).unfocus();

    if (!(_emailFormKey.currentState?.validate() ?? false)) return;
    if (!(_resetFormKey.currentState?.validate() ?? false)) return;

    try {
      final ok = await p.resetPassword(
        email: _emailC.text.trim(),
        code: _tokenC.text.trim(),
        newPassword: _newPasswordC.text,
      );

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil direset. Silakan login.'),
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reset password gagal.')));
      }
    } catch (_) {
      if (!mounted) return;
      final msg =
          context.read<ResetPasswordProvider>().errorMessage ??
          'Reset password gagal.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ResetPasswordProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset(
                'lib/assets/images/Reset_password.png',
                height: 250,
                width: 250,
              ),
              const SizedBox(height: 20),
              Text(
                "Reset Password",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 20),

              // ===== FORM EMAIL =====
              Form(
                key: _emailFormKey,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _emailC,
                          validator: _validateEmail,
                          enabled: !p.isLoading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          hintText: "masukan email",
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          leadingIcon: Icons.alternate_email_rounded,
                          onChanged: (_) {
                            if (_tokenRequested) {
                              setState(() => _tokenRequested = false);
                            }
                            if (p.errorMessage != null) {
                              context
                                  .read<ResetPasswordProvider>()
                                  .clearError();
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            AppButton(
                              text: 'Kirim Kode',
                              size: AppButtonSize.sm,
                              isLoading: p.isLoading,
                              manageInternalLoading: false,
                              enabled: !p.isLoading,
                              onPressedAsync: _onRequestToken,
                            ),
                            const SizedBox(width: 12),
                            if (_tokenRequested)
                              const Expanded(
                                child: Text(
                                  'Token dikirim (cek email)',
                                  style: TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ===== FORM TOKEN + PASSWORD BARU =====
              Form(
                key: _resetFormKey,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 350),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Token",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _tokenC,
                          validator: _validateToken,
                          enabled: !p.isLoading,
                          textInputAction: TextInputAction.next,
                          hintText: "Token",
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          leadingIcon: Icons.generating_tokens_outlined,
                          onChanged: (_) {
                            if (p.errorMessage != null) {
                              context
                                  .read<ResetPasswordProvider>()
                                  .clearError();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Password Baru",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AppTextField(
                          controller: _newPasswordC,
                          validator: _validateNewPassword,
                          enabled: !p.isLoading,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          hintText: "Password Baru",
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          leadingIcon: Icons.lock,
                          onSubmitted: (_) => _onResetPassword(),
                          onChanged: (_) {
                            if (p.errorMessage != null) {
                              context
                                  .read<ResetPasswordProvider>()
                                  .clearError();
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          text: "Reset Password",
                          fullWidth: true,
                          isLoading: p.isLoading,
                          manageInternalLoading: false,
                          enabled: !p.isLoading,
                          onPressedAsync: _onResetPassword,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              GestureDetector(
                onTap: p.isLoading
                    ? null
                    : () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                child: Text(
                  'Login',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
