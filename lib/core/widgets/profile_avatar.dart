import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileAvatar extends StatelessWidget {
  final Uint8List? imageData;
  final double radius;
  final Color backgroundColor;
  final Color iconColor;
  final IconData fallbackIcon;
  final double iconSize;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.imageData,
    required this.radius,
    required this.backgroundColor,
    required this.iconColor,
    this.fallbackIcon = FontAwesomeIcons.solidUser,
    this.iconSize = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: imageData != null ? MemoryImage(imageData!) : null,
      child: imageData == null
          ? FaIcon(fallbackIcon, size: iconSize, color: iconColor)
          : null,
    );

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}
