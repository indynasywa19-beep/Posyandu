import 'package:flutter/material.dart';

import 'pages/login_page.dart';

void main() {
  runApp(const SiPosyanduApp());
}

class SiPosyanduApp extends StatelessWidget {
  const SiPosyanduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SI-Posyandu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
