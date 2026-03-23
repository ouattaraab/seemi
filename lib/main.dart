import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:ppv_app/core/config/app_config.dart';
import 'package:ppv_app/core/security/device_security.dart';
import 'package:ppv_app/core/services/pending_deep_link_service.dart';
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
import 'package:ppv_app/features/affiliate/data/affiliate_repository.dart';
import 'package:ppv_app/features/bundle/data/bundle_repository.dart';
import 'package:ppv_app/features/custom_requests/data/custom_request_repository.dart';
import 'package:ppv_app/features/messaging/data/messaging_repository.dart';
import 'package:ppv_app/features/subscription/data/subscription_repository.dart';
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
    ).timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

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

/// App minimale de debug — à supprimer une fois le rendu iOS validé.
class _DebugApp extends StatelessWidget {
  const _DebugApp();
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0D0C1D),
        body: Center(
          child: Text('SeeMi OK', style: TextStyle(color: Colors.white, fontSize: 32)),
        ),
      ),
    );
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
  late final SecureStorageService _storageService;
  late final AuthRepository _authRepository;
  late final ContentRepository _contentRepository;
  late final PayoutRepository _payoutRepository;
  late final WalletRepository _walletRepository;
  late final NotificationRepository _notificationRepository;
  late final ReferralRepository _referralRepository;
  late final MessagingRepository _messagingRepository;
  late final AffiliateRepository _affiliateRepository;
  late final CustomRequestRepository _customRequestRepository;
  late final SubscriptionRepository _subscriptionRepository;
  late final BundleRepository _bundleRepository;

  @override
  void initState() {
    super.initState();
    _storageService = const SecureStorageService();
    _appRouter = widget.router ?? AppRouter();

    final dioClient = DioClient(
      storageService: _storageService,
      onSessionExpired: () => _appRouter.router.go(RouteNames.kRouteLogin),
      onMaintenance: (data) =>
          _appRouter.router.go(RouteNames.kRouteMaintenance, extra: data),
    );
    // Initialise le service d'analytique mobile (Tier 2)
    MobileEventService.initialize(dioClient.dio);

    final authDataSource = AuthRemoteDataSource(dio: dioClient.dio);
    _authRepository = AuthRepository(
      dataSource: authDataSource,
      storageService: _storageService,
    );
    final contentDataSource = ContentRemoteDataSource(dio: dioClient.dio);
    _contentRepository = ContentRepository(dataSource: contentDataSource);
    final payoutDataSource = PayoutRemoteDataSource(dio: dioClient.dio);
    _payoutRepository = PayoutRepository(dataSource: payoutDataSource);
    _walletRepository = WalletRepository(dio: dioClient.dio);
    _notificationRepository = NotificationRepository(dio: dioClient.dio);
    _referralRepository = ReferralRepository(dio: dioClient.dio);
    // MED-05 — MessagingRepository uses shared DioClient (with session/maintenance callbacks)
    _messagingRepository = MessagingRepositoryImpl(client: dioClient);

    // MED-06 — Repos partagent le même DioClient (callbacks session/maintenance)
    _affiliateRepository      = AffiliateRepository(client: dioClient);
    _customRequestRepository  = CustomRequestRepository(client: dioClient);
    _subscriptionRepository   = SubscriptionRepository(authClient: dioClient);
    _bundleRepository         = BundleRepositoryImpl(client: dioClient);

    _setupFcmHandlers();
  }

  // ── FCM tap handlers ───────────────────────────────────────────────────────

  void _setupFcmHandlers() {
    // App en background → utilisateur tape sur la notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message.data);
    });

    // App terminée → lancée depuis une notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        // Délai pour s'assurer que le router est prêt
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationTap(message.data);
        });
      }
    });
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final notificationId = data['notification_id'] as String?;
    final conversationId = data['conversation_id'] as String?;

    final String targetRoute;
    if (type == 'new_message' && conversationId != null) {
      targetRoute =
          RouteNames.conversation(int.tryParse(conversationId) ?? 0);
    } else if (notificationId != null) {
      targetRoute = RouteNames.notificationDetail(
          int.tryParse(notificationId) ?? 0);
    } else {
      targetRoute = RouteNames.kRouteMessages;
    }

    _storageService.hasTokens().then((hasToken) {
      if (!hasToken) {
        // Stocker le pending deep link et aller au login
        PendingDeepLinkService.instance.set(targetRoute);
        _appRouter.router.go(RouteNames.kRouteLogin);
      } else {
        _appRouter.router.push(targetRoute);
      }
    });
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
        // MED-05 — Shared instance with proper session/maintenance callbacks
        Provider<MessagingRepository>(
          create: (_) => _messagingRepository,
        ),
        // MED-06 — Repos with shared DioClient (session expiry + maintenance)
        Provider<AffiliateRepository>(
          create: (_) => _affiliateRepository,
        ),
        Provider<CustomRequestRepository>(
          create: (_) => _customRequestRepository,
        ),
        Provider<SubscriptionRepository>(
          create: (_) => _subscriptionRepository,
        ),
        Provider<BundleRepository>(
          create: (_) => _bundleRepository,
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
