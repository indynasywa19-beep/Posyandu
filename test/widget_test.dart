import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:si_posyandu/pages/login_page.dart';

void main() {
  testWidgets('login page shows Supabase email and password inputs', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('SI-POSYANDU'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('MASUK'), findsOneWidget);
  });
}
