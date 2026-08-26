import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/gramik_brand_icon.dart';
import 'providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpStep = false;
  String? _error;
  String? _success;
  bool _loading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _mobile =>
      _mobileController.text.replaceAll(RegExp(r'\D'), '').substring(
            _mobileController.text.replaceAll(RegExp(r'\D'), '').length > 10
                ? _mobileController.text.replaceAll(RegExp(r'\D'), '').length - 10
                : 0,
          );

  bool get _isValidMobile => RegExp(r'^[6-9]\d{9}$').hasMatch(_mobile);

  Future<void> _sendOtp() async {
    setState(() {
      _error = null;
      _success = null;
    });

    if (!_isValidMobile) {
      setState(() => _error = 'Valid 10-digit mobile number enter karein (6-9 se start).');
      return;
    }

    setState(() => _loading = true);
    try {
      final message = await ref.read(authControllerProvider.notifier).sendOtp(_mobile);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _otpStep = true;
        _success = message.isNotEmpty ? message : 'OTP aapke mobile par bhej diya gaya.';
      });
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
    setState(() {
      _error = null;
      _success = null;
    });

    final otp = _otpController.text.trim();
    if (otp.length != 5) {
      setState(() => _error = '5 digit OTP enter karein.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).verifyOtp(mobile: _mobile, otp: otp);
      if (!mounted) return;
      setState(() => _loading = false);
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

  void _changeMobile() {
    setState(() {
      _otpStep = false;
      _otpController.clear();
      _error = null;
      _success = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _HeroPanel(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _otpStep ? 'OTP verify karein' : 'Welcome',
                        style: context.sora.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _otpStep
                            ? '+91 $_mobile par bheja gaya OTP enter karein'
                            : 'Apna mobile number enter karein, OTP aayega',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_error != null) ...[
                        AlertBanner(message: _error!, isError: true),
                        const SizedBox(height: 14),
                      ],
                      if (_success != null) ...[
                        AlertBanner(message: _success!, isError: false),
                        const SizedBox(height: 14),
                      ],
                      if (!_otpStep) ...[
                        const Text(
                          'MOBILE NUMBER',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone_outlined, size: 20),
                            prefixText: '+91 ',
                            hintText: '9876543210',
                          ),
                          onSubmitted: (_) => _sendOtp(),
                        ),
                        const SizedBox(height: 16),
                        LoadingButton(
                          label: 'OTP bhejein',
                          isLoading: _loading,
                          onPressed: _sendOtp,
                        ),
                      ] else ...[
                        Text(
                          '+91 $_mobile',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'OTP',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(5),
                          ],
                          decoration: const InputDecoration(hintText: '12345'),
                          onSubmitted: (_) => _verifyOtp(),
                        ),
                        const SizedBox(height: 16),
                        LoadingButton(
                          label: 'Login karein',
                          isLoading: _loading,
                          onPressed: _verifyOtp,
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _loading ? null : _changeMobile,
                          child: const Text('Mobile number change karein'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sora = GoogleFonts.sora();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 28, 24, 36),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E483A), Color(0x2617877A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GramikBrandIcon(size: 42),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gramik Lens',
                    style: sora.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'LOGICAL ENTERPRISE NETWORK SYSTEM',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.55),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Empowering 5 lac+ farmers',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Grow smarter,\nmanage better.',
            style: sora.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Mobile se login karein — OTP aapke number par aayega.',
            style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}
