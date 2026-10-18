import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/login_page.dart';
import 'widgets/app_theme.dart';

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
      home: const LoginPage(),
    );
  }
}
