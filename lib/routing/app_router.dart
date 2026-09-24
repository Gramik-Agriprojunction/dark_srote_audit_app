import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/theme_aware.dart';
import '../core/theme/theme_mode_provider.dart';
import '../core/widgets/animated_indexed_stack.dart';
import '../core/widgets/history_back_scope.dart';
import '../core/widgets/main_tab_shell.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/select_warehouse_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/stock_audit/presentation/home_screen.dart';
import '../features/stock_audit/presentation/my_products_screen.dart';
import '../features/stock_audit/presentation/transactions_screen.dart';
import '../features/stock_audit/presentation/variance_screen.dart';
import '../features/dc/presentation/dc_detail_screen.dart';
import '../features/dc/presentation/dc_list_screen.dart';
import '../features/orders/presentation/order_detail_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import '../features/orders/presentation/pickup_otp_enter_screen.dart';
import '../features/profile/presentation/inventory_report_screen.dart';
import '../features/profile/presentation/privacy_policy_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/stock_audit/presentation/variant_audit_screen.dart';
import 'page_transitions.dart';

/// Forces the page to rebuild/remount when theme flips (needed because
/// [AppColors] are static getters and stacked routes from `push` stay mounted).
Widget _themePage(Widget page) => ThemeAware(builder: (_, __) => page);

/// Stack screens get system-back → pop, or dashboard when opened via [go].
Widget _stackPage(Widget page) =>
    _themePage(HistoryBackScope(child: page));

Page<void> _smoothStack(GoRouterState state, Widget page) =>
    buildSmoothPage(key: state.pageKey, child: _stackPage(page));

Page<void> _smoothTheme(GoRouterState state, Widget page) =>
    buildSmoothPage(key: state.pageKey, child: _themePage(page));

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthState>(
    ref.read(authControllerProvider),
  );
  final themeNotifier = ValueNotifier<AppThemeMode>(
    ref.read(appThemeModeProvider),
  );

  ref.listen<AuthState>(authControllerProvider, (_, next) {
    authNotifier.value = next;
  });
  ref.listen<AppThemeMode>(appThemeModeProvider, (_, next) {
    themeNotifier.value = next;
  });

  ref.onDispose(() {
    authNotifier.dispose();
    themeNotifier.dispose();
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: Listenable.merge([authNotifier, themeNotifier]),
    redirect: (context, state) {
      final auth = authNotifier.value;
      final loc = state.matchedLocation;
      final loggingIn = loc == '/login';
      final selectingWarehouse = loc == '/select-warehouse';

      // Splash decides where to go itself, once the session has been restored.
      if (loc == '/splash') return null;

      if (auth.status == AuthStatus.unknown) return null;
      if (auth.status == AuthStatus.unauthenticated && !loggingIn) {
        return '/login';
      }
      if (auth.status == AuthStatus.authenticated) {
        if (loggingIn) {
          return auth.needsWarehouseSelection
              ? '/select-warehouse'
              : '/dashboard';
        }
        if (auth.needsWarehouseSelection && !selectingWarehouse) {
          return '/select-warehouse';
        }
        if (!auth.needsWarehouseSelection && selectingWarehouse) {
          return '/dashboard';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            _smoothTheme(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _smoothTheme(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/select-warehouse',
        pageBuilder: (context, state) =>
            _smoothTheme(state, const SelectWarehouseScreen()),
      ),
      GoRoute(
        path: '/home',
        redirect: (context, state) =>
            '/dashboard${state.uri.query.isNotEmpty ? '?${state.uri.query}' : ''}',
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return MainTabShell(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return AnimatedIndexedStack(
            index: navigationShell.currentIndex,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) =>
                    _themePage(const DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-products',
                builder: (context, state) => _themePage(
                  MyProductsScreen(
                    initialStatusFilter:
                        state.uri.queryParameters['filter'],
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) =>
                    _themePage(const OrdersScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/audit',
                builder: (context, state) =>
                    _themePage(const HomeScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            _smoothStack(state, const ProfileScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _smoothStack(state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/privacy-policy',
        pageBuilder: (context, state) =>
            _smoothStack(state, const PrivacyPolicyScreen()),
      ),
      GoRoute(
        path: '/report',
        pageBuilder: (context, state) =>
            _smoothStack(state, const InventoryReportScreen()),
      ),
      GoRoute(
        path: '/orders/:orderId',
        pageBuilder: (context, state) {
          final orderId =
              int.tryParse(state.pathParameters['orderId'] ?? '') ?? 0;
          if (orderId <= 0) {
            return _smoothTheme(state, const OrdersScreen());
          }
          return _smoothStack(state, OrderDetailScreen(orderId: orderId));
        },
        routes: [
          GoRoute(
            path: 'pickup-otp',
            pageBuilder: (context, state) {
              final orderId =
                  int.tryParse(state.pathParameters['orderId'] ?? '') ?? 0;
              final orderCode = state.extra is String
                  ? state.extra as String
                  : null;
              return _smoothStack(
                state,
                PickupOtpEnterScreen(
                  orderId: orderId,
                  orderCode: orderCode,
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/transactions',
        pageBuilder: (context, state) =>
            _smoothStack(state, const TransactionsScreen()),
      ),
      GoRoute(
        path: '/dc',
        pageBuilder: (context, state) {
          final tab = state.uri.queryParameters['tab'] ?? 'incoming';
          return _smoothStack(state, DcListScreen(initialTab: tab));
        },
      ),
      GoRoute(
        path: '/dc/:transferId',
        pageBuilder: (context, state) {
          final transferId =
              int.tryParse(state.pathParameters['transferId'] ?? '') ?? 0;
          final tab = state.uri.queryParameters['tab'] ?? 'incoming';
          if (transferId <= 0) {
            return _smoothStack(state, DcListScreen(initialTab: tab));
          }
          final canSave =
              tab == 'incoming' || tab == 'outgoing';
          return _smoothStack(
            state,
            DcDetailScreen(
              transferId: transferId,
              tab: tab,
              showSaveActions: canSave,
            ),
          );
        },
      ),
      GoRoute(
        path: '/variance',
        pageBuilder: (context, state) =>
            _smoothStack(state, const VarianceScreen()),
      ),
      GoRoute(
        path: '/variant-audit',
        pageBuilder: (context, state) {
          final storeId =
              int.tryParse(state.uri.queryParameters['storeId'] ?? '') ?? 0;
          final productId =
              int.tryParse(state.uri.queryParameters['productId'] ?? '') ?? 0;
          final variantId =
              int.tryParse(state.uri.queryParameters['variantId'] ?? '') ?? 0;
          if (storeId <= 0 || productId <= 0 || variantId <= 0) {
            return _smoothTheme(state, const HomeScreen());
          }
          return _smoothStack(
            state,
            VariantAuditScreen(
              storeId: storeId,
              productId: productId,
              variantId: variantId,
            ),
          );
        },
      ),
    ],
  );
});
