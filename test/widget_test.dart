import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rxvarta/app/app.dart';

void main() {
  testWidgets('App boots to home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RxvartaApp()));

    // Can't use pumpAndSettle — the hero waveform animates continuously.
    // Pump a fixed window so the staggered entrance timers fire and the
    // async providers settle.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // The redesigned home shows the brand mark and the primary CTA.
    expect(find.text('Rxvarta'), findsWidgets);
    expect(find.text('Start new consultation'), findsOneWidget);
  });
}
