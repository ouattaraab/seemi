import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/network/dio_client.dart';
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
import 'package:ppv_app/features/wallet/data/wallet_repository.dart';
import 'package:ppv_app/features/wallet/presentation/wallet_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyA2L0I78kO-1oZAsGuC_sCTO_mVYGCYwsI',
        appId: '1:83620169310:android:d2abeba5f7d9f5ab22d6cf',
        messagingSenderId: '83620169310',
        projectId: 'ppv-paye-pour-voir',
        storageBucket: 'ppv-paye-pour-voir.firebasestorage.app',
      ),
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  runApp(const PpvApp());
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

  @override
  void initState() {
    super.initState();
    _appRouter = widget.router ?? AppRouter();

    const storageService = SecureStorageService();
    final dioClient = DioClient(
      storageService: storageService,
      onSessionExpired: () => _appRouter.router.go(RouteNames.kRouteLogin),
    );
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
        themeMode: ThemeMode.light,
        routerConfig: _appRouter.router,
      ),
    );
  }
}
