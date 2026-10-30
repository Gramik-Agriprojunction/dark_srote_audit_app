import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_language_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/alert_banner.dart';
import '../../auth/presentation/widgets/otp_pin_input.dart';
import '../data/orders_repository.dart';

class PickupOtpEnterScreen extends ConsumerStatefulWidget {
  const PickupOtpEnterScreen({
    super.key,
    required this.orderId,
    this.orderCode,
  });

  final int orderId;
  final String? orderCode;

  @override
  ConsumerState<PickupOtpEnterScreen> createState() =>
      _PickupOtpEnterScreenState();
}

class _PickupOtpEnterScreenState extends ConsumerState<PickupOtpEnterScreen> {
  final _otpController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _otpController.removeListener(_refresh);
    _otpController.dispose();
    super.dispose();
  }

  bool get _ready =>
      _otpController.text.trim().length == AppConfig.otpLength && !_submitting;

  Future<void> _onSubmit() async {
    if (!_ready) return;
    final otp = _otpController.text.trim();
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(ordersRepositoryProvider).verifyPickupOtp(
            orderId: widget.orderId,
            otp: otp,
          );
      if (!mounted) return;
      context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = ref.read(appStringsProvider).tryAgain;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final code = (widget.orderCode ?? '').trim();
    final subtitle =
        code.isNotEmpty ? code : s.orderNumber(widget.orderId);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.headerBg,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.headerBg,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _submitting ? null : () => context.pop(),
          ),
          title: Text(
            s.pickupOtpTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 16 + bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.pickupOtpEnter,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  AlertBanner(message: _error!, isError: true),
                ],
                const SizedBox(height: 36),
                OtpPinInput(
                  controller: _otpController,
                  length: AppConfig.otpLength,
                  onCompleted: (_) => _onSubmit(),
                ),
                const Spacer(),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _ready ? _onSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.35),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(s.submit),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
