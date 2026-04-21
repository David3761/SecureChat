import 'dart:typed_data';
import 'dart:ui';

import 'package:chat/core/theme/theme.dart';
import 'package:chat/core/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double paddingTop;
  final String displayName;
  final String memberCountStr;
  final bool isAdmin;
  final VoidCallback onBack;
  final VoidCallback onQr;
  final VoidCallback onEdit;
  final Color backgroundColor;
  final Color scrolledColor;
  final Uint8List? profilePicData;
  final VoidCallback? onTapAvatar;

  GroupHeaderDelegate({
    required this.paddingTop,
    required this.displayName,
    required this.memberCountStr,
    required this.isAdmin,
    required this.onBack,
    required this.onQr,
    required this.onEdit,
    required this.backgroundColor,
    required this.scrolledColor,
    this.profilePicData,
    this.onTapAvatar,
  });

  @override
  double get minExtent => kToolbarHeight + paddingTop;

  @override
  double get maxExtent => 260.0 + paddingTop;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final shrinkPercentage = (shrinkOffset / (maxExtent - minExtent)).clamp(
      0.0,
      1.0,
    );

    final expandedOpacity = (1 - shrinkPercentage * 3.0).clamp(0.0, 1.0);
    final collapsedOpacity = (shrinkPercentage * 4 - 1).clamp(0.0, 1.0);

    final currentBgColor = Color.lerp(
      backgroundColor,
      scrolledColor,
      shrinkPercentage,
    );

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: EdgeInsets.only(top: paddingTop),
          decoration: BoxDecoration(
            color: currentBgColor,
            border: Border(
              bottom: BorderSide(
                color: AppColors.onSecondaryBackground.withValues(
                  alpha: 0.15 * shrinkPercentage,
                ),
                width: 0.5,
              ),
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: expandedOpacity,
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ProfileAvatar(
                          imageData: profilePicData,
                          radius: 50,
                          backgroundColor: AppColors.primaryBlue.withValues(
                            alpha: 0.2,
                          ),
                          iconColor: AppColors.primaryBlue,
                          fallbackIcon: FontAwesomeIcons.userGroup,
                          iconSize: 34,
                          onTap: onTapAvatar,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.title,
                              ),
                        ),
                        if (memberCountStr.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            memberCountStr,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              Opacity(
                opacity: collapsedOpacity,
                child: Container(
                  height: kToolbarHeight,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 64),
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.angleLeft,
                    color: AppColors.title,
                    size: 24,
                  ),
                  onPressed: onBack,
                ),
              ),

              Positioned(
                top: 4,
                right: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.qrcode,
                        color: AppColors.title,
                        size: 20,
                      ),
                      onPressed: onQr,
                    ),
                    if (isAdmin)
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.pen,
                          color: AppColors.title,
                          size: 18,
                        ),
                        onPressed: onEdit,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant GroupHeaderDelegate oldDelegate) {
    return displayName != oldDelegate.displayName ||
        memberCountStr != oldDelegate.memberCountStr ||
        paddingTop != oldDelegate.paddingTop ||
        isAdmin != oldDelegate.isAdmin ||
        backgroundColor != oldDelegate.backgroundColor ||
        scrolledColor != oldDelegate.scrolledColor ||
        profilePicData != oldDelegate.profilePicData;
  }
}
