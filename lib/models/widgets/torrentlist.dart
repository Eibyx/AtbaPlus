import 'package:atba/models/widgets/search_bar.dart';
import 'package:atba/models/widgets/torrent_widget.dart';
import 'package:atba/theme/app_theme.dart';
import 'package:atba/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:atba/services/library_page_state.dart';

class TorrentsList extends StatefulWidget {
  const TorrentsList({super.key});

  @override
  State<TorrentsList> createState() => _TorrentsListState();
}

class _TorrentsListState extends State<TorrentsList> {
  bool _queuedExpanded = false;
  bool _activeExpanded = true;
  bool _inactiveExpanded = true;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LibraryPageState>(context);
    return CustomScrollView(
      slivers: [
        if (state.isSearching)
          DownloadsSearchBar(
            controller: state.searchController,
            focusNode: state.searchControllerFocusNode,
          ),
        ..._section(
          context,
          title: 'En cola',
          count: '${state.queuedTorrents.length}',
          expanded: _queuedExpanded,
          onToggle: () => setState(() => _queuedExpanded = !_queuedExpanded),
          itemCount: state.queuedTorrents.length,
          itemBuilder: (i) =>
              QueuedTorrentWidget(torrent: state.queuedTorrents[i]),
        ),
        ..._section(
          context,
          title: 'Activos',
          count:
              state.filteredSortedActiveTorrents.length ==
                  state.activeTorrents.length
              ? '${state.activeTorrents.length}'
              : '${state.filteredSortedActiveTorrents.length}/${state.activeTorrents.length}',
          expanded: _activeExpanded,
          onToggle: () => setState(() => _activeExpanded = !_activeExpanded),
          itemCount: state.filteredSortedActiveTorrents.length,
          itemBuilder: (i) =>
              TorrentWidget(torrent: state.filteredSortedActiveTorrents[i]),
        ),
        ..._section(
          context,
          title: 'Inactivos',
          count:
              state.filteredSortedInactiveTorrents.length ==
                  state.inactiveTorrents.length
              ? '${state.inactiveTorrents.length}'
              : '${state.filteredSortedInactiveTorrents.length}/${state.inactiveTorrents.length}',
          expanded: _inactiveExpanded,
          onToggle: () =>
              setState(() => _inactiveExpanded = !_inactiveExpanded),
          itemCount: state.filteredSortedInactiveTorrents.length,
          itemBuilder: (i) =>
              TorrentWidget(torrent: state.filteredSortedInactiveTorrents[i]),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  List<Widget> _section(
    BuildContext context, {
    required String title,
    required String count,
    required bool expanded,
    required VoidCallback onToggle,
    required int itemCount,
    required Widget Function(int i) itemBuilder,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return [
      SliverToBoxAdapter(
        child: SectionHeader(
          title: title,
          onTap: onToggle,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusPill(label: count, color: scheme.primary),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: expanded ? 0 : -0.25,
                duration: AppMotion.medium,
                curve: AppMotion.emphasized,
                child: Icon(
                  Icons.expand_more_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      if (expanded)
        SliverList.builder(
          itemCount: itemCount,
          itemBuilder: (context, i) =>
              EntranceAnimation(index: i < 10 ? i : 0, child: itemBuilder(i)),
        ),
    ];
  }
}
