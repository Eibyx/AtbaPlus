import 'dart:convert';

import 'package:atba/screens/tools/tool_kit.dart';
import 'package:atba/theme/app_theme.dart';
import 'package:atba/utils.dart';
import 'package:atba/widgets/motion.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:torbox_api/torbox_api.dart';

enum _Kind { torrent, usenet, web }

class _Entry {
  final String input;
  final String hash;
  CachedAvailabilityData? cached;

  _Entry(this.input, this.hash);
}

/// Checks TorBox's instant (cached) availability for magnets, hashes, NZB
/// hashes or web links, and can look up torrent metadata.
class CacheCheckerPage extends StatefulWidget {
  const CacheCheckerPage({super.key});

  @override
  State<CacheCheckerPage> createState() => _CacheCheckerPageState();
}

class _CacheCheckerPageState extends State<CacheCheckerPage> {
  final _input = TextEditingController();
  _Kind _kind = _Kind.torrent;
  bool _loading = false;
  List<_Entry>? _results;

  static final _btih = RegExp(r'urn:btih:([a-zA-Z0-9]+)', caseSensitive: false);
  static final _hex = RegExp(r'^[a-fA-F0-9]{32,40}$');

  String? _hashFor(String line) {
    switch (_kind) {
      case _Kind.torrent:
        final m = _btih.firstMatch(line);
        if (m != null) return m.group(1)!.toLowerCase();
        return _hex.hasMatch(line) ? line.toLowerCase() : null;
      case _Kind.usenet:
        return _hex.hasMatch(line)
            ? line.toLowerCase()
            : md5.convert(utf8.encode(line)).toString();
      case _Kind.web:
        if (_hex.hasMatch(line)) return line.toLowerCase();
        return md5.convert(utf8.encode(line)).toString();
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null) return;
    final current = _input.text.trim();
    _input.text = current.isEmpty
        ? data!.text!.trim()
        : '$current\n${data!.text!.trim()}';
    final t = _input.text.toLowerCase();
    if (t.contains('magnet:')) {
      setState(() => _kind = _Kind.torrent);
    } else if (t.startsWith('http')) {
      setState(() => _kind = _Kind.web);
    }
  }

