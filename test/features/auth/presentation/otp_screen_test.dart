import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/features/auth/data/auth_remote_datasource.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/data/tos_acceptance_model.dart';
import 'package:ppv_app/features/auth/data/user_model.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';
import 'package:ppv_app/features/auth/presentation/screens/otp_screen.dart';
import 'package:ppv_app/features/auth/presentation/tos_provider.dart';

class _FakeUserCredential implements firebase.UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockAuthRepository implements AuthRepository {
  bool verifyOtpCalled = false;
  bool registerCalled = false;
  bool loginCalled = false;
  bool verifyOtpShouldSucceed = false;
  LoginResult? loginResult;
  Exception? loginError;

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(firebase.FirebaseAuthException error)
        onVerificationFailed,
    required void Function(firebase.PhoneAuthCredential credential)
        onVerificationCompleted,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    onCodeSent('test_verification_id', null);
  }

  @override
  Future<firebase.UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    verifyOtpCalled = true;
    if (verifyOtpShouldSucceed) {
      return _FakeUserCredential();
    }
    throw UnimplementedError();
  }

  @override
  Future<RegisterResult> register({
    String? firstName,
    String? lastName,
  }) async {
    registerCalled = true;
    return const RegisterResult(
      user: UserModel(
        id: 1,
        phone: '+2250701020304',
        role: 'creator',
        kycStatus: 'none',
        isActive: true,
      ),
      accessToken: 'token',
      refreshToken: 'refresh',
    );
  }

  @override
  Future<LoginResult> login() async {
    loginCalled = true;
    if (loginError != null) throw loginError!;
    return loginResult ??
        const LoginResult(
          user: UserModel(
            id: 1,
            phone: '+2250701020304',
            firstName: 'Aminata',
            lastName: 'Koné',
            role: 'creator',
            kycStatus: 'none',
            acceptedTosAt: null,
            tosVersion: null,
            isActive: true,
          ),
          accessToken: 'test_access',
          refreshToken: 'test_refresh',
        );
  }

  @override
  Future<void> refreshToken() async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> submitKyc({
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required File document,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> getProfile() async {
    throw UnimplementedError();
  }

  @override
  Future<TosAcceptanceModel> acceptTos({
    required String type,
  }) async {
    return TosAcceptanceModel(
      id: 1,
      acceptanceType: type,
      tosVersion: '1.0',
      acceptedAt: DateTime.now(),
    );
  }

  @override
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    File? avatar,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> registerFcmToken(String token) async =>
      throw UnimplementedError();
}

void main() {
  late _MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = _MockAuthRepository();
  });

  Widget createTestWidget({bool isLoginFlow = false}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: mockRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => TosProvider(repository: mockRepository),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/otp',
          routes: [
            GoRoute(
              path: '/otp',
              builder: (_, _) => OtpScreen(
                phoneNumber: '+2250701020304',
                isLoginFlow: isLoginFlow,
              ),
            ),
            GoRoute(
              path: '/register',
              builder: (_, _) =>
                  const Scaffold(body: Text('Register Screen')),
            ),
            GoRoute(
              path: '/login',
              builder: (_, _) =>
                  const Scaffold(body: Text('Login Screen')),
            ),
            GoRoute(
              path: '/tos',
              builder: (_, _) =>
                  const Scaffold(body: Text('TOS Screen')),
            ),
            GoRoute(
              path: '/kyc',
              builder: (_, _) =>
                  const Scaffold(body: Text('KYC Screen')),
            ),
            GoRoute(
              path: '/home',
              builder: (_, _) =>
                  const Scaffold(body: Text('Home Screen')),
            ),
          ],
        ),
      ),
    );
  }

  group('OtpScreen', () {
    testWidgets('displays verification title and phone number',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Vérification'), findsOneWidget);
      expect(find.text('Code envoyé au +2250701020304'), findsOneWidget);
    });

    testWidgets('displays Modifier button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Modifier'), findsOneWidget);
    });

    testWidgets('displays 6 OTP input fields', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // 6 TextFields for OTP digits
      expect(find.byType(TextField), findsNWidgets(6));
    });

    testWidgets('displays resend timer countdown', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.textContaining('Renvoyer le code'), findsOneWidget);
      expect(find.textContaining('60s'), findsOneWidget);
    });

    testWidgets('displays Vérifier button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Vérifier'), findsOneWidget);
    });

    testWidgets('timer counts down', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Advance timer by 1 second
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('59s'), findsOneWidget);
    });

    testWidgets('auto-advances focus between OTP fields', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final fields = find.byType(TextField);

      // Type in first field
      await tester.enterText(fields.at(0), '1');
      await tester.pump();

      // Focus should move to second field (verified by being able to type)
      await tester.enterText(fields.at(1), '2');
      await tester.pump();

      // Verify both fields have values
      final controller0 =
          (tester.widget(fields.at(0)) as TextField).controller;
      final controller1 =
          (tester.widget(fields.at(1)) as TextField).controller;

      expect(controller0?.text, '1');
      expect(controller1?.text, '2');
    });
  });

  group('OtpScreen - Login Flow (isLoginFlow=true)', () {
    testWidgets('back button navigates to /login', (tester) async {
      await tester.pumpWidget(createTestWidget(isLoginFlow: true));

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('Modifier navigates to /login', (tester) async {
      await tester.pumpWidget(createTestWidget(isLoginFlow: true));

      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen'), findsOneWidget);
    });

    testWidgets('login flow calls loginAfterOtp on OTP verified',
        (tester) async {
      mockRepository.verifyOtpShouldSucceed = true;
      // Login returns user with TOS accepted → should go to /home
      mockRepository.loginResult = LoginResult(
        user: UserModel(
          id: 1,
          phone: '+2250701020304',
          firstName: 'Aminata',
          lastName: 'Koné',
          role: 'creator',
          kycStatus: 'none',
          acceptedTosAt: DateTime(2025, 1, 1),
          tosVersion: '1.0',
          isActive: true,
        ),
        accessToken: 'test_access',
        refreshToken: 'test_refresh',
      );

      await tester.pumpWidget(createTestWidget(isLoginFlow: true));

      // First send OTP to set verificationId
      final authProvider = tester
          .element(find.byType(OtpScreen))
          .read<AuthProvider>();
      await authProvider.loginSendOtp('+2250701020304');
      await tester.pump();

      // Type OTP code
      final fields = find.byType(TextField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(fields.at(i), '${i + 1}');
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(mockRepository.loginCalled, true);
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('login flow shows TOS dialog when tosAcceptedAt is null',
        (tester) async {
      mockRepository.verifyOtpShouldSucceed = true;
      // Login returns user WITHOUT TOS accepted
      mockRepository.loginResult = const LoginResult(
        user: UserModel(
          id: 1,
          phone: '+2250701020304',
          firstName: 'Aminata',
          lastName: 'Koné',
          role: 'creator',
          kycStatus: 'none',
          acceptedTosAt: null,
          tosVersion: null,
          isActive: true,
        ),
        accessToken: 'test_access',
        refreshToken: 'test_refresh',
      );

      await tester.pumpWidget(createTestWidget(isLoginFlow: true));

      // Set verificationId via loginSendOtp
      final authProvider = tester
          .element(find.byType(OtpScreen))
          .read<AuthProvider>();
      await authProvider.loginSendOtp('+2250701020304');
      await tester.pump();

      // Type OTP code
      final fields = find.byType(TextField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(fields.at(i), '${i + 1}');
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // TOS dialog should be shown
      expect(
          find.text('Conditions Générales d\'Utilisation'), findsOneWidget);
      expect(find.text('Accepter'), findsOneWidget);
    });

    testWidgets('TOS dialog acceptance navigates to /home',
        (tester) async {
      mockRepository.verifyOtpShouldSucceed = true;
      mockRepository.loginResult = const LoginResult(
        user: UserModel(
          id: 1,
          phone: '+2250701020304',
          firstName: 'Aminata',
          lastName: 'Koné',
          role: 'creator',
          kycStatus: 'none',
          acceptedTosAt: null,
          tosVersion: null,
          isActive: true,
        ),
        accessToken: 'test_access',
        refreshToken: 'test_refresh',
      );

      await tester.pumpWidget(createTestWidget(isLoginFlow: true));

      // Set verificationId
      final authProvider = tester
          .element(find.byType(OtpScreen))
          .read<AuthProvider>();
      await authProvider.loginSendOtp('+2250701020304');
      await tester.pump();

      // Type OTP
      final fields = find.byType(TextField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(fields.at(i), '${i + 1}');
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Dialog is showing — tap Accepter
      await tester.tap(find.text('Accepter'));
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('ACCOUNT_NOT_FOUND shows SnackBar with S\'inscrire action',
        (tester) async {
      mockRepository.verifyOtpShouldSucceed = true;
      mockRepository.loginError = const AuthApiException(
        message: 'Aucun compte associé',
        code: 'ACCOUNT_NOT_FOUND',
      );

      await tester.pumpWidget(createTestWidget(isLoginFlow: true));

      // Set verificationId
      final authProvider = tester
          .element(find.byType(OtpScreen))
          .read<AuthProvider>();
      await authProvider.loginSendOtp('+2250701020304');
      await tester.pump();

      // Type OTP
      final fields = find.byType(TextField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(fields.at(i), '${i + 1}');
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // SnackBar should show
      expect(
          find.text('Aucun compte associé à ce numéro.'), findsOneWidget);
      expect(find.text('S\'inscrire'), findsOneWidget);
    });
  });

  group('OtpScreen - Register Flow (isLoginFlow=false)', () {
    testWidgets('back button navigates to /register', (tester) async {
      await tester.pumpWidget(createTestWidget(isLoginFlow: false));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Register Screen'), findsOneWidget);
    });
  });
}
