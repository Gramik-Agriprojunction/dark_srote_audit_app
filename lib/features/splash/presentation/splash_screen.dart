import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/providers/auth_provider.dart';

/// Branded launch screen. Starts on the same white background as the native
/// splash so the hand-off is invisible, then animates the logo and wordmark in.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const minimumDuration = Duration(milliseconds: 2100);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  Timer? _minimumTimer;
  bool _minimumElapsed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  /// Hands over from the native splash once the real window size has settled.
  Future<void> _reveal() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    FlutterNativeSplash.remove();
    _controller.forward();
    _minimumTimer = Timer(SplashScreen.minimumDuration, () {
      _minimumElapsed = true;
      _maybeNavigate();
    });
  }

  @override
  void dispose() {
    _minimumTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _maybeNavigate() {
    if (_navigated || !mounted || !_minimumElapsed) return;
    final status = ref.read(authControllerProvider).status;
    if (status == AuthStatus.unknown) return;
    _navigated = true;
    context.go(status == AuthStatus.authenticated ? '/home' : '/login');
  }

  Animation<double> _fade(double begin, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (_, _) => _maybeNavigate());

    final logoFade = _fade(0, 0.45);
    final logoScale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    final textFade = _fade(0.35, 0.75);
    final footerFade = _fade(0.6, 1);

    return Scaffold(
      backgroundColor: Colors.white,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white, AppColors.primarySoft],
            stops: [0, 0.62, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: logoFade,
                        child: ScaleTransition(
                          scale: logoScale,
                          child: Image.asset(
                            AppAssets.logo,
                            width: 226,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: textFade,
                        child: Column(
                          children: [
                            Text(
                              'StockShield',
                              style: context.sora.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Smart Inventory • Accurate Stock',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              FadeTransition(
                opacity: footerFade,
                child: Column(
                  children: [
                    const _SplashProgress(),
                    const SizedBox(height: 18),
                    Text(
                      'Powered by GRAMiK',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.textMuted.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slim indeterminate bar that reads as "getting things ready".
class _SplashProgress extends StatefulWidget {
  const _SplashProgress();

  @override
  State<_SplashProgress> createState() => _SplashProgressState();
}

class _SplashProgressState extends State<_SplashProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const width = 108.0;
    const barWidth = 42.0;

    return SizedBox(
      width: width,
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(
              (_controller.value * 2 <= 1
                  ? _controller.value * 2
                  : 2 - _controller.value * 2),
            );
            return Align(
              alignment: Alignment(-1 + 2 * t, 0),
              child: Container(
                width: barWidth,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryMid, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
