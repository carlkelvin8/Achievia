import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/presentation/provider/notifications/notifications_provider.dart';
import 'package:achievia/presentation/widgets/notifications/notification_card.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:achievia/presentation/widgets/badges/notification_badge.dart';
import 'package:achievia/presentation/widgets/placeholder_gestures/empty_state_widget.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Notifications',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: NotificationBadge(
              count: unreadCount,
              child: IconButton(
                icon: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF90CAF9),
                    size: 24,
                  ),
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: () {
                  // Refresh notifications
                  ref.invalidate(notificationsProvider);
                },
              ),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => EmptyStateWidget(
          icon: Icons.cloud_off,
          title: 'Unable to load notifications',
          subtitle: 'Check your connection and try again',
          action: FilledButton.icon(
            onPressed: () => ref.invalidate(notificationsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
        data: (notifications) => notifications.isEmpty
            ? const EmptyStateWidget(
                icon: Icons.notifications_none,
                title: 'No notifications yet',
                subtitle: 'We\'ll notify you when something important happens',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NotificationCard(
                      notification: notification,
                      onTap: () => ref
                          .read(notificationsProvider.notifier)
                          .markAsRead(notification.id),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
