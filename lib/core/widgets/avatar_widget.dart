import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AvatarWidget extends StatelessWidget {
  final String name;
  final double size;
  final String? photoUrl;

  const AvatarWidget({super.key, required this.name, this.size = 40, this.photoUrl});

  static String getInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(photoUrl!),
        backgroundColor: AppColors.avatarBg(name),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.avatarBg(name),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        getInitials(name),
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w500,
          color: AppColors.avatarText(name),
        ),
      ),
    );
  }
}
