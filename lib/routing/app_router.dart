import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/theme_aware.dart';
import '../core/theme/theme_mode_provider.dart';
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
import '../features/profile/presentation/profile_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/stock_audit/presentation/variant_audit_screen.dart';

/// Forces the page to rebuild/remount when theme flips (needed because
/// [AppColors] are static getters and stacked routes from `push` stay mounted).
Widget _themePage(Widget page) => ThemeAware(builder: (_, __) => page);

/// Stack screens get system-back → pop, or dashboard when opened via [go].
Widget _stackPage(Widget page) =>
    _themePage(HistoryBackScope(child: page));

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
        builder: (context, state) => _themePage(const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => _themePage(const LoginScreen()),
      ),
      GoRoute(
        path: '/select-warehouse',
        builder: (context, state) =>
            _themePage(const SelectWarehouseScreen()),
      ),
      GoRoute(
        path: '/home',
        redirect: (context, state) =>
            '/dashboard${state.uri.query.isNotEmpty ? '?${state.uri.query}' : ''}',
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainTabShell(navigationShell: navigationShell);
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
        builder: (context, state) => _stackPage(const ProfileScreen()),
      ),
      GoRoute(
        path: '/report',
        builder: (context, state) =>
            _stackPage(const InventoryReportScreen()),
      ),
      GoRoute(
        path: '/orders/:orderId',
        builder: (context, state) {
          final orderId =
              int.tryParse(state.pathParameters['orderId'] ?? '') ?? 0;
          if (orderId <= 0) return _themePage(const OrdersScreen());
          return _stackPage(OrderDetailScreen(orderId: orderId));
        },
        routes: [
          GoRoute(
            path: 'pickup-otp',
            builder: (context, state) {
              final orderId =
                  int.tryParse(state.pathParameters['orderId'] ?? '') ?? 0;
              final orderCode = state.extra is String
                  ? state.extra as String
                  : null;
              return _stackPage(
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
        builder: (context, state) => _stackPage(const TransactionsScreen()),
      ),
      GoRoute(
        path: '/dc',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'] ?? 'incoming';
          return _stackPage(DcListScreen(initialTab: tab));
        },
      ),
      GoRoute(
        path: '/dc/:transferId',
        builder: (context, state) {
          final transferId =
              int.tryParse(state.pathParameters['transferId'] ?? '') ?? 0;
          if (transferId <= 0) return _stackPage(const DcListScreen());
          final tab = state.uri.queryParameters['tab'] ?? 'incoming';
          return _stackPage(
            DcDetailScreen(
              transferId: transferId,
              showSaveActions: tab != 'received',
            ),
          );
        },
      ),
      GoRoute(
        path: '/variance',
        builder: (context, state) => _stackPage(const VarianceScreen()),
      ),
      GoRoute(
        path: '/variant-audit',
        builder: (context, state) {
          final storeId =
              int.tryParse(state.uri.queryParameters['storeId'] ?? '') ?? 0;
          final productId =
              int.tryParse(state.uri.queryParameters['productId'] ?? '') ?? 0;
          final variantId =
              int.tryParse(state.uri.queryParameters['variantId'] ?? '') ?? 0;
          if (storeId <= 0 || productId <= 0 || variantId <= 0) {
            return _themePage(const HomeScreen());
          }
          return _stackPage(
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
