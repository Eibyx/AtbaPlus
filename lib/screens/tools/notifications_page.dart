import 'package:atba/screens/tools/tool_kit.dart';
import 'package:atba/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:torbox_api/torbox_api.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _loaderKey = GlobalKey<ApiLoaderState<List<NotificationData>>>();
  final Set<int> _dismissed = {};

  @override
  Widget build(BuildContext context) {
    return ApiLoader<List<NotificationData>>(
      key: _loaderKey,
      title: 'Notifications',
      load: (api) => api.notifications.getNotificationFeed(),
      isEmpty: (d) => d.where((n) => !_dismissed.contains(n.id)).isEmpty,
      emptyState: EmptyState(
        icon: Icons.notifications_off_rounded,
        title: "You're all caught up",
        message: 'New TorBox notifications will show up here.',
        action: OutlinedButton.icon(
          onPressed: _sendTest,
          icon: const Icon(Icons.send_rounded),
          label: const Text('Send a test notification'),
        ),
      ),
      actions: (context, reload) => [
        IconButton(
          tooltip: 'Send test notification',
          icon: const Icon(Icons.send_rounded),
          onPressed: _sendTest,
        ),
        IconButton(
          tooltip: 'Clear all',
          icon: const Icon(Icons.clear_all_rounded),
          onPressed: () async {
            final ok = await confirmAction(
              context,
              title: 'Clear all notifications?',
              message: 'This removes every notification from your account.',
              confirmLabel: 'Clear all',
            );
            if (!ok || !context.mounted) return;
            final r = await runApiAction(
              context,
              (api) => api.notifications.clearAllNotifications(),
              successMessage: 'Notifications cleared',
            );
            if (r != null) reload();
          },
        ),
      ],
      builder: (context, items, reload) {
        final visible = items.where((n) => !_dismissed.contains(n.id)).toList();
        return [
          SliverList.builder(
            itemCount: visible.length,
            itemBuilder: (context, i) {
              final n = visible[i];
              return EntranceAnimation(
                index: i,
                child: Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      Icons.delete_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onDismissed: (_) async {
                    setState(() => _dismissed.add(n.id));
                    final r = await runApiAction(
                      context,
                      (api) => api.notifications.clearNotification(n.id),
                      successMessage: 'Notification removed',
                    );
                    if (r == null && mounted) {
                      setState(() => _dismissed.remove(n.id));
                    }
                  },
                  child: SurfaceCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconBadge(
                          icon: Icons.notifications_rounded,
                          color: const Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                  ),
                                  Text(
                                    timeAgo(n.createdAt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                n.message,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ];
      },
    );
  }

  Future<void> _sendTest() async {
    final r = await runApiAction(
      context,
      (api) => api.notifications.sendTestNotification(),
      successMessage: 'Test notification sent',
    );
    if (r != null) {
      await Future.delayed(const Duration(milliseconds: 800));
      _loaderKey.currentState?.reload();
    }
  }
}
