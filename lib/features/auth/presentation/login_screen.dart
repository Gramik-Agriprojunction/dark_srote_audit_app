import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_brand_header.dart';
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
      context.go('/audit');
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
        statusBarColor: AuthTheme.primary,
      ),
      child: Scaffold(
        backgroundColor: _otpStep ? AuthTheme.primary : AuthTheme.screenBg,
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

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AuthTheme.primary,
            padding: EdgeInsets.fromLTRB(24, top + 40, 24, 48),
            child: const AppBrandMark(size: AppBrandMarkSize.hero),
          ),
          Transform.translate(
            offset: const Offset(0, -28),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AuthTheme.cardBorder, width: 0.5),
                boxShadow: AppColors.cardShadow,
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
                    style: AuthTheme.bodySm(),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AuthTheme.inputBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AuthTheme.line),
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
                                  const Color(0xFF555555),
                                ).copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: const Color(0xFFDDDDDD),
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.phone,
                            style: AuthTheme.label().copyWith(
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
                                const Color(0xFFBBBBBB),
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
                  _FeatureDot(text: 'Stock audit karo real-time'),
                  const SizedBox(height: 10),
                  _FeatureDot(text: 'Inventory variance track karo'),
                  const SizedBox(height: 10),
                  _FeatureDot(text: 'Pickup & RTO transactions dekho'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: RichText(
              text: TextSpan(
                style: AuthTheme.caption(const Color(0xFFCCCCCC)),
                children: [
                  const TextSpan(text: 'Powered by '),
                  TextSpan(
                    text: 'Gramik',
                    style: AuthTheme.caption(
                      const Color(0xFFBBBBBB),
                    ).copyWith(fontWeight: FontWeight.w700),
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

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, top + 12, 24, 32),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.white.withValues(alpha: 0.2),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: loading ? null : onBack,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Text(
                      '←',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                AuthTheme.primary,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                AppAssets.shopIcon,
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('OTP Daalo', style: AuthTheme.otpTitle()),
          const SizedBox(height: 6),
          Text(
            AppConfig.skipSmsOtp
                ? 'Testing mode — SMS nahi bheja gaya'
                : 'Tumhare number pe OTP bheja hai',
            style: AuthTheme.bodySm(
              Colors.white.withValues(alpha: 0.7),
            ),
          ),
          if (AppConfig.skipSmsOtp) ...[
            const SizedBox(height: 6),
            Text(
              'Master OTP enter karke login karein',
              style: AuthTheme.caption(
                Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+91 $mobile',
              style: AuthTheme.label(Colors.white).copyWith(
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
            inverted: true,
            onCompleted: (_) => onVerify(),
          ),
          const SizedBox(height: 28),
          if (!AppConfig.skipSmsOtp)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'OTP nahi aaya? ',
                  style: AuthTheme.bodySm(
                    Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                GestureDetector(
                  onTap: resendSeconds == 0 && !loading ? onResend : null,
                  child: Text(
                    loading && resendSeconds == 0
                        ? 'Bhej rahe hai...'
                        : resendSeconds == 0
                            ? 'Dubara Bhejo'
                            : 'Dubara Bhejo (00:${resendSeconds.toString().padLeft(2, '0')})',
                    style: AuthTheme.bodySm(Colors.white).copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          if (!AppConfig.skipSmsOtp && expireSeconds > 0) ...[
            const SizedBox(height: 10),
            Text(
              'OTP expire: 00:${expireSeconds.toString().padLeft(2, '0')}',
              style: AuthTheme.caption(
                Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            _ErrorText(message: error!, onPrimary: true),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: canVerify ? onVerify : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                foregroundColor: AuthTheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AuthTheme.primary,
                      ),
                    )
                  : Text(
                      'Verify Karo',
                      style: AuthTheme.button(AuthTheme.primary),
                    ),
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
      height: 50,
      child: ElevatedButton(
        onPressed: enabled && !loading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthTheme.primary,
          disabledBackgroundColor: AuthTheme.primary.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
            : Text(label, style: AuthTheme.button()),
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
          decoration: const BoxDecoration(
            color: AuthTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: AuthTheme.bodySm(const Color(0xFF888888))),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message, this.onPrimary = false});

  final String message;
  final bool onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: onPrimary
            ? Colors.white.withValues(alpha: 0.15)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onPrimary
              ? Colors.white.withValues(alpha: 0.25)
              : const Color(0xFFFFCDD2),
        ),
      ),
      child: Text(
        message,
        style: AuthTheme.caption(
          onPrimary ? Colors.white : const Color(0xFFC62828),
        ),
      ),
    );
  }
}
