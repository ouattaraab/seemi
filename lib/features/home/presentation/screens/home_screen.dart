import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/services/fcm_service.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/features/auth/presentation/screens/profile_screen.dart';
import 'package:ppv_app/features/content/presentation/widgets/my_contents_tab.dart';
import 'package:ppv_app/features/notifications/presentation/notification_list_screen.dart';
import 'package:ppv_app/features/notifications/presentation/notification_provider.dart';

/// Écran principal — 3 onglets : Accueil | Publier (FAB) | Profil & Gains.
///
/// Le contenu du portefeuille (Gains) est intégré dans l'onglet Profil.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0 = Accueil, 1 = FAB (skip), 2 = Profil
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifProvider = context.read<NotificationProvider>();

      // Chargement initial du badge et de la liste.
      notifProvider.loadNotifications(refresh: true);

      // ── FCM foreground : rafraîchit le badge en temps réel ──────────────
      // Quand une notification push arrive pendant que l'app est ouverte,
      // on recharge la liste pour mettre à jour le compteur non lu.
      FcmService.instance.listenForegroundMessages((_) {
        if (mounted) {
          context.read<NotificationProvider>().loadNotifications(refresh: true);
        }
      });

      // ── FCM background tap : ouvre l'écran Notifications ────────────────
      // Quand l'utilisateur tape sur une notif système (app était en arrière-plan).
      FcmService.instance.listenMessageOpenedApp((_) {
        if (!mounted) return;
        _openNotificationScreen(context.read<NotificationProvider>());
      });

      // ── FCM terminated tap : app lancée via notif ────────────────────────
      FcmService.instance.getInitialMessage().then((msg) {
        if (msg != null && mounted) {
          _openNotificationScreen(context.read<NotificationProvider>());
        }
      });
    });
  }

  @override
  void dispose() {
    FcmService.instance.cancelMessageListeners();
    super.dispose();
  }

  void _openNotificationScreen(NotificationProvider provider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const NotificationListScreen(),
        ),
      ),
    );
  }

  String get _appBarTitle => switch (_currentIndex) {
        2 => 'Mon Profil',
        _ => 'SeeMi',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      appBar: AppBar(
        backgroundColor: AppColors.kBgBase,
        title: Text(
          _appBarTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => _openNotificationScreen(provider),
                  ),
                  if (provider.unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.kError,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          provider.unreadCount > 99
                              ? '99+'
                              : '${provider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          MyContentsTab(),       // 0 – Accueil
          SizedBox.shrink(),     // 1 – FAB placeholder (jamais affiché)
          ProfileScreen(),       // 2 – Profil + Gains
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => context.push(RouteNames.kRouteUpload),
        backgroundColor: AppColors.kPrimary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 34),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: AppColors.kBgBase,
        selectedItemColor: AppColors.kPrimary,
        unselectedItemColor: AppColors.kTextTertiary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        elevation: 12,
        onTap: (index) {
          if (index == 1) return; // FAB tab — skip
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 28),
            activeIcon: Icon(Icons.home_rounded, size: 28),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: SizedBox.shrink(),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 28),
            activeIcon: Icon(Icons.person_rounded, size: 28),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
