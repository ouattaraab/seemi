import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/services/fcm_service.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/features/auth/presentation/screens/profile_screen.dart';
import 'package:ppv_app/features/home/presentation/widgets/home_dashboard_tab.dart';
import 'package:ppv_app/features/notifications/presentation/notification_list_screen.dart';
import 'package:ppv_app/features/notifications/presentation/notification_provider.dart';
import 'package:ppv_app/features/wallet/presentation/wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 0 = Accueil, 1 = Upload (push), 2 = Portefeuille, 3 = Profil
  int _currentIndex = 0;

  // Mapping nav index → stack index (index 1 = Upload n'a pas de stack)
  int get _stackIndex => _currentIndex > 1 ? _currentIndex - 1 : _currentIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifProvider = context.read<NotificationProvider>();
      notifProvider.loadNotifications(refresh: true);

      FcmService.instance.listenForegroundMessages((_) {
        if (mounted) context.read<NotificationProvider>().loadNotifications(refresh: true);
      });

      FcmService.instance.listenMessageOpenedApp((_) {
        if (!mounted) return;
        _openNotificationScreen(context.read<NotificationProvider>());
      });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      body: IndexedStack(
        index: _stackIndex,
        children: const [
          HomeDashboardTab(), // stack 0 → nav 0
          WalletScreen(),     // stack 1 → nav 2
          ProfileScreen(),    // stack 2 → nav 3
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onIndexChanged: (i) => setState(() => _currentIndex = i),
        onUpload: () => context.push(RouteNames.kRouteUpload),
      ),
    );
  }
}

// ─── _BottomNav ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onUpload;

  const _BottomNav({
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.kBgSurface,
        border: Border(top: BorderSide(color: AppColors.kBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Accueil',
                isActive: currentIndex == 0,
                onTap: () => onIndexChanged(0),
              ),
              // ── Centre : bouton Publier surélevé ──────────────────────
              Expanded(
                child: GestureDetector(
                  onTap: onUpload,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.kPrimary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.kPrimary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Publier',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: 'Portefeuille',
                isActive: currentIndex == 2,
                onTap: () => onIndexChanged(2),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
                isActive: currentIndex == 3,
                onTap: () => onIndexChanged(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _NavItem ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indicateur pill actif
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 36 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.kPrimary,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? AppColors.kPrimary : AppColors.kTextTertiary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.kPrimary : AppColors.kTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
