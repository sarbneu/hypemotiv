// Smoke + authentication tests for the shipped HypeMotiv app shell.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hypemotiv/main.dart';
import 'package:hypemotiv/screens/login_screen.dart';
import 'package:hypemotiv/screens/setup_screen.dart';
import 'package:hypemotiv/services/auth_service.dart';
import 'package:hypemotiv/services/math_task_service.dart';
import 'package:hypemotiv/services/proof_verification_service.dart';
import 'package:hypemotiv/services/task_selection_service.dart';
import 'package:hypemotiv/utils/task_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app boots into the sign-in screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const HypeMotivApp());
    // pumpAndSettle never returns while the indeterminate progress animates.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Create your account'), findsOneWidget);
    expect(find.textContaining('Create account and continue'), findsOneWidget);
  });

  testWidgets('creating a local account enters the app', (tester) async {
    SharedPreferences.setMockInitialValues({});
    bool entered = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(onEnter: () => entered = true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField).at(0), 'runner@hypemotiv.app');
    await tester.enterText(find.byType(TextField).at(1), 'wakeup123');
    await tester.enterText(find.byType(TextField).at(2), 'wakeup123');
    await tester.ensureVisible(find.text('Create account and continue'));
    await tester.pump();
    await tester.tap(find.text('Create account and continue'));
    await tester.pumpAndSettle();

    expect(entered, isTrue);
    expect(await AuthService().isRegistered(), isTrue);
    expect(await AuthService().isSignedIn(), isTrue);
  });

  testWidgets('wrong passcode is rejected', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final AuthService auth = AuthService();
    await auth.register('runner@hypemotiv.app', 'wakeup123');
    await auth.signOut();

    bool entered = false;
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onEnter: () => entered = true)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    // A registered account starts in sign-in mode.
    await tester.enterText(find.byType(TextField).at(0), 'runner@hypemotiv.app');
    await tester.enterText(find.byType(TextField).at(1), 'wrongpass');
    await tester.ensureVisible(find.text('Sign in and continue'));
    await tester.pump();
    await tester.tap(find.text('Sign in and continue'));
    await tester.pumpAndSettle();

    expect(entered, isFalse);
    expect(find.text('Incorrect passcode or handle'), findsNWidgets(2));
  });

  testWidgets('a one-character passcode is accepted', (tester) async {
    SharedPreferences.setMockInitialValues({});
    bool entered = false;
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onEnter: () => entered = true)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField).at(0), 'solo');
    await tester.enterText(find.byType(TextField).at(1), '1');
    await tester.enterText(find.byType(TextField).at(2), '1');
    await tester.ensureVisible(find.text('Create account and continue'));
    await tester.pump();
    await tester.tap(find.text('Create account and continue'));
    await tester.pumpAndSettle();

    expect(entered, isTrue);
    expect(await AuthService().login('solo', '1'), isTrue);
  });

  testWidgets('mismatched passcodes are rejected', (tester) async {
    SharedPreferences.setMockInitialValues({});
    bool entered = false;
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(onEnter: () => entered = true)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField).at(0), 'solo');
    await tester.enterText(find.byType(TextField).at(1), 'abc');
    await tester.enterText(find.byType(TextField).at(2), 'abd');
    await tester.ensureVisible(find.text('Create account and continue'));
    await tester.pump();
    await tester.tap(find.text('Create account and continue'));
    await tester.pumpAndSettle();

    expect(entered, isFalse);
    expect(find.text('Passcodes do not match'), findsNWidgets(2));
  });
  test('task selection defaults to all tasks and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final TaskSelectionService service = TaskSelectionService();
    expect(await service.selected(), wakeTasks.map((WakeTask task) => task.id).toList());

    await service.save(<String>['maths', 'squats']);
    expect(await service.selected(), <String>['maths', 'squats']);
    expect(await service.isRequired('photo'), isFalse);
    expect(await service.isRequired('maths'), isTrue);
  });

  test('photo proof requires fresh, distinct captures', () {
    final ProofVerificationService service = ProofVerificationService();
    final DateTime now = DateTime.now();
    const String firstHash = '0000000000000000000000000000000000000000000000000000000000000000';
    const String sameHash = '0000000000000000000000000000000000000000000000000000000000000000';
    const String differentHash = '1111111111111111000000000000000000000000000000000000000000000000';

    expect(ProofVerificationService.hashDistance(firstHash, sameHash), 0);
    expect(ProofVerificationService.hashDistance(firstHash, differentHash), 16);

    final ProofSignature first = ProofSignature(
      hash: firstHash,
      capturedAt: now,
      brightness: 120,
      variance: 500,
    );
    final ProofSignature tooSoon = ProofSignature(
      hash: differentHash,
      capturedAt: now.add(const Duration(seconds: 3)),
      brightness: 120,
      variance: 500,
    );
    final ProofSignature valid = ProofSignature(
      hash: differentHash,
      capturedAt: now.add(const Duration(seconds: 12)),
      brightness: 120,
      variance: 500,
    );

    expect(service.isDistinctCapture(first, tooSoon), isFalse);
    expect(service.isDistinctCapture(first, valid), isTrue);
  });


  test('shared auth validators enforce handle and passcode rules', () {
    expect(AuthService.validateUser(''), isNotNull);
    expect(AuthService.validateUser('ab'), isNotNull);
    expect(AuthService.validateUser('bad handle'), isNotNull);
    expect(AuthService.validateUser('runner09'), isNull);

    expect(AuthService.validatePasscode(''), isNotNull);
    expect(AuthService.validatePasscode('1' * 65), isNotNull);
    expect(AuthService.validatePasscode('1'), isNull);
    expect(
      AuthService.validatePasscode('abc', confirmation: 'abd'),
      'Passcodes do not match',
    );
  });

  testWidgets('finish setup rejects an empty passcode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    bool entered = false;
    await tester.pumpWidget(
      MaterialApp(home: SetupScreen(onEnter: () => entered = true)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.ensureVisible(find.text('Finish setup'));
    await tester.pump();
    await tester.tap(find.text('Finish setup'));
    await tester.pumpAndSettle();

    expect(entered, isFalse);
    expect(find.text('Enter a passcode (even one character is fine)'), findsWidgets);
  });


  test('math task supports easy difficulty and custom questions', () async {
    SharedPreferences.setMockInitialValues({});
    final MathTaskService service = MathTaskService();

    await service.setDifficulty('Easy');
    final MathProblem easy = await service.nextProblem();
    expect(easy.question.contains('+') || easy.question.contains('−'), isTrue);

    await service.addCustom('What is 7 + 5?', 12);
    expect((await service.customQuestions()).length, 1);
    final MathProblem custom = await service.nextProblem();
    expect(custom.question, 'What is 7 + 5?');
    expect(custom.answer, 12);

    await service.removeCustom(0);
    expect(await service.customQuestions(), isEmpty);
  });

}
