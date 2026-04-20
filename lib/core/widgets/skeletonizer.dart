import 'package:flutter/material.dart';

class Skeletonizer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const Skeletonizer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xffe0e0e0),
    this.highlightColor = const Color(0xfff5f5f5),
  });

  @override
  State<Skeletonizer> createState() => _SkeletonizerState();
}

class _SkeletonizerState extends State<Skeletonizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1, 0),
              end: Alignment(2, 0),
              colors: [widget.baseColor, widget.highlightColor, widget.baseColor],
              stops: [0, 0.5, 1],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      (bounds.width * 5 * slidePercent) - (bounds.width * 2),
      0,
      0,
    );
  }
}
