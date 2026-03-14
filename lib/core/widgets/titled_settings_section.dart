import 'package:chat/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TitledSettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> options;

  const TitledSettingsSection({
    super.key,
    required this.title,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.onSecondaryBackground,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: AppColors.white,
          ),
          child: Column(children: options),
        ),
      ],
    );
  }
}
