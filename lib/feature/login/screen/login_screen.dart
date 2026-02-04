import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/core/services/api_service.dart';
import 'package:saraspatika/core/shared_widgets/app_button_widget.dart';
import 'package:saraspatika/core/shared_widgets/app_text_field.dart';
import 'package:saraspatika/feature/absensi/data/provider/get_face_provider.dart';
import 'package:saraspatika/feature/login/data/provider/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password wajib diisi.')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final getFaceProvider = context.read<GetFaceProvider>();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await authProvider.login(email: email, password: password);

      final userId = (authProvider.me?.idUser ?? '').trim();
      if (userId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID user tidak ditemukan.')),
        );
        return;
      }

      bool hasFace = false;
      try {
        final face = await getFaceProvider.fetchFaceData(userId);
        hasFace = (face?.items ?? const []).isNotEmpty;
      } catch (e) {
        // Kalau server return 404 saat data wajah belum ada, treat sebagai "belum ada data"
        if (e is ApiException && e.statusCode == 404) {
          hasFace = false;
        } else {
          if (!mounted) return;
          final msg =
              getFaceProvider.errorMessage ?? 'Gagal mengambil data wajah.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
          return;
        }
      }

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacementNamed(hasFace ? '/home-screen' : '/registrasi-wajah');
    } catch (_) {
      if (!mounted) return;
      final msg = authProvider.errorMessage ?? 'Login gagal.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset(
                  'lib/assets/images/Karakter_login.png',
                  width: 300,
                  height: 300,
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome Back!',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to continue',
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                AutofillGroup(
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _emailController,
                        hintText: 'Masukan email',
                        leadingIcon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Email wajib diisi.';
                          return null;
                        },
                        enabled: !authProvider.isLoading,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _passwordController,
                        hintText: 'Masukan password',
                        leadingIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        validator: (v) {
                          final value = v ?? '';
                          if (value.isEmpty) return 'Password wajib diisi.';
                          return null;
                        },
                        onSubmitted: (_) => _handleLogin(),
                        enabled: !authProvider.isLoading,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Login',
                  fullWidth: true,
                  isLoading: authProvider.isLoading,
                  manageInternalLoading: false,
                  enabled: !authProvider.isLoading,
                  onPressedAsync: _handleLogin,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: authProvider.isLoading
                          ? null
                          : () {
                              Navigator.of(
                                context,
                              ).pushReplacementNamed('/reset-password');
                            },
                      child: Text(
                        'Reset Password?',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
