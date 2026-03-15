import 'package:chat/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsOption extends StatelessWidget {
  final String title;
  final IconData? iconData;
  final SvgPicture? customIcon;
  final VoidCallback callback;
  final bool? hasArrow;
  final bool? red;
  final bool? hasDivider;

  const SettingsOption({
    super.key,
    required this.title,
    required this.callback,
    this.iconData,
    this.customIcon,
    this.hasArrow,
    this.red,
    this.hasDivider,
  }) : assert(
         (iconData != null && customIcon == null) ||
             (iconData == null && customIcon != null),
         'Either iconData or customIcon must be provided, not both.',
       );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: callback,
      child: Padding(
        padding: const EdgeInsets.only(left: 30, right: 20.0, bottom: 8.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Row(
                children: [
                  iconData != null
                      ? FaIcon(
                          iconData,
                          color: red != null && red == true
                              ? AppColors.red
                              : AppColors.title,
                          size: 22,
                        )
                      : customIcon ?? SizedBox(width: 22),
                  SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        textStyle: red != null && red == true
                            ? Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: AppColors.red,
                              )
                            : Theme.of(context).textTheme.titleMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Spacer(),
                  hasArrow != null && hasArrow == false
                      ? SizedBox()
                      : SvgPicture.asset(
                          'assets/right_arrow.svg',
                          height: 20,
                          width: 20,
                          colorFilter: ColorFilter.mode(
                            const Color.fromARGB(164, 101, 100, 98),
                            BlendMode.srcIn,
                          ),
                        ),
                ],
              ),
              hasDivider != null && hasDivider == false
                  ? SizedBox()
                  : const Divider(indent: 40),
            ],
          ),
        ),
      ),
    );
  }
}
