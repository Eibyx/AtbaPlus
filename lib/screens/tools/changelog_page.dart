import 'package:atba/screens/tools/tool_kit.dart';
import 'package:atba/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:torbox_api/torbox_api.dart';
import 'package:url_launcher/url_launcher.dart';

class ChangelogPage extends StatelessWidget {
  const ChangelogPage({super.key});

  /// Very small markdown cleanup so the text reads well without a renderer.
  static String _plain(String md) => md
      .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
      .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
      .replaceAllMapped(RegExp(r'\[(.*?)\]\((.*?)\)'), (m) => m[1]!)
      .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '•  ')
      .trim();

  @override
  Widget build(BuildContext context) {
    return ApiLoader<List<ChangelogEntry>>(
      title: 'Novedades',
      load: (api) => api.general.getChangelogsJson(),
      isEmpty: (d) => d.isEmpty,
      builder: (context, entries, reload) => [
        SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final e = entries[i];
            return EntranceAnimation(
              index: i,
              child: _ChangelogCard(
                entry: e,
                text: _plain(e.markdown),
                initiallyOpen: i == 0,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ChangelogCard extends StatefulWidget {
  final ChangelogEntry entry;
  final String text;
  final bool initiallyOpen;

  const _ChangelogCard({
    required this.entry,
    required this.text,
    required this.initiallyOpen,
  });

  @override
  State<_ChangelogCard> createState() => _ChangelogCardState();
}

class _ChangelogCardState extends State<_ChangelogCard> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      onTap: () => setState(() => _open = !_open),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.name,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatDate(widget.entry.createdAt, withTime: false),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.expand_more_rounded),
                ),
              ],
            ),
            if (_open) ...[
              const SizedBox(height: 12),
              SelectableText(widget.text, style: theme.textTheme.bodyMedium),
              if (widget.entry.link.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(widget.entry.link),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Abrir'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
