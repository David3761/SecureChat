import 'package:chat/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback callback;
  final bool? hasArrow;
  final bool? red;

  const SettingsOption({
    super.key,
    required this.title,
    required this.icon,
    required this.callback,
    this.hasArrow,
    this.red,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: callback,
      child: Padding(
        padding: const EdgeInsets.only(left: 28.0, right: 20.0, bottom: 8.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              Row(
                children: [
                  FaIcon(
                    icon,
                    color: red != null && red == true
                        ? AppColors.red
                        : AppColors.title,
                    size: 24,
                  ),
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
              const Divider(indent: 40),
            ],
          ),
        ),
      ),
    );
  }
}
