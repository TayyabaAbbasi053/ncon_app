import 'package:flutter/material.dart';
import '../utils/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final bool showBackButton;
  final Widget leading;

  const CustomAppBar({
    super.key, // Fixed: Using super.key
    required this.title,
    this.actions = const [],
    this.showBackButton = false,
    this.leading = const SizedBox(),
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      title: Text(
        title,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: actions,
      automaticallyImplyLeading: showBackButton,
      leading: leading,
      iconTheme: IconThemeData(
        color: AppColors.primary,
      ),
    );
  }
}