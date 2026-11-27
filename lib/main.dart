import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/home_kader_page.dart';
import 'pages/home_ortu_page.dart';
import 'pages/login_page.dart';
import 'widgets/app_components.dart';
import 'widgets/app_theme.dart';
import 'widgets/design_tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qbkddqhxatkfpxqrzzri.supabase.co',
    publishableKey: 'sb_publishable_oBV6wIFcCH6rJZ3Aa_VgSg_Y-lkjiMC',
  );

  runApp(const SiPosyanduApp());
}

class SiPosyanduApp extends StatelessWidget {
  const SiPosyanduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SI-Posyandu',
      theme: AppTheme.parent,
      home: const _AuthGate(),
    );
  }
}

/// Mengecek sesi login tersimpan secara otomatis saat aplikasi dibuka.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final Future<Widget> _startPageFuture = _resolveStartPage();

  Future<Widget> _resolveStartPage() async {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    final user = session?.user;

    if (session == null || user == null) {
      return const LoginPage();
    }

    // 1. Cek peran dari userMetadata terlebih dahulu (cepat)
    final metaRole = user.userMetadata?['role']?.toString().toLowerCase();
    if (metaRole == 'kader') {
      return const HomeKaderPage();
    }

    // 2. Cocokkan dengan tabel profiles di database Supabase
    try {
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      final dbRole = profile?['role']?.toString().toLowerCase();
      if (dbRole == 'kader') {
        return const HomeKaderPage();
      }
      return const HomeOrtuPage();
    } catch (_) {
      // Jika offline / gagal ambil profil, tetap arahkan sesuai metadata atau Ortu
      return metaRole == 'kader'
          ? const HomeKaderPage()
          : const HomeOrtuPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _startPageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SiPosyanduLogoIcon(size: 64),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: AppColors.navy),
                ],
              ),
            ),
          );
        }

        return snapshot.data ?? const LoginPage();
      },
    );
  }
}