  Future<void> _check() async {
    FocusScope.of(context).unfocus();
    final api = torboxApiOf(context);
    if (api == null) {
      showToast(context, 'Primero añade tu clave API', type: ToastType.error);
      return;
    }
    final entries = <_Entry>[];
    for (final raw in const LineSplitter().convert(_input.text)) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final hash = _hashFor(line);
      if (hash != null) entries.add(_Entry(line, hash));
    }
    if (entries.isEmpty) {
      showToast(
        context,
        'No hay nada válido que comprobar',
        type: ToastType.error,
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final hashes = entries.map((e) => e.hash).toSet().toList();
      final r = switch (_kind) {
        _Kind.torrent => await api.torrents.checkCachedAvailability(
          hashes: hashes,
          format: 'object',
          listFiles: true,
        ),
        _Kind.usenet => await api.usenet.checkCachedAvailability(
          hashes: hashes,
          format: 'object',
        ),
        _Kind.web => await api.webDownloads.checkCachedAvailability(
          hashes: hashes,
          format: 'object',
        ),
      };
      final map = r.data ?? const {};
      for (final e in entries) {
        e.cached = map[e.hash];
      }
      if (!mounted) return;
      setState(() => _results = entries);
      final hits = entries.where((e) => e.cached != null).length;
      showToast(
        context,
        '$hits de ${entries.length} en caché',
        type: hits > 0 ? ToastType.success : ToastType.info,
      );
    } catch (e) {
      if (mounted) showToast(context, describeError(e), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add(_Entry e) async {
    await runApiAction(
      context,
      (api) => switch (_kind) {
        _Kind.torrent => api.torrents.createTorrent(
          magnet: e.input.startsWith('magnet:')
              ? e.input
              : 'magnet:?xt=urn:btih:${e.hash}',
        ),
        _Kind.web => api.webDownloads.createWebDownload(link: e.input),
        _Kind.usenet => api.usenet.createUsenetDownload(link: e.input),
      },
      successMessage: 'Añadido a tu biblioteca',
    );
  }

  Future<void> _info(_Entry e) async {
    final api = torboxApiOf(context);
    if (api == null) return;
    showToolSheet<void>(
      context,
      title: 'Info del torrent',
      builder: (context) => FutureBuilder<TorBoxResponse<TorrentInfoData>>(
        future: api.torrents.getTorrentInfo(hash: e.hash, timeout: 10),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final info = snap.data?.data;
          if (snap.hasError || info == null) {
            return Text(
              snap.hasError
                  ? describeError(snap.error!)
                  : (snap.data?.detail ?? 'Sin información'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoRow(label: 'Nombre', value: info.name ?? '—'),
              InfoRow(label: 'Hash', value: info.hash, copyable: true),
              InfoRow(label: 'Tamaño', value: getReadableSize(info.size ?? 0)),
              InfoRow(label: 'Seeds', value: '${info.seeds ?? '—'}'),
              InfoRow(label: 'Peers', value: '${info.peers ?? '—'}'),
              InfoRow(
                label: 'Trackers',
                value: '${info.trackers?.length ?? 0}',
              ),
              if ((info.files ?? []).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Archivos', style: Theme.of(context).textTheme.titleSmall),
                for (final f in info.files!.take(100))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            f.name,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          getReadableSize(f.size),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolScaffold(
      title: 'Comprobar caché',
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<_Kind>(
                  segments: const [
                    ButtonSegment(
                      value: _Kind.torrent,
                      label: Text('Torrent'),
                      icon: Icon(Icons.hub_rounded),
                    ),
                    ButtonSegment(
                      value: _Kind.usenet,
                      label: Text('Usenet'),
                      icon: Icon(Icons.dns_rounded),
                    ),
                    ButtonSegment(
                      value: _Kind.web,
                      label: Text('Web'),
                      icon: Icon(Icons.public_rounded),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (s) => setState(() {
                    _kind = s.first;
                    _results = null;
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _input,
                  minLines: 4,
                  maxLines: 8,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  decoration: InputDecoration(
                    labelText: switch (_kind) {
                      _Kind.torrent => 'Magnets o hashes',
                      _Kind.usenet => 'Enlaces NZB o hashes',
                      _Kind.web => 'Enlaces web',
                    },
                    hintText: 'Uno por línea',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _paste,
                        icon: const Icon(Icons.content_paste_rounded),
                        label: const Text('Pegar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _check,
                        icon: AnimatedSwitcher(
                          duration: AppMotion.fast,
                          child: _loading
                              ? const SizedBox(
                                  key: ValueKey('l'),
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : const Icon(
                                  Icons.bolt_rounded,
                                  key: ValueKey('i'),
                                ),
                        ),
                        label: const Text('Comprobar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_results != null) ...[
          SectionHeader(
            title: 'Resultados',
            trailing: Text(
              '${_results!.where((e) => e.cached != null).length}/${_results!.length} en caché',
              style: theme.textTheme.labelMedium,
            ),
          ).let((w) => SliverToBoxAdapter(child: w)),
          SliverList.builder(
            itemCount: _results!.length,
            itemBuilder: (context, i) {
              final e = _results![i];
              final hit = e.cached != null;
              final color = hit
                  ? const Color(0xFF34D399)
                  : theme.colorScheme.onSurfaceVariant;
              return EntranceAnimation(
                index: i,
                child: SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconBadge(
                            icon: hit
                                ? Icons.bolt_rounded
                                : Icons.hourglass_empty_rounded,
                            color: color,
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.cached?.name ?? e.input,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    StatusPill(
                                      label: hit
                                          ? 'En caché'
                                          : 'No está en caché',
                                      color: color,
                                    ),
                                    if (hit)
                                      StatusPill(
                                        label: getReadableSize(e.cached!.size),
                                      ),
                                    if ((e.cached?.files?.length ?? 0) > 0)
                                      StatusPill(
                                        label:
                                            '${e.cached!.files!.length} files',
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_kind == _Kind.torrent)
                            TextButton.icon(
                              onPressed: () => _info(e),
                              icon: const Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                              ),
                              label: const Text('Info'),
                            ),
                          if (_kind != _Kind.usenet ||
                              e.input.startsWith('http'))
                            TextButton.icon(
                              onPressed: () => _add(e),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Añadir'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
