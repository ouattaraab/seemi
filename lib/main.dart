import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ppv_app/core/config/app_config.dart';
import 'package:ppv_app/core/security/device_security.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:ppv_app/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/network/dio_client.dart';
import 'package:ppv_app/core/services/mobile_event_service.dart';
import 'package:ppv_app/core/routing/app_router.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';
import 'package:ppv_app/core/theme/app_theme.dart';
import 'package:ppv_app/features/auth/data/auth_remote_datasource.dart';
import 'package:ppv_app/features/auth/data/auth_repository.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';
import 'package:ppv_app/features/auth/presentation/kyc_provider.dart';
import 'package:ppv_app/features/auth/presentation/profile_provider.dart';
import 'package:ppv_app/features/auth/presentation/tos_provider.dart';
import 'package:ppv_app/features/content/data/content_remote_datasource.dart';
import 'package:ppv_app/features/content/data/content_repository.dart';
import 'package:ppv_app/features/content/presentation/content_provider.dart';
import 'package:ppv_app/features/payout/data/payout_remote_datasource.dart';
import 'package:ppv_app/features/payout/data/payout_repository.dart';
import 'package:ppv_app/features/payout/presentation/payout_method_provider.dart';
import 'package:ppv_app/features/sharing/data/contact_repository.dart';
import 'package:ppv_app/features/sharing/data/share_repository.dart';
import 'package:ppv_app/features/notifications/data/notification_repository.dart';
import 'package:ppv_app/features/notifications/presentation/notification_provider.dart';
import 'package:ppv_app/features/referral/data/referral_repository.dart';
import 'package:ppv_app/features/referral/presentation/referral_provider.dart';
import 'package:ppv_app/features/wallet/data/wallet_repository.dart';
import 'package:ppv_app/features/wallet/presentation/wallet_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquer l'app sur les devices compromis (jailbreak/root/dev mode).
  // Timeout 3s : sur iOS bêta (iOS 26+), le plugin peut ne jamais répondre
  // → fail-open pour ne pas bloquer indéfiniment au démarrage.
  final bool compromised = await DeviceSecurity.isCompromised()
      .timeout(const Duration(seconds: 3), onTimeout: () => false);
  if (compromised) {
    runApp(const _JailbreakWarningApp());
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // Lancer l'app immédiatement pour éviter tout blocage sur l'écran blanc.
  // Sentry est initialisé en arrière-plan seulement si le DSN est configuré.
  runApp(const PpvApp());

  if (AppConfig.sentryDsn.isNotEmpty) {
    SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.environment = AppConfig.environment;
        options.tracesSampleRate = AppConfig.isProd ? 0.1 : 0.0;
      },
    ).ignore();
  }
}

/// Écran affiché sur les devices compromis — remplace l'app entière.
class _JailbreakWarningApp extends StatelessWidget {
  const _JailbreakWarningApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, color: Color(0xFFE53935), size: 72),
                  const SizedBox(height: 24),
                  const Text(
                    'Appareil non sécurisé',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SeeMi ne peut pas fonctionner sur un appareil rooté, '
                    'jailbreaké ou avec le mode développeur activé.\n\n'
                    'Désactivez le mode développeur et réessayez.',
                    style: TextStyle(
                      color: Colors.white.withAlpha(178),
                      fontSize: 15,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Root widget de l'application PPV.
class PpvApp extends StatefulWidget {
  final AppRouter? router;

  const PpvApp({super.key, this.router});

  @override
  State<PpvApp> createState() => _PpvAppState();
}

class _PpvAppState extends State<PpvApp> {
  late final AppRouter _appRouter;
  late final AuthRepository _authRepository;
  late final ContentRepository _contentRepository;
  late final PayoutRepository _payoutRepository;
  late final WalletRepository _walletRepository;
  late final NotificationRepository _notificationRepository;
  late final ReferralRepository _referralRepository;

  @override
  void initState() {
    super.initState();
    _appRouter = widget.router ?? AppRouter();

    const storageService = SecureStorageService();
    final dioClient = DioClient(
      storageService: storageService,
      onSessionExpired: () => _appRouter.router.go(RouteNames.kRouteLogin),
      onMaintenance: (data) =>
          _appRouter.router.go(RouteNames.kRouteMaintenance, extra: data),
    );
    // Initialise le service d'analytique mobile (Tier 2)
    MobileEventService.initialize(dioClient.dio);

    final authDataSource = AuthRemoteDataSource(dio: dioClient.dio);
    _authRepository = AuthRepository(
      dataSource: authDataSource,
      storageService: storageService,
    );
    final contentDataSource = ContentRemoteDataSource(dio: dioClient.dio);
    _contentRepository = ContentRepository(dataSource: contentDataSource);
    final payoutDataSource = PayoutRemoteDataSource(dio: dioClient.dio);
    _payoutRepository = PayoutRepository(dataSource: payoutDataSource);
    _walletRepository = WalletRepository(dio: dioClient.dio);
    _notificationRepository = NotificationRepository(dio: dioClient.dio);
    _referralRepository = ReferralRepository(dio: dioClient.dio);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: _authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => KycProvider(repository: _authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => TosProvider(repository: _authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(repository: _authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ContentProvider(repository: _contentRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => PayoutMethodProvider(repository: _payoutRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletProvider(repository: _walletRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            repository: _notificationRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ReferralProvider(repository: _referralRepository),
        ),
        Provider<ShareRepository>(
          create: (_) => ShareRepositoryImpl(),
        ),
        Provider<ContactRepository>(
          create: (_) => ContactRepositoryImpl(),
        ),
      ],
      child: MaterialApp.router(
        title: 'SeeMi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        routerConfig: _appRouter.router,
      ),
    );
  }
}
