import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared soft fade + slide for stack pushes (profile, order detail, DC, …).
CustomTransitionPage<T> buildSmoothPage<T>({
  required LocalKey key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 340),
  Duration reverseDuration = const Duration(milliseconds: 280),
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final slide = Tween<Offset>(
        begin: const Offset(0.06, 0),
        end: Offset.zero,
      ).animate(curved);
      final fade = Tween<double>(begin: 0, end: 1).animate(curved);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
