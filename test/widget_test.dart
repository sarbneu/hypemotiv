// Smoke test for the shipped HypeMotiv app shell.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hypemotiv/main.dart';

void main() {
  testWidgets('app boots into the secure operator login', (tester) async {
    await tester.pumpWidget(const HypeMotivApp());

    expect(find.textContaining('SECURE OPERATOR ACCESS'), findsOneWidget);
    expect(find.textContaining('AUTHORIZE & ENTER ARENA'), findsOneWidget);
  });
}
