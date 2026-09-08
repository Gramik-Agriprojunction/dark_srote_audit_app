import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../features/profile/presentation/profile_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/stock_audit/presentation/variant_audit_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthState>(
    ref.read(authControllerProvider),
  );

  ref.listen<AuthState>(authControllerProvider, (_, next) {
    authNotifier.value = next;
  });

  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
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
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/select-warehouse',
        builder: (context, state) => const SelectWarehouseScreen(),
      ),
      GoRoute(
        path: '/home',
        redirect: (context, state) =>
            '/dashboard${state.uri.query.isNotEmpty ? '?${state.uri.query}' : ''}',
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/audit',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/orders/:orderId',
        builder: (context, state) {
          final orderId =
              int.tryParse(state.pathParameters['orderId'] ?? '') ?? 0;
          if (orderId <= 0) return const OrdersScreen();
          return OrderDetailScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/my-products',
        builder: (context, state) => const MyProductsScreen(),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        path: '/dc',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'] ?? 'incoming';
          return DcListScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: '/dc/:transferId',
        builder: (context, state) {
          final transferId =
              int.tryParse(state.pathParameters['transferId'] ?? '') ?? 0;
          if (transferId <= 0) return const DcListScreen();
          final tab = state.uri.queryParameters['tab'] ?? 'incoming';
          return DcDetailScreen(
            transferId: transferId,
            showSaveActions: tab != 'received',
          );
        },
      ),
      GoRoute(
        path: '/variance',
        builder: (context, state) => const VarianceScreen(),
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
            return const HomeScreen();
          }
          return VariantAuditScreen(
            storeId: storeId,
            productId: productId,
            variantId: variantId,
          );
        },
      ),
    ],
  );
});
