import 'package:atba/screens/tools/tool_kit.dart';
import 'package:atba/utils.dart';
import 'package:atba/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:torbox_api/torbox_api.dart';

class HostersPage extends StatefulWidget {
  const HostersPage({super.key});

  @override
  State<HostersPage> createState() => _HostersPageState();
}

class _HostersPageState extends State<HostersPage> {
  String _query = '';
  bool _onlineOnly = false;

  @override
  Widget build(BuildContext context) {
    return ApiLoader<List<HosterData>>(
      title: 'Supported hosters',
      load: (api) => api.webDownloads.getHosters(),
      isEmpty: (d) => d.isEmpty,
      builder: (context, hosters, reload) {
        final q = _query.toLowerCase();
        final list =
            hosters
                .where((h) => !_onlineOnly || h.status)
                .where(
                  (h) =>
                      q.isEmpty ||
                      h.name.toLowerCase().contains(q) ||
                      h.domains.any((d) => d.toLowerCase().contains(q)),
                )
                .toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
        final online = hosters.where((h) => h.status).length;
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search hosters or domains',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '$online of ${hosters.length} online',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  FilterChip(
                    label: const Text('Online only'),
                    selected: _onlineOnly,
                    showCheckmark: false,
                    onSelected: (v) => setState(() => _onlineOnly = v),
                  ),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: list.length,
            itemBuilder: (context, i) => EntranceAnimation(
              key: ValueKey(list[i].id),
              index: i,
              child: _HosterCard(hoster: list[i]),
            ),
          ),
        ];
      },
    );
  }
}

class _HosterCard extends StatefulWidget {
  final HosterData hoster;
  const _HosterCard({required this.hoster});

  @override
  State<_HosterCard> createState() => _HosterCardState();
}

class _HosterCardState extends State<_HosterCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.hoster;
    final theme = Theme.of(context);
    final statusColor = h.status
        ? const Color(0xFF34D399)
        : const Color(0xFFF87171);
    return SurfaceCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    h.icon,
                    width: 36,
                    height: 36,
                    errorBuilder: (_, _, _) => IconBadge(
                      icon: Icons.public_rounded,
                      color: theme.colorScheme.primary,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h.name, style: theme.textTheme.titleSmall),
                      Text(
                        h.domains.take(3).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  label: h.status ? 'Online' : 'Offline',
                  color: statusColor,
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.expand_more_rounded),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              InfoRow(label: 'Type', value: h.type),
              if (h.dailyLinkLimit > 0)
                InfoRow(
                  label: 'Daily links',
                  value: '${h.dailyLinkUsed} / ${h.dailyLinkLimit}',
                ),
              if (h.dailyBandwidthLimit > 0)
                InfoRow(
                  label: 'Daily bandwidth',
                  value:
                      '${getReadableSize(h.dailyBandwidthUsed)} / ${getReadableSize(h.dailyBandwidthLimit)}',
                ),
              if (h.perLinkSizeLimit > 0)
                InfoRow(
                  label: 'Max file size',
                  value: getReadableSize(h.perLinkSizeLimit),
                ),
              if (h.nsfw) const InfoRow(label: 'NSFW', value: 'Yes'),
              if ((h.note ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(h.note!, style: theme.textTheme.bodySmall),
                ),
              if (h.domains.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    h.domains.join(', '),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
