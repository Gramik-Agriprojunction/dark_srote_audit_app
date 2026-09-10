import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/widgets/otp_pin_input.dart';

/// UI-only screen to enter Pickup OTP (no API yet).
class PickupOtpEnterScreen extends StatefulWidget {
  const PickupOtpEnterScreen({
    super.key,
    required this.orderId,
    this.orderCode,
  });

  final int orderId;
  final String? orderCode;

  @override
  State<PickupOtpEnterScreen> createState() => _PickupOtpEnterScreenState();
}

class _PickupOtpEnterScreenState extends State<PickupOtpEnterScreen> {
  final _otpController = TextEditingController();

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
      _otpController.text.trim().length == AppConfig.otpLength;

  void _onSubmit() {
    if (!_ready) return;
    // API will be wired later — UI only for now.
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final code = (widget.orderCode ?? '').trim();
    final subtitle = code.isNotEmpty
        ? code
        : 'Order #${widget.orderId}';

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
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Pickup OTP Dale',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 16 + bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pickup OTP enter karein',
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
                    child: const Text('Submit'),
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
