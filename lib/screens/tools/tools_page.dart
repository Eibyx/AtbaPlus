import 'package:atba/screens/jobs_status_page.dart';
import 'package:atba/screens/tools/account_page.dart';
import 'package:atba/screens/tools/account_settings_page.dart';
import 'package:atba/screens/tools/cache_checker_page.dart';
import 'package:atba/screens/tools/changelog_page.dart';
import 'package:atba/screens/tools/hosters_page.dart';
import 'package:atba/screens/tools/notifications_page.dart';
import 'package:atba/screens/tools/rss_page.dart';
import 'package:atba/screens/tools/service_status_page.dart';
import 'package:atba/screens/tools/speedtest_page.dart';
import 'package:atba/screens/tools/tool_kit.dart';
import 'package:atba/screens/tools/usenet_provider_page.dart';
import 'package:atba/theme/app_theme.dart';
import 'package:atba/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:torbox_api/torbox_api.dart';

class _Tool {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  const _Tool(this.title, this.subtitle, this.icon, this.color, this.builder);
}

/// Hub that exposes every TorBox API capability not covered by the library.
class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  UserData? _user;

  static final List<(String, List<_Tool>)> _sections = [
    (
      'Account',
      [
        _Tool(
          'Account',
          'Plan, usage & billing',
          Icons.person_rounded,
          const Color(0xFF60A5FA),
          (_) => const AccountPage(),
        ),
        _Tool(
          'TorBox settings',
          'Seeding, notifications, links',
          Icons.tune_rounded,
          const Color(0xFFA78BFA),
          (_) => const AccountSettingsPage(),
        ),
        _Tool(
          'Notifications',
          'Your TorBox inbox',
          Icons.notifications_rounded,
          const Color(0xFFFBBF24),
          (_) => const NotificationsPage(),
        ),
      ],
    ),
    (
      'Automation',
      [
        _Tool(
          'RSS feeds',
          'Auto-add from feeds',
          Icons.rss_feed_rounded,
          const Color(0xFFFB923C),
          (_) => const RssFeedsPage(),
        ),
        _Tool(
          'Integration jobs',
          'Cloud uploads queue',
          Icons.cloud_sync_rounded,
          const Color(0xFF22D3EE),
          (_) => const JobsStatusPage(),
        ),
      ],
    ),
    (
      'Utilities',
      [
        _Tool(
          'Cache checker',
          'Instant availability & torrent info',
          Icons.bolt_rounded,
          const Color(0xFF34D399),
          (_) => const CacheCheckerPage(),
        ),
        _Tool(
          'Supported hosters',
          'Web download sources',
          Icons.public_rounded,
          const Color(0xFFF472B6),
          (_) => const HostersPage(),
        ),
        _Tool(
          'Usenet provider',
          'Your NNTP credentials',
          Icons.hub_rounded,
          const Color(0xFF818CF8),
          (_) => const UsenetProviderPage(),
        ),
        _Tool(
          'Speed test',
          'Test TorBox CDN speed',
          Icons.speed_rounded,
          const Color(0xFF4ADE80),
          (_) => const SpeedtestPage(),
        ),
      ],
    ),
    (
      'TorBox',
      [
        _Tool(
          'Service status',
          'Live network stats',
          Icons.monitor_heart_rounded,
          const Color(0xFFF87171),
          (_) => const ServiceStatusPage(),
        ),
        _Tool(
          'Changelog',
          "What's new on TorBox",
          Icons.new_releases_rounded,
          const Color(0xFF2DD4BF),
          (_) => const ChangelogPage(),
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final api = torboxApiOf(context);
    if (api == null) return;
    try {
      final r = await api.user.getUserData();
      if (mounted && r.success) setState(() => _user = r.data);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 900 ? 4 : (width > 600 ? 3 : 2);
    var index = 0;
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text('Tools'),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          SliverToBoxAdapter(
            child: EntranceAnimation(child: _AccountHeader(user: _user)),
          ),
          for (final (name, tools) in _sections) ...[
            SliverToBoxAdapter(child: SectionHeader(title: name)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.count(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  for (final tool in tools)
                    EntranceAnimation(
                      index: index++,
                      child: _ToolCard(tool: tool),
                    ),
                ],
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  final UserData? user;
  const _AccountHeader({required this.user});

  static const _plans = {0: 'Free', 1: 'Essential', 2: 'Pro', 3: 'Standard'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final plan = user == null
        ? '—'
        : (_plans[user!.plan] ?? 'Plan ${user!.plan}');
    final expires = user?.premiumExpiresAt;
    return SurfaceCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AccountPage()),
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.primary.withValues(alpha: 0.30),
          scheme.tertiary.withValues(alpha: 0.12),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            child: Text(
              (user?.email?.isNotEmpty ?? false)
                  ? user!.email![0].toUpperCase()
                  : '?',
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppMotion.medium,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, ?current],
              ),
              child: Column(
                key: ValueKey(user?.id),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.email ?? 'Loading account…',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      StatusPill(
                        label: plan,
                        color: scheme.primary,
                        icon: Icons.workspace_premium_rounded,
                      ),
                      if (expires != null)
                        StatusPill(
                          label:
                              'Renews ${formatDate(expires, withTime: false)}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final _Tool tool;
  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      margin: EdgeInsets.zero,
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: tool.builder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'tool-${tool.title}',
            child: IconBadge(icon: tool.icon, color: tool.color),
          ),
          const Spacer(),
          Text(
            tool.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tool.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
