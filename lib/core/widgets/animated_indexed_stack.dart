import 'package:flutter/material.dart';

/// Keeps all [children] alive (like [IndexedStack]) but fades/slides when
/// [index] changes so tab switches feel smooth instead of instant.
class AnimatedIndexedStack extends StatefulWidget {
  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeInOutCubic,
  });

  final int index;
  final List<Widget> children;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _displayIndex;
  int _direction = 1;
  int _switchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _displayIndex = widget.index;
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..value = 1;
  }

  @override
  void didUpdateWidget(covariant AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == _displayIndex) return;

    _direction = widget.index > _displayIndex ? 1 : -1;
    final gen = ++_switchGeneration;
    _controller.reverse().then((_) {
      if (!mounted || gen != _switchGeneration) return;
      setState(() => _displayIndex = widget.index);
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = _displayIndex.clamp(0, widget.children.length - 1);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = widget.curve.transform(_controller.value);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(14 * (1 - t) * _direction, 0),
            child: child,
          ),
        );
      },
      child: IndexedStack(
        index: safeIndex,
        sizing: StackFit.expand,
        children: widget.children,
      ),
    );
  }
}
