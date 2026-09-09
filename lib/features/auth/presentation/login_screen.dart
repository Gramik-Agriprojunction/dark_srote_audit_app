import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/app_config.dart';
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

  bool get _otpReady {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || _loading) return false;
    if (otp.length == AppConfig.otpLength) return true;
    if (AppConfig.isMasterOtp(otp)) return true;
    return otp.length >= 4 && otp.length < AppConfig.otpLength;
  }

  Future<void> _verifyOtp() async {
    if (!_otpReady) return;
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(mobile: _mobile, otp: _otpController.text.trim());
      if (!mounted) return;
      final auth = ref.read(authControllerProvider);
      if (auth.status != AuthStatus.authenticated) {
        setState(() {
          _loading = false;
          _error = auth.error ?? 'Login failed';
        });
        return;
      }
      context.go(
        auth.needsWarehouseSelection ? '/select-warehouse' : '/dashboard',
      );
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AuthTheme.screenBg,
      ),
      child: Scaffold(
        backgroundColor: AuthTheme.screenBg,
        body: _otpStep
            ? _OtpView(
                mobile: _mobile,
                controller: _otpController,
                loading: _loading,
                error: _error,
                resendSeconds: _resendSeconds,
                expireSeconds: _expireSeconds,
                canVerify: _otpReady,
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
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final dark = AppColors.isDark;

    if (!dark) {
      return ColoredBox(
        color: AppColors.background,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: AppColors.primary,
                padding: EdgeInsets.fromLTRB(24, top + 40, 24, 48),
                child: const _LoginBrandHeader(onOrange: true),
              ),
              Transform.translate(
                offset: const Offset(0, -28),
                child: _LoginFormCard(
                  controller: controller,
                  loading: loading,
                  error: error,
                  enabled: enabled,
                  onSend: onSend,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 20),
                child: RichText(
                  text: TextSpan(
                    style: AuthTheme.caption(AppColors.textMuted),
                    children: [
                      const TextSpan(text: 'Powered by '),
                      TextSpan(
                        text: 'Gramik',
                        style: AuthTheme.caption(AppColors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        const Positioned.fill(child: _LoginAmbientGlow()),
        SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(20, top + 36, 20, bottom + 20),
          child: Column(
            children: [
              const _LoginBrandHeader(),
              const SizedBox(height: 36),
              _LoginFormCard(
                controller: controller,
                loading: loading,
                error: error,
                enabled: enabled,
                onSend: onSend,
              ),
              const SizedBox(height: 28),
              RichText(
                text: TextSpan(
                  style: AuthTheme.caption(AppColors.textMuted),
                  children: [
                    const TextSpan(text: 'Powered by '),
                    TextSpan(
                      text: 'Gramik',
                      style: AuthTheme.caption(AppColors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AuthTheme.cardBorder),
        boxShadow: AppColors.isDark ? null : AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Apna Number Daalo', style: AuthTheme.title()),
          const SizedBox(height: 4),
          Text(
            AppConfig.skipSmsOtp
                ? 'Testing mode — master OTP se login karein'
                : 'Number daalo, hum OTP bhej denge turant',
            style: AuthTheme.bodySm(AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.isDark ? AuthTheme.inputBg : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.isDark ? AuthTheme.lineSoft : AppColors.primary,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 5),
                      Text(
                        '+91',
                        style: AuthTheme.label(
                          AppColors.isDark
                              ? AppColors.textSecondary
                              : const Color(0xFFCCCCCC),
                        ).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: AppColors.isDark
                      ? AuthTheme.line
                      : const Color(0xFF555555),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    cursorColor: AuthTheme.primary,
                    style: AuthTheme.label(
                      AppColors.isDark
                          ? AppColors.textPrimary
                          : Colors.white,
                    ).copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      hintText: 'Mobile Number',
                      hintStyle: AuthTheme.bodySm(
                        AppColors.isDark
                            ? AppColors.textMuted
                            : const Color(0xFF888888),
                      ).copyWith(fontSize: 16),
                    ),
                    onSubmitted: (_) {
                      if (enabled) onSend();
                    },
                  ),
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            _ErrorText(message: error!),
          ],
          const SizedBox(height: 18),
          _PrimaryButton(
            label: AppConfig.skipSmsOtp ? 'Aage Badho  →' : 'OTP Bhejo  →',
            loading: loading,
            enabled: enabled,
            onPressed: onSend,
          ),
          const SizedBox(height: 28),
          const _FeatureDot(text: 'Stock audit karo real-time'),
          const SizedBox(height: 10),
          const _FeatureDot(text: 'Inventory variance track karo'),
          const SizedBox(height: 10),
          const _FeatureDot(text: 'Pickup & RTO transactions dekho'),
        ],
      ),
    );
  }
}

class _LoginAmbientGlow extends StatelessWidget {
  const _LoginAmbientGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AuthTheme.primary.withValues(alpha: 0.22),
                    AuthTheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AuthTheme.primary.withValues(alpha: 0.16),
                    AuthTheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBrandHeader extends StatelessWidget {
  const _LoginBrandHeader({this.onOrange = false});

  final bool onOrange;

  @override
  Widget build(BuildContext context) {
    final titleColor = onOrange || AppColors.isDark
        ? Colors.white
        : AppColors.textPrimary;
    final subtitleColor = onOrange
        ? Colors.white.withValues(alpha: 0.75)
        : AppColors.textSecondary;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: onOrange ? Colors.white.withValues(alpha: 0.18) : null,
            gradient: onOrange
                ? null
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF06A1A),
                      Color(0xFFEC5800),
                      Color(0xFFD04E00),
                    ],
                  ),
            boxShadow: onOrange
                ? null
                : [
                    BoxShadow(
                      color: AuthTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              AppAssets.shopIcon,
              width: 34,
              height: 34,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Gramik',
          style: AuthTheme.brandNameBold(titleColor).copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Dark Store',
          style: AuthTheme.caption(subtitleColor).copyWith(fontSize: 13),
        ),
      ],
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
    required this.canVerify,
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
  final bool canVerify;
  final VoidCallback onBack;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        const Positioned.fill(child: _LoginAmbientGlow()),
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, top + 12, 24, 32),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: AppColors.fieldBg,
                  shape: CircleBorder(
                    side: BorderSide(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: loading ? null : onBack,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 28),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFF06A1A),
                      AuthTheme.primary,
                      AuthTheme.primaryDark,
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    AppAssets.shopIcon,
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('OTP Daalo', style: AuthTheme.title(AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text(
                AppConfig.skipSmsOtp
                    ? 'Testing mode — SMS nahi bheja gaya'
                    : 'Tumhare number pe OTP bheja hai',
                style: AuthTheme.bodySm(AppColors.textSecondary),
              ),
              if (AppConfig.skipSmsOtp) ...[
                const SizedBox(height: 6),
                Text(
                  'Master OTP enter karke login karein',
                  style: AuthTheme.caption(AppColors.textMuted),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.fieldBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '+91 $mobile',
                  style: AuthTheme.label(AppColors.textPrimary).copyWith(
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              OtpPinInput(
                controller: controller,
                length: AppConfig.otpLength,
                enabled: !loading,
                inverted: false,
                onCompleted: (_) => onVerify(),
              ),
              const SizedBox(height: 28),
              if (!AppConfig.skipSmsOtp)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'OTP nahi aaya? ',
                      style: AuthTheme.bodySm(AppColors.textMuted),
                    ),
                    GestureDetector(
                      onTap: resendSeconds == 0 && !loading ? onResend : null,
                      child: Text(
                        loading && resendSeconds == 0
                            ? 'Bhej rahe hai...'
                            : resendSeconds == 0
                                ? 'Dubara Bhejo'
                                : 'Dubara Bhejo (00:${resendSeconds.toString().padLeft(2, '0')})',
                        style: AuthTheme.bodySm(AuthTheme.primary).copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AuthTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              if (!AppConfig.skipSmsOtp && expireSeconds > 0) ...[
                const SizedBox(height: 10),
                Text(
                  'OTP expire: 00:${expireSeconds.toString().padLeft(2, '0')}',
                  style: AuthTheme.caption(AppColors.textMuted),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                _ErrorText(message: error!),
              ],
              const SizedBox(height: 28),
              _PrimaryButton(
                label: 'Verify Karo',
                loading: loading,
                enabled: canVerify,
                onPressed: onVerify,
              ),
            ],
          ),
        ),
      ],
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
    final active = enabled && !loading;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: active
                ? [
                    Color(0xFFF06A1A),
                    AuthTheme.primary,
                    AuthTheme.primaryDark,
                  ]
                : [
                    AuthTheme.primary.withValues(alpha: 0.35),
                    AuthTheme.primaryDark.withValues(alpha: 0.35),
                  ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: active ? onPressed : null,
            borderRadius: BorderRadius.circular(14),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: AuthTheme.button().copyWith(
                        color: Colors.white.withValues(alpha: active ? 1 : 0.7),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureDot extends StatelessWidget {
  const _FeatureDot({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AuthTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: AuthTheme.bodySm(AppColors.textSecondary)),
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
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Text(
        message,
        style: AuthTheme.caption(AppColors.errorText),
      ),
    );
  }
}
