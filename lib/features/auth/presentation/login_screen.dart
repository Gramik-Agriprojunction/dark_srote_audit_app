import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/network/api_exception.dart';
import 'providers/auth_provider.dart';
import 'widgets/auth_theme.dart';
import 'widgets/otp_pin_input.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  Timer? _resendTimer;
  Timer? _expireTimer;
  bool _otpStep = false;
  bool _loading = false;
  String? _error;
  int _resendSeconds = 25;
  int _expireSeconds = 45;

  String get _mobile => _mobileController.text
      .replaceAll(RegExp(r'\D'), '')
      .substring(
        _mobileController.text.replaceAll(RegExp(r'\D'), '').length > 10
            ? _mobileController.text.replaceAll(RegExp(r'\D'), '').length - 10
            : 0,
      );

  bool get _validMobile => RegExp(r'^[6-9]\d{9}$').hasMatch(_mobile);

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_refresh);
    _otpController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _expireTimer?.cancel();
    _mobileController
      ..removeListener(_refresh)
      ..dispose();
    _otpController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _startTimers() {
    _resendTimer?.cancel();
    _expireTimer?.cancel();
    setState(() {
      _resendSeconds = 25;
      _expireSeconds = 45;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });

    _expireTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_expireSeconds <= 1) {
        timer.cancel();
        setState(() => _expireSeconds = 0);
      } else {
        setState(() => _expireSeconds--);
      }
    });
  }

  Future<void> _sendOtp({bool resend = false}) async {
    setState(() => _error = null);
    if (!_validMobile) {
      setState(() => _error = 'Valid 10-digit mobile number enter karein.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).sendOtp(_mobile);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _otpStep = true;
        if (!resend) _otpController.clear();
      });
      _startTimers();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Connection error. Dubara try karein.';
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 5 || _loading) return;
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(mobile: _mobile, otp: _otpController.text);
      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Connection error. Dubara try karein.';
      });
    }
  }

  void _backToLogin() {
    _resendTimer?.cancel();
    _expireTimer?.cancel();
    setState(() {
      _otpStep = false;
      _otpController.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _otpStep
          ? _OtpView(
              mobile: _mobile,
              controller: _otpController,
              loading: _loading,
              error: _error,
              resendSeconds: _resendSeconds,
              expireSeconds: _expireSeconds,
              onBack: _backToLogin,
              onVerify: _verifyOtp,
              onResend: () => _sendOtp(resend: true),
            )
          : _LoginView(
              controller: _mobileController,
              loading: _loading,
              error: _error,
              enabled: _validMobile,
              onSend: _sendOtp,
            ),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView({
    required this.controller,
    required this.loading,
    required this.error,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool loading;
  final String? error;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 375 + MediaQuery.paddingOf(context).top,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(AppAssets.authFarmHero, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.30),
                        Colors.white.withValues(alpha: 0.55),
                        Colors.white.withValues(alpha: 0.86),
                      ],
                      stops: const [0, 0.52, 1],
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Image.asset(
                        AppAssets.logo,
                        height: 96,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                      const SizedBox(height: 8),
                      Text('StockShield', style: AuthTheme.brandName()),
                      Text(
                        'Smart Inventory • Accurate Stock',
                        style: AuthTheme.caption(
                          AuthTheme.brandTagline,
                        ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 52,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      children: [
                        Text(
                          'Welcome Back! 👋',
                          style: AuthTheme.title(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Login to manage your store stock\nwith confidence.',
                          style: AuthTheme.body(),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -35),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.fromLTRB(25, 30, 25, 35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mobile Number', style: AuthTheme.label()),
                  const SizedBox(height: 10),
                  Container(
                    height: 58,
                    decoration: BoxDecoration(
                      border: Border.all(color: AuthTheme.line),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Row(
                      children: [
                        Container(
                          width: 76,
                          alignment: Alignment.center,
                          color: AuthTheme.inputBg,
                          child: Text(
                            '+91',
                            style: AuthTheme.body(
                              AuthTheme.ink,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.phone,
                            style: AuthTheme.body(AuthTheme.ink),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              hintText: 'Enter your mobile number',
                              hintStyle: AuthTheme.body(
                                const Color(0xFF9AA2AA),
                              ),
                            ),
                            onSubmitted: (_) {
                              if (enabled) onSend();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: AuthTheme.primary,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        "We'll send you a secure OTP",
                        style: AuthTheme.caption(const Color(0xFF6B756D)),
                      ),
                    ],
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorText(message: error!),
                  ],
                  const SizedBox(height: 20),
                  _PrimaryButton(
                    label: 'Send OTP',
                    loading: loading,
                    enabled: enabled,
                    onPressed: onSend,
                  ),
                  const SizedBox(height: 27),
                  _WhyDivider(),
                  const SizedBox(height: 20),
                  const _FeatureRow(
                    emoji: '🌱',
                    bg: AuthTheme.featureGreenBg,
                    title: 'Farmer First',
                    subtitle: 'Everything you need to grow\nyour business',
                  ),
                  const SizedBox(height: 17),
                  const _FeatureRow(
                    emoji: '📊',
                    bg: AuthTheme.featureYellowBg,
                    title: 'Smart Insights',
                    subtitle: 'AI-powered insights to make\nbetter decisions',
                  ),
                  const SizedBox(height: 17),
                  const _FeatureRow(
                    emoji: '🛡️',
                    bg: AuthTheme.featureGreenBg,
                    title: 'Secure & Reliable',
                    subtitle:
                        'Your data is safe with\nenterprise-grade security',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpView extends StatelessWidget {
  const _OtpView({
    required this.mobile,
    required this.controller,
    required this.loading,
    required this.error,
    required this.resendSeconds,
    required this.expireSeconds,
    required this.onBack,
    required this.onVerify,
    required this.onResend,
  });

  final String mobile;
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final int resendSeconds;
  final int expireSeconds;
  final VoidCallback onBack;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  String get _formattedMobile =>
      '+91 ${mobile.substring(0, 5)} ${mobile.substring(5)}';

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(25, top + 30, 25, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            elevation: 0,
            child: InkWell(
              onTap: loading ? null : onBack,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE7EAE7)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 16,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  '‹',
                  style: TextStyle(fontSize: 28, color: AuthTheme.ink),
                ),
              ),
            ),
          ),
          const SizedBox(height: 38),
          Center(
            child: Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: AuthTheme.shieldBg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AuthTheme.shieldBg.withValues(alpha: 0.65),
                    spreadRadius: 12,
                  ),
                  BoxShadow(
                    color: AuthTheme.brand.withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('🛡️', style: TextStyle(fontSize: 55)),
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              'Verify Your Number',
              style: AuthTheme.otpTitle(),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 9),
          Center(
            child: Text(
              "We've sent a 5-digit OTP to",
              style: AuthTheme.bodySm(),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _formattedMobile,
              style: AuthTheme.body(
                AuthTheme.primaryDark,
              ).copyWith(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 35),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 25, 18, 21),
            decoration: BoxDecoration(
              border: Border.all(color: AuthTheme.lineSoft),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                OtpPinInput(
                  controller: controller,
                  enabled: !loading,
                  onCompleted: (_) => onVerify(),
                ),
                const SizedBox(height: 18),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AuthTheme.caption(
                      const Color(0xFF727A75),
                    ).copyWith(fontSize: 13),
                    children: [
                      const TextSpan(text: 'OTP will expire in '),
                      TextSpan(
                        text: expireSeconds > 0
                            ? '00:${expireSeconds.toString().padLeft(2, '0')}'
                            : 'Expired',
                        style: AuthTheme.caption(
                          AuthTheme.timerGreen,
                        ).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AuthTheme.warningBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text('🔒', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Don't share your OTP with anyone",
                              style: AuthTheme.label().copyWith(fontSize: 13),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Gramik will never ask for your OTP',
                              style: AuthTheme.caption(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            _ErrorText(message: error!),
          ],
          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                Text("Didn't receive OTP?", style: AuthTheme.caption()),
                const SizedBox(height: 7),
                GestureDetector(
                  onTap: resendSeconds == 0 && !loading ? onResend : null,
                  child: RichText(
                    text: TextSpan(
                      style: AuthTheme.caption(
                        AuthTheme.resendGreen,
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                      children: [
                        const TextSpan(text: 'Resend OTP '),
                        TextSpan(
                          text: resendSeconds == 0
                              ? ''
                              : '(00:${resendSeconds.toString().padLeft(2, '0')})',
                          style: AuthTheme.caption(
                            const Color(0xFF7B837D),
                          ).copyWith(fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 45),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AuthTheme.secureBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AuthTheme.secureBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🔐', style: TextStyle(fontSize: 31)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Login',
                        style: AuthTheme.label().copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Your security is our priority. All data is encrypted and protected.',
                        style: AuthTheme.caption().copyWith(
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: enabled && !loading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthTheme.primary,
          disabledBackgroundColor: AuthTheme.primary.withValues(alpha: 0.45),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shadowColor: AuthTheme.primary.withValues(alpha: 0.22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('➤', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 9),
                  Text(label, style: AuthTheme.button()),
                ],
              ),
      ),
    );
  }
}

class _WhyDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AuthTheme.lineSoft)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Why StockShield?',
            style: AuthTheme.label(const Color(0xFF626B65)),
          ),
        ),
        Expanded(child: Divider(color: AuthTheme.lineSoft)),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.emoji,
    required this.bg,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final Color bg;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 47,
          height: 47,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 21)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AuthTheme.label().copyWith(fontSize: 14)),
              const SizedBox(height: 3),
              Text(subtitle, style: AuthTheme.caption()),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Text(message, style: AuthTheme.caption(const Color(0xFFC62828))),
    );
  }
}
