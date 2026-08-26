import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/stock_audit/presentation/home_screen.dart';
import '../features/stock_audit/presentation/my_products_screen.dart';
import '../features/stock_audit/presentation/variant_audit_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthState>(ref.read(authControllerProvider));

  ref.listen<AuthState>(authControllerProvider, (_, next) {
    authNotifier.value = next;
  });

  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final auth = authNotifier.value;
      final loggingIn = state.matchedLocation == '/login';

      if (auth.status == AuthStatus.unknown) return null;
      if (auth.status == AuthStatus.unauthenticated && !loggingIn) return '/login';
      if (auth.status == AuthStatus.authenticated && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/my-products',
        builder: (context, state) => const MyProductsScreen(),
      ),
      GoRoute(
        path: '/variant-audit',
        builder: (context, state) {
          final storeId = int.tryParse(state.uri.queryParameters['storeId'] ?? '') ?? 0;
          final productId = int.tryParse(state.uri.queryParameters['productId'] ?? '') ?? 0;
          final variantId = int.tryParse(state.uri.queryParameters['variantId'] ?? '') ?? 0;
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
