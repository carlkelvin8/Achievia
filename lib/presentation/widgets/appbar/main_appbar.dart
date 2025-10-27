import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/presentation/widgets/headers/app_header.dart';
import 'package:achievia/presentation/widgets/tabs/profile/tab_bar_profile.dart';
import 'package:flutter/material.dart';

class MainAppbar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onSettingsTap;
  final VoidCallback onNotificationTap;
  final int notificationCount;
  final String username;
  final String profileImageUrl;
  const MainAppbar({super.key, required this.onSettingsTap, required this.onNotificationTap, required this.notificationCount, required this.username, required this.profileImageUrl});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 20,
            backgroundColor: headerColor2,
            backgroundImage: profileImageUrl.isNotEmpty
                ? NetworkImage(profileImageUrl)
                : null,
            child: profileImageUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          // Username
          Expanded(
            child: Text(
              username,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: headerColor,
              ),
            ),
          ),
          // Notification Icon
          Stack(
            children: [
              IconButton(
                onPressed: onNotificationTap,
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: headerColor2,
                  size: 24,
                ),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Settings Icon
          IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(
              Icons.settings_outlined,
              color: headerColor2,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}