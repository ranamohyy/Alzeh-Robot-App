import 'package:alzeh/core/resources/app_colors.dart';
import 'package:alzeh/core/resources/app_image.dart';
import 'package:flutter/material.dart';

class MenuItems extends StatelessWidget {
  const MenuItems(
      {super.key,
      required this.title,
      required this.icon,
      required this.onTap,
      this.isRed = false});
  final String icon;
  final String title;
  final VoidCallback onTap;
  final bool isRed;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(0),
      leading: AppImage.svgImage(
        icon,
        ColorFilter.mode(
          isRed ? Colors.red : AppColors.primaryColor,
          BlendMode.srcIn,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isRed ? Colors.red : AppColors.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_sharp, color: Colors.grey),
      onTap: onTap,
    );
  }
}
