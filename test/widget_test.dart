import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medscribe/app/app.dart';

void main() {
  testWidgets('App boots to home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MedScribeApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Welcome Back, Doctor'), findsOneWidget);
    expect(find.text('MediScribe'), findsWidgets);
  });
}
