import 'package:atba/screens/tools/tool_kit.dart';
import 'package:atba/l10n.dart';
import 'package:atba/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:torbox_api/torbox_api.dart';

class RssFeedsPage extends StatefulWidget {
  const RssFeedsPage({super.key});

  @override
  State<RssFeedsPage> createState() => _RssFeedsPageState();
}

class _RssFeedsPageState extends State<RssFeedsPage> {
  final _loaderKey = GlobalKey<ApiLoaderState<List<RssFeedData>>>();

  void _reload() => _loaderKey.currentState?.reload();

  @override
  Widget build(BuildContext context) {
    return ApiLoader<List<RssFeedData>>(
      key: _loaderKey,
      title: 'Feeds RSS',
      load: (api) => api.rssFeeds.getRssFeeds(),
      isEmpty: (d) => d.isEmpty,
      emptyState: EmptyState(
        icon: Icons.rss_feed_rounded,
        title: 'Aún no hay feeds RSS',
        message: 'TorBox puede vigilar feeds RSS y añadir automáticamente los torrents, NZB o enlaces que coincidan.',
        action: FilledButton.icon(
          onPressed: () => _editFeed(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Añadir feed'),
        ),
      ),
      fab: (context, reload) => FloatingActionButton.extended(
        onPressed: () => _editFeed(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Añadir feed'),
      ),
      builder: (context, feeds, reload) => [
        SliverList.builder(
          itemCount: feeds.length,
          itemBuilder: (context, i) => EntranceAnimation(
            index: i,
            child: _FeedCard(
              feed: feeds[i],
              onChanged: _reload,
              onEdit: () => _editFeed(context, feeds[i]),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editFeed(BuildContext context, [RssFeedData? feed]) async {
    final saved = await showToolSheet<bool>(
      context,
      title: feed == null ? 'Añadir feed RSS' : 'Editar feed',
      builder: (_) => _FeedForm(feed: feed),
    );
    if (saved == true) _reload();
  }
}

class _FeedCard extends StatelessWidget {
  final RssFeedData feed;
  final VoidCallback onChanged;
  final VoidCallback onEdit;

  const _FeedCard({
    required this.feed,
    required this.onChanged,
    required this.onEdit,
  });

  bool get _paused =>
      (feed.status ?? feed.state ?? '').toLowerCase().contains('pause');

  Future<void> _control(BuildContext context, String op, String msg) async {
    final r = await runApiAction(
      context,
      (api) => api.rssFeeds.controlRssFeed(operation: op, rssFeedId: feed.id),
      successMessage: msg,
    );
    if (r != null) onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _paused
        ? theme.colorScheme.onSurfaceVariant
        : const Color(0xFFFB923C);
    return SurfaceCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RssFeedItemsPage(feed: feed)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: Icons.rss_feed_rounded, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(feed.name, style: theme.textTheme.titleSmall),
                    Text(
                      feed.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (v) async {
                  switch (v) {
                    case 'edit':
                      onEdit();
                    case 'update':
                      await _control(context, 'update', 'Comprobación en cola');
                    case 'pause':
                      await _control(context, 'pause', 'Feed pausado');
                    case 'resume':
                      await _control(context, 'resume', 'Feed reanudado');
                    case 'delete':
                      final ok = await confirmAction(
                        context,
                        title: '¿Borrar "${feed.name}"?',
                        message: 'Este feed dejará de comprobarse.',
                        confirmLabel: 'Borrar',
                      );
                      if (ok && context.mounted) {
                        await _control(context, 'delete', 'Feed borrado');
                      }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  const PopupMenuItem(
                    value: 'update',
                    child: Text('Comprobar ahora'),
                  ),
                  if (_paused)
                    const PopupMenuItem(
                      value: 'resume',
                      child: Text('Reanudar'),
                    )
                  else
                    const PopupMenuItem(value: 'pause', child: Text('Pausar')),
                  const PopupMenuItem(value: 'delete', child: Text('Borrar')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusPill(
                label: tr(feed.status ?? feed.state ?? 'unknown'),
                color: _paused ? null : const Color(0xFF34D399),
              ),
              if (feed.type != null) StatusPill(label: feed.type!),
              if (feed.scanInterval != null)
                StatusPill(
                  label: 'cada ${feed.scanInterval} min',
                  icon: Icons.schedule_rounded,
                ),
              StatusPill(
                label: 'revisado ${timeAgo(feed.lastChecked)}',
                icon: Icons.history_rounded,
              ),
            ],
          ),
          if ((feed.statusMessage ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(feed.statusMessage!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _FeedForm extends StatefulWidget {
  final RssFeedData? feed;
  const _FeedForm({this.feed});

  @override
  State<_FeedForm> createState() => _FeedFormState();
}

class _FeedFormState extends State<_FeedForm> {
  late final _name = TextEditingController(text: widget.feed?.name);
  late final _url = TextEditingController(text: widget.feed?.url);
  late final _doRegex = TextEditingController(text: widget.feed?.doRegex);
  late final _dontRegex = TextEditingController(text: widget.feed?.dontRegex);
  late final _interval = TextEditingController(
    text: '${widget.feed?.scanInterval ?? 60}',
  );
  late final _olderThan = TextEditingController(
    text: '${widget.feed?.dontOlderThan ?? 0}',
  );
  late String _type = widget.feed?.type ?? 'torrent';
  late int _seeding = widget.feed?.torrentSeeding ?? 1;
  bool _passCheck = false;
  bool _saving = false;

  Future<void> _save() async {
    if (_name.text.trim().isEmpty ||
        (widget.feed == null && _url.text.trim().isEmpty)) {
      showToast(
        context,
        'Nombre y URL son obligatorios',
        type: ToastType.error,
      );
      return;
    }
    setState(() => _saving = true);
    String? orNull(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final interval = int.tryParse(_interval.text);
    final olderThan = int.tryParse(_olderThan.text);
    final r = await runApiAction(
      context,
      (api) => widget.feed == null
          ? api.rssFeeds.addRssFeed(
              url: _url.text.trim(),
              name: _name.text.trim(),
              doRegex: orNull(_doRegex),
              dontRegex: orNull(_dontRegex),
              scanInterval: interval,
              dontOlderThan: olderThan,
              rssType: _type,
              torrentSeeding: _seeding,
              passCheck: _passCheck,
            )
          : api.rssFeeds.modifyRssFeed(
              rssFeedId: widget.feed!.id,
              name: _name.text.trim(),
              doRegex: orNull(_doRegex),
              dontRegex: orNull(_dontRegex),
              scanInterval: interval,
              dontOlderThan: olderThan,
              rssType: _type,
              torrentSeeding: _seeding,
              passCheck: _passCheck,
            ),
      successMessage: widget.feed == null ? 'Feed añadido' : 'Feed actualizado',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (r != null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: kSheetFieldGap,
          child: TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
        ),
        if (widget.feed == null)
          Padding(
            padding: kSheetFieldGap,
            child: TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'URL del feed'),
            ),
          ),
        Padding(
          padding: kSheetFieldGap,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'torrent', label: Text('Torrent')),
              ButtonSegment(value: 'usenet', label: Text('Usenet')),
              ButtonSegment(value: 'webdl', label: Text('Web')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
        ),
        Padding(
          padding: kSheetFieldGap,
          child: TextField(
            controller: _doRegex,
            decoration: const InputDecoration(
              labelText: 'Regex para incluir',
              hintText: 'p. ej. 1080p.*WEB',
            ),
          ),
        ),
        Padding(
          padding: kSheetFieldGap,
          child: TextField(
            controller: _dontRegex,
            decoration: const InputDecoration(
              labelText: 'Regex para excluir',
              hintText: 'p. ej. CAM|TS',
            ),
          ),
        ),
        Padding(
          padding: kSheetFieldGap,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _interval,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Revisar cada (min)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _olderThan,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ignorar más antiguos que (días)',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_type == 'torrent')
          Padding(
            padding: kSheetFieldGap,
            child: DropdownButtonFormField<int>(
              initialValue: _seeding,
              decoration: const InputDecoration(labelText: 'Seeding'),
              items: const [
                DropdownMenuItem(
                  value: 1,
                  child: Text('Automático (según la cuenta)'),
                ),
                DropdownMenuItem(value: 2, child: Text('Seed siempre')),
                DropdownMenuItem(value: 3, child: Text("Sin seed")),
              ],
              onChanged: (v) => setState(() => _seeding = v ?? 1),
            ),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Saltar primera revisión'),
          subtitle: const Text("No añadir lo que ya está en el feed"),
          value: _passCheck,
          onChanged: (v) => setState(() => _passCheck = v),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _saving
                ? const SizedBox(
                    key: ValueKey('p'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(
                    widget.feed == null ? 'Añadir feed' : 'Guardar cambios',
                    key: const ValueKey('t'),
                  ),
          ),
        ),
      ],
    );
  }
}

class RssFeedItemsPage extends StatelessWidget {
  final RssFeedData feed;
  const RssFeedItemsPage({super.key, required this.feed});

  @override
  Widget build(BuildContext context) {
    return ApiLoader<List<RssFeedItemData>>(
      title: feed.name,
      load: (api) => api.rssFeeds.getRssFeedItems(rssFeedId: feed.id),
      isEmpty: (d) => d.isEmpty,
      emptyState: const EmptyState(
        icon: Icons.inbox_rounded,
        title: 'Aún no hay elementos',
        message: 'Aquí aparecerá lo que coincida con este feed.',
      ),
      builder: (context, items, reload) => [
        SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final it = items[i];
            final color = it.downloaded
                ? const Color(0xFF34D399)
                : it.ignored
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : const Color(0xFFFBBF24);
            return EntranceAnimation(
              index: i,
              child: SurfaceCard(
                onTap: () =>
                    copyToClipboard(context, it.link, label: 'Enlace copiado'),
                child: Row(
                  children: [
                    IconBadge(
                      icon: it.downloaded
                          ? Icons.check_rounded
                          : it.ignored
                          ? Icons.block_rounded
                          : Icons.schedule_rounded,
                      color: color,
                      size: 36,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${it.status} · ${timeAgo(it.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
