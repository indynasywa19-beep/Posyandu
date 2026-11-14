import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si_posyandu/pages/artikel_page.dart';
import 'package:si_posyandu/pages/login_page.dart';
import 'package:si_posyandu/pages/profil_page.dart';

void main() {
  testWidgets('login page shows Supabase email and password inputs', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('SI-POSYANDU'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Kata sandi'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('login page shows inline errors when fields are empty', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    await tester.ensureVisible(find.text('Masuk'));
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
  });

  testWidgets('artikel page displays neutral heading and navigates to detail', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ArtikelPage()));

    expect(find.text('Bacaan Kesehatan Anak'), findsOneWidget);
    expect(find.textContaining('Bunda'), findsNothing);
    expect(find.text('Pentingnya Imunisasi untuk Anak'), findsOneWidget);

    // Tap first article to open detail
    await tester.tap(find.text('Pentingnya Imunisasi untuk Anak'));
    await tester.pumpAndSettle();

    expect(find.text('Artikel'), findsOneWidget);
    expect(find.textContaining('Imunisasi merupakan salah satu cara penting'), findsOneWidget);
  });

  testWidgets('profil page shows account info and prompts confirm on logout', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfilPage()));

    expect(find.text('Profil Saya'), findsOneWidget);
    expect(find.text('Informasi Akun'), findsOneWidget);
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Simpan Profil'), findsOneWidget);

    // Tap logout button in appbar
    final logoutButton = find.byTooltip('Keluar akun');
    expect(logoutButton, findsOneWidget);
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    // Verify confirmation dialog is presented
    expect(find.text('Keluar dari akun?'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
  });
}
