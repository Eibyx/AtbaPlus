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
      'Cuenta',
      [
        _Tool(
          'Cuenta',
          'Plan, uso y facturación',
          Icons.person_rounded,
          const Color(0xFF60A5FA),
          (_) => const AccountPage(),
        ),
        _Tool(
          'Ajustes de TorBox',
          'Seeding, notificaciones, enlaces',
          Icons.tune_rounded,
          const Color(0xFFA78BFA),
          (_) => const AccountSettingsPage(),
        ),
        _Tool(
          'Notificaciones',
          'Tu bandeja de TorBox',
          Icons.notifications_rounded,
          const Color(0xFFFBBF24),
          (_) => const NotificationsPage(),
        ),
      ],
    ),
    (
      'Automatización',
      [
        _Tool(
          'Feeds RSS',
          'Añadir automáticamente desde feeds',
          Icons.rss_feed_rounded,
          const Color(0xFFFB923C),
          (_) => const RssFeedsPage(),
        ),
        _Tool(
          'Trabajos de integración',
          'Cola de subidas a la nube',
          Icons.cloud_sync_rounded,
          const Color(0xFF22D3EE),
          (_) => const JobsStatusPage(),
        ),
      ],
    ),
    (
      'Utilidades',
      [
        _Tool(
          'Comprobar caché',
          'Disponibilidad inmediata e info de torrents',
          Icons.bolt_rounded,
          const Color(0xFF34D399),
          (_) => const CacheCheckerPage(),
        ),
        _Tool(
          'Servidores compatibles',
          'Fuentes de descarga web',
          Icons.public_rounded,
          const Color(0xFFF472B6),
          (_) => const HostersPage(),
        ),
        _Tool(
          'Proveedor Usenet',
          'Tus credenciales NNTP',
          Icons.hub_rounded,
          const Color(0xFF818CF8),
          (_) => const UsenetProviderPage(),
        ),
        _Tool(
          'Test de velocidad',
          'Mide la velocidad del CDN de TorBox',
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
          'Estado del servicio',
          'Estadísticas en vivo',
          Icons.monitor_heart_rounded,
          const Color(0xFFF87171),
          (_) => const ServiceStatusPage(),
        ),
        _Tool(
          'Novedades',
          "Lo nuevo en TorBox",
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
    final columns = width > 900 ? 3 : (width > 600 ? 2 : 1);
    var index = 0;
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.medium(
            title: const Text('Herramientas'),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          SliverToBoxAdapter(
            child: EntranceAnimation(child: _AccountHeader(user: _user)),
          ),
          for (final (name, tools) in _sections) ...[
            SliverToBoxAdapter(child: SectionHeader(title: name)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 64,
                ),
                delegate: SliverChildListDelegate([
                  for (final tool in tools)
                    EntranceAnimation(
                      index: index++,
                      child: _ToolCard(tool: tool),
                    ),
                ]),
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

  static const _plans = {0: 'Gratis', 1: 'Essential', 2: 'Pro', 3: 'Standard'};

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
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
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
                    user?.email ?? 'Cargando cuenta…',
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
                              'Renueva el ${formatDate(expires, withTime: false)}',
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: tool.builder)),
      child: Row(
        children: [
          IconBadge(icon: tool.icon, color: tool.color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  tool.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
