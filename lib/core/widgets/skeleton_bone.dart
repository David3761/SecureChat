import 'package:flutter/material.dart';

class SkeletonBone extends StatelessWidget {
  final double? height;
  final double? width;
  final BoxShape shape;

  const SkeletonBone({
    super.key,
    this.height,
    this.width,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(6),
      ),
    );
  }
}
