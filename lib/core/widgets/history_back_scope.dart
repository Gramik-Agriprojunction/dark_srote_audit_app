import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Ensures the system back button pops the route stack when possible,
/// otherwise returns to [fallbackLocation] instead of closing the app.
class HistoryBackScope extends StatelessWidget {
  const HistoryBackScope({
    super.key,
    required this.child,
    this.fallbackLocation = '/dashboard',
  });

  final Widget child;
  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(fallbackLocation);
      },
      child: child,
    );
  }
}
