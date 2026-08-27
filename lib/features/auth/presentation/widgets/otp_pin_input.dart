import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_theme.dart';

class OtpPinInput extends StatefulWidget {
  const OtpPinInput({
    super.key,
    required this.controller,
    this.length = 5,
    this.onCompleted,
    this.enabled = true,
    this.inverted = false,
  });

  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;
  final bool enabled;
  final bool inverted;

  @override
  State<OtpPinInput> createState() => _OtpPinInputState();
}

class _OtpPinInputState extends State<OtpPinInput> {
  final _focusNode = FocusNode();
  bool _completionSent = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    final complete = widget.controller.text.length == widget.length;
    if (complete && !_completionSent) {
      _completionSent = true;
      widget.onCompleted?.call(widget.controller.text);
    } else if (!complete) {
      _completionSent = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;
    final activeIndex = value.length >= widget.length
        ? widget.length - 1
        : value.length;
    final inverted = widget.inverted;

    return GestureDetector(
      onTap: widget.enabled ? _focusNode.requestFocus : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 1,
            height: 1,
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (index) {
              final filled = index < value.length;
              final focused = widget.enabled && index == activeIndex && !filled;
              final active = focused || filled;

              Color bg;
              Color border;
              Color digitColor;

              if (inverted) {
                bg = active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.15);
                border = active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2);
                digitColor = AuthTheme.ink;
              } else {
                bg = Colors.white;
                border = focused ? AuthTheme.primary : AuthTheme.line;
                digitColor = AuthTheme.ink;
              }

              return Container(
                width: inverted ? 56 : 45,
                height: inverted ? 56 : 53,
                margin: EdgeInsets.only(
                  right: index == widget.length - 1 ? 0 : (inverted ? 10 : 8),
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(inverted ? 14 : 12),
                  border: Border.all(
                    color: border,
                    width: inverted ? 2 : (focused ? 1.5 : 1),
                  ),
                  boxShadow: !inverted && focused
                      ? [
                          BoxShadow(
                            color: AuthTheme.primary.withValues(alpha: 0.1),
                            blurRadius: 0,
                            spreadRadius: 3,
                          ),
                        ]
                      : null,
                ),
                child: filled
                    ? Text(
                        value[index],
                        style: GoogleFonts.inter(
                          fontSize: inverted ? 28 : 21,
                          fontWeight: FontWeight.w800,
                          color: digitColor,
                        ),
                      )
                    : (inverted && !active
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: focused
                                  ? AuthTheme.primary
                                  : Colors.white.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          )
                        : null),
              );
            }),
          ),
        ],
      ),
    );
  }
}
