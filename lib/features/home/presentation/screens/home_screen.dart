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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.kBgBase,
          border: Border(top: BorderSide(color: AppColors.kBorder, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Accueil',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.add_box_outlined,
                  activeIcon: Icons.add_box_rounded,
                  label: 'Publier',
                  isActive: false,
                  onTap: () => context.push(RouteNames.kRouteUpload),
                ),
                _NavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: 'Portefeuille',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profil',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
            Icon(
              isActive ? activeIcon : icon,
              size: 26,
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
