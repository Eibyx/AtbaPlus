import 'dart:io';

import 'package:atba/screens/tools/tool_kit.dart';
import 'package:atba/theme/app_theme.dart';
import 'package:atba/utils.dart';
import 'package:atba/widgets/motion.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:torbox_api/torbox_api.dart';

/// Loads a single API value inside a card and animates it in.
class AsyncSection<T> extends StatefulWidget {
  final Future<TorBoxResponse<T>> Function(TorboxApi api) load;
  final Widget Function(BuildContext context, T data) builder;
  final double placeholderHeight;

  const AsyncSection({
    super.key,
    required this.load,
    required this.builder,
    this.placeholderHeight = 120,
  });

  @override
  State<AsyncSection<T>> createState() => _AsyncSectionState<T>();
}

class _AsyncSectionState<T> extends State<AsyncSection<T>> {
  late Future<TorBoxResponse<T>>? _future;

  @override
  void initState() {
    super.initState();
    final api = torboxApiOf(context);
    _future = api == null ? null : widget.load(api);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<TorBoxResponse<T>>(
      future: _future,
      builder: (context, snap) {
        Widget child;
        if (snap.connectionState != ConnectionState.done) {
          child = Container(
            key: const ValueKey('loading'),
            height: widget.placeholderHeight,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          );
        } else if (snap.hasError ||
            snap.data == null ||
            !snap.data!.success ||
            snap.data!.data == null) {
          final msg = snap.hasError
              ? describeError(snap.error!)
              : (snap.data?.detail ?? 'No disponible');
          child = SurfaceCard(
            key: const ValueKey('error'),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(msg)),
              ],
            ),
          );
        } else {
          child = KeyedSubtree(
            key: const ValueKey('data'),
            child: widget.builder(context, snap.data!.data as T),
          );
        }
        return AnimatedSwitcher(
          duration: AppMotion.medium,
          switchInCurve: AppMotion.emphasized,
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: SizeTransition(sizeFactor: a, child: c),
          ),
          child: child,
        );
      },
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  static const _plans = {0: 'Gratis', 1: 'Essential', 2: 'Pro', 3: 'Standard'};

  @override
  Widget build(BuildContext context) {
    return ApiLoader<UserData>(
      title: 'Cuenta',
      load: (api) => api.user.getUserData(),
      builder: (context, user, reload) {
        final scheme = Theme.of(context).colorScheme;
        return [
          SliverToBoxAdapter(
            child: EntranceAnimation(
              child: SurfaceCard(
                child: Column(
                  children: [
                    InfoRow(
                      label: 'Email',
                      value: user.email ?? '—',
                      copyable: true,
                    ),
                    InfoRow(
                      label: 'Plan',
                      value: _plans[user.plan] ?? 'Plan ${user.plan}',
                    ),
                    InfoRow(
                      label: 'Suscrito',
                      value: (user.isSubscribed ?? false) ? 'Sí' : 'No',
                    ),
                    InfoRow(
                      label: 'Premium hasta',
                      value: formatDate(user.premiumExpiresAt),
                    ),
                    if (user.cooldownUntil != null)
                      InfoRow(
                        label: 'En espera hasta',
                        value: formatDate(user.cooldownUntil),
                      ),
                    InfoRow(
                      label: 'Miembro desde',
                      value: formatDate(user.createdAt, withTime: false),
                    ),
                    InfoRow(
                      label: 'Slots extra',
                      value: '${user.additionalConcurrentSlots ?? 0}',
                    ),
                    InfoRow(
                      label: 'ID de usuario',
                      value: '${user.id}',
                      copyable: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SectionHeader(title: 'Uso total')),
          StatGrid(
            tiles: [
              StatTile(
                index: 1,
                label: 'Descargado',
                value: getReadableSize(user.totalBytesDownloaded ?? 0),
                icon: Icons.south_rounded,
                color: const Color(0xFF60A5FA),
              ),
              StatTile(
                index: 2,
                label: 'Subido',
                value: getReadableSize(user.totalBytesUploaded ?? 0),
                icon: Icons.north_rounded,
                color: const Color(0xFF34D399),
              ),
              StatTile(
                index: 3,
                label: 'Torrents',
                value: '${user.torrentsDownloaded ?? 0}',
                icon: Icons.hub_rounded,
                color: const Color(0xFFFBBF24),
              ),
              StatTile(
                index: 4,
                label: 'Web / Usenet',
                value:
                    '${user.webDownloadsDownloaded ?? 0} / ${user.usenetDownloadsDownloaded ?? 0}',
                icon: Icons.public_rounded,
                color: const Color(0xFFF472B6),
              ),
            ],
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(title: 'Consumo (últimos 30 días)'),
          ),
          SliverToBoxAdapter(
            child: AsyncSection<UserStatsData>(
              placeholderHeight: 180,
              load: (api) => api.user.getStats(
                general: true,
                bandwidth: true,
                bandwidthGrouping: 'day',
              ),
              builder: (context, stats) => _BandwidthChart(
                points: stats.bandwidth ?? const [],
                ratio: stats.general?.ratio,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SectionHeader(title: 'Referidos')),
          SliverToBoxAdapter(
            child: AsyncSection<ReferralData>(
              load: (api) => api.user.getReferralData(),
              builder: (context, r) => SurfaceCard(
                child: Column(
                  children: [
                    InfoRow(
                      label: 'Tu código',
                      value: r.referralCode,
                      copyable: true,
                    ),
                    InfoRow(
                      label: 'Cuentas referidas',
                      value: '${r.referredAccounts}',
                    ),
                    InfoRow(
                      label: 'Compras referidas',
                      value: '${r.purchasesReferred}',
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _addReferral(context),
                        icon: const Icon(Icons.card_giftcard_rounded),
                        label: const Text('Usar un código de referido'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(title: 'Suscripciones'),
          ),
          SliverToBoxAdapter(
            child: AsyncSection<List<UserSubscription>>(
              load: (api) => api.user.getSubscriptions(),
              builder: (context, subs) => subs.isEmpty
                  ? const SurfaceCard(child: Text('Sin suscripciones'))
                  : Column(
                      children: [
                        for (final s in subs)
                          SurfaceCard(
                            child: Row(
                              children: [
                                IconBadge(
                                  icon: Icons.workspace_premium_rounded,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.planName ?? s.planCode ?? 'Plan',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                      Text(
                                        '${s.gateway ?? ''} · ${formatDate(s.createdAt, withTime: false)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                StatusPill(
                                  label: s.status ?? '—',
                                  color: s.status == 'active'
                                      ? const Color(0xFF34D399)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SectionHeader(title: 'Transacciones'),
          ),
          SliverToBoxAdapter(
            child: AsyncSection<List<UserTransaction>>(
              load: (api) => api.user.getTransactions(),
              builder: (context, txs) => txs.isEmpty
                  ? const SurfaceCard(child: Text('Sin transacciones'))
                  : Column(
                      children: [
                        for (final (i, t) in txs.indexed)
                          EntranceAnimation(
                            index: i,
                            child: SurfaceCard(
                              onTap: kIsWeb
                                  ? null
                                  : () => _downloadReceipt(context, t),
                              child: Row(
                                children: [
                                  IconBadge(
                                    icon: Icons.receipt_long_rounded,
                                    color: scheme.tertiary,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.type,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        Text(
                                          formatDate(t.at),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${t.amount}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  if (!kIsWeb) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.picture_as_pdf_rounded,
                                      size: 18,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          const SliverToBoxAdapter(child: SectionHeader(title: 'Seguridad')),
          SliverToBoxAdapter(
            child: SurfaceCard(
              onTap: () => runApiAction(
                context,
                (api) => api.user.getConfirmation(),
                successMessage: 'Código enviado a tu correo',
              ),
              child: const Row(
                children: [
                  Icon(Icons.mark_email_read_rounded),
                  SizedBox(width: 14),
                  Expanded(child: Text('Enviarme un código de confirmación')),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }

  Future<void> _addReferral(BuildContext context) async {
    final controller = TextEditingController();
    await showToolSheet<void>(
      context,
      title: 'Usar un código de referido',
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Código de referido'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              final ok = await runApiAction(
                context,
                (api) => api.user.addReferral(code),
                successMessage: 'Código de referido aplicado',
              );
              if (ok != null && sheetContext.mounted) {
                Navigator.pop(sheetContext);
              }
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadReceipt(BuildContext context, UserTransaction t) async {
    final api = torboxApiOf(context);
    if (api == null) return;
    showToast(context, 'Descargando recibo…');
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = await api.user.downloadTransactionPdf(
        transactionId: t.transactionId,
        savePath:
            '${dir.path}${Platform.pathSeparator}torbox-${t.transactionId}.pdf',
      );
      if (context.mounted) {
        showToast(context, 'Recibo guardado', type: ToastType.success);
      }
      await OpenFile.open(path);
    } catch (e) {
      if (context.mounted) {
        showToast(context, describeError(e), type: ToastType.error);
      }
    }
  }
}

/// Simple animated bar chart of daily bandwidth.
class _BandwidthChart extends StatelessWidget {
  final List<UserBandwidthPoint> points;
  final double? ratio;

  const _BandwidthChart({required this.points, this.ratio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final data = points.length > 30
        ? points.sublist(points.length - 30)
        : points;
    final maxV = data.fold<int>(
      1,
      (m, p) => p.bytesDownloaded > m ? p.bytesDownloaded : m,
    );
    final total = data.fold<int>(0, (s, p) => s + p.bytesDownloaded);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                getReadableSize(total),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (ratio != null)
                StatusPill(
                  label: 'Ratio ${ratio!.toStringAsFixed(2)}',
                  color: scheme.primary,
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: data.isEmpty
                ? const Center(child: Text('Aún no hay datos'))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final (i, p) in data.indexed)
                        Expanded(
                          child: Tooltip(
                            message:
                                '${p.date}\n${getReadableSize(p.bytesDownloaded)}',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: 0,
                                  end: p.bytesDownloaded / maxV,
                                ),
                                duration: Duration(milliseconds: 500 + i * 15),
                                curve: AppMotion.emphasized,
                                builder: (context, v, _) => Container(
                                  height: 4 + 106 * v,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        scheme.primary.withValues(alpha: 0.45),
                                        scheme.primary,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
