import 'package:atba/config/constants.dart';
import 'package:atba/l10n.dart';
import 'package:atba/models/library_items/downloadable_item.dart';
import 'package:atba/models/library_items/library_item.dart';
import 'package:atba/models/library_items/queued_torrent.dart';
import 'package:atba/models/library_items/torrent.dart';
import 'package:atba/models/widgets/downloadable_item_detail_screen.dart';
import 'package:atba/models/widgets/library_item_card.dart';
import 'package:atba/widgets/motion.dart';
import 'package:atba/services/library_page_state.dart';
import 'package:atba/services/torrent_name_parser.dart';
import 'package:atba/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:provider/provider.dart';

const _blue = Color(0xFF60A5FA);
const _green = Color(0xFF34D399);
const _amber = Color(0xFFFBBF24);
const _grey = Color(0xFF9CA3AF);
const _red = Color(0xFFF87171);

class TorrentWidget extends StatelessWidget {
  final Torrent torrent;
  const TorrentWidget({super.key, required this.torrent});

  /* Torrent states:
  TorBox:
  "downloading" -> The torrent is currently downloading.
  "uploading" -> The torrent is currently seeding.
  "stalled (no seeds)" -> The torrent is trying to download, but there are no seeds connected to download from.
  "paused" -> The torrent is paused.
  "completed" -> The torrent is completely downloaded. Do not use this for download completion status.
  "cached" -> The torrent is cached from the server.
  "metaDL" -> The torrent is downloading metadata from the hoard.
  "checkingResumeData" -> The torrent is checking resumable data.

  Qbittorrent:
  error 	Some error occurred, applies to paused torrents
  missingFiles 	Torrent data files is missing
  uploading 	Torrent is being seeded and data is being transferred
  pausedUP 	Torrent is paused and has finished downloading
  queuedUP 	Queuing is enabled and torrent is queued for upload
  stalledUP 	Torrent is being seeded, but no connection were made
  checkingUP 	Torrent has finished downloading and is being checked
  forcedUP 	Torrent is forced to uploading and ignore queue limit
  allocating 	Torrent is allocating disk space for download
  downloading 	Torrent is being downloaded and data is being transferred
  metaDL 	Torrent has just started downloading and is fetching metadata
  pausedDL 	Torrent is paused and has NOT finished downloading
  queuedDL 	Queuing is enabled and torrent is queued for download
  stalledDL 	Torrent is being downloaded, but no connection were made
  checkingDL 	Same as checkingUP, but torrent has NOT finished downloading
  forcedDL 	Torrent is forced to downloading to ignore queue limit
  checkingResumeData 	Checking resume data on qBt startup
  moving 	Torrent is moving to another location
  */

  static const Map<String, Map<String, dynamic>> torrentStatuses = {
    // TorBox
    "downloading": {"color": _blue, "icon": Icons.cloud_download_rounded},
    "uploading": {"color": _green, "icon": Icons.cloud_upload_rounded},
    "stalled (no seeds)": {"color": _amber, "icon": Icons.stop_rounded},
    "paused": {"color": _grey, "icon": Icons.pause_rounded},
    "completed": {"color": _green, "icon": Icons.check_circle_rounded},
    "cached": {"color": _grey, "icon": Icons.cached_rounded},
    "metaDL": {"color": _amber, "icon": Icons.arrow_circle_down_rounded},
    "checkingResumeData": {"color": _amber, "icon": Icons.stop_rounded},
    // Qbittorrent
    "error": {"color": _red, "icon": Icons.error_rounded},
    "missingFiles": {"color": _red, "icon": Icons.error_rounded},
    "pausedUP": {"color": _amber, "icon": Icons.pause_rounded},
    "queuedUP": {"color": _amber, "icon": Icons.arrow_circle_down_rounded},
    "uploading (no peers)": {
      "color": _amber,
      "icon": Icons.cloud_upload_rounded,
    },
    "stalledUP": {"color": _amber, "icon": Icons.stop_rounded},
    "checkingUP": {"color": _amber, "icon": Icons.stop_rounded},
    "forcedUP": {"color": _amber, "icon": Icons.stop_rounded},
    "allocating": {"color": _amber, "icon": Icons.stop_rounded},
    "pausedDL": {"color": _amber, "icon": Icons.pause_rounded},
    "queuedDL": {"color": _amber, "icon": Icons.arrow_circle_down_rounded},
    "stalledDL": {"color": _amber, "icon": Icons.stop_rounded},
    "checkingDL": {"color": _amber, "icon": Icons.stop_rounded},
    "forcedDL": {"color": _amber, "icon": Icons.stop_rounded},
    "moving": {"color": _amber, "icon": Icons.stop_rounded},
  };

  @override
  Widget build(BuildContext context) {
    final torrentState = torrent.active
        ? torrent.downloadState
        : torrent.downloadState == "uploading"
        ? "cached"
        : torrent.downloadState;

    return _BaseTorrentWidget(
      item: torrent,
      leading: _buildLeading(torrentState),
      subtitle: _buildSubtitle(torrentState),
      trailing: getReadableSize(torrent.size),
      onDetailTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DownloadableItemDetailScreen(item: torrent),
        ),
      ),
    );
  }

  Widget _buildLeading(String torrentState) {
    switch (torrent.itemStatus) {
      case DownloadableItemStatus.loading:
        return const StatusBadge(icon: Icons.sync, color: _blue, loading: true);
      case DownloadableItemStatus.success:
        return const StatusBadge(icon: Icons.check_rounded, color: _green);
      case DownloadableItemStatus.error:
        return const StatusBadge(icon: Icons.error_rounded, color: _red);
      default:
        return StatusBadge(
          icon: torrentStatuses[torrentState]?['icon'] ?? Icons.question_mark,
          color: torrentStatuses[torrentState]?['color'] ?? _grey,
        );
    }
  }

  Widget _buildSubtitle(String torrentState) {
    switch (torrent.itemStatus) {
      case DownloadableItemStatus.loading:
        return const Text('Procesando…');
      case DownloadableItemStatus.success:
        return const Text('Listo');
      case DownloadableItemStatus.error:
        return Text('Error: ${torrent.errorMessage}');
      default:
        final color = torrentStatuses[torrentState]?['color'] as Color?;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: [
                StatusPill(label: tr(torrentState), color: color),
                if (torrent.ratio != 0)
                  StatusPill(
                    label: torrent.ratio.toStringAsFixed(2),
                    icon: Icons.swap_vert_rounded,
                  ),
                if (torrent.active)
                  StatusPill(
                    label: formatTimeDifference(
                      DateTime.now().difference(torrent.createdAt),
                    ),
                    icon: Icons.schedule_rounded,
                  ),
              ],
            ),
            if (torrentState.toLowerCase() == 'downloading')
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedProgressBar(
                        value: torrent.progress,
                        color: _blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${(torrent.progress * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              ),
          ],
        );
    }
  }
}

class QueuedTorrentWidget extends StatelessWidget {
  final QueuedTorrent torrent;
  const QueuedTorrentWidget({super.key, required this.torrent});

  @override
  Widget build(BuildContext context) {
    return _BaseTorrentWidget(
      item: torrent,
      leading: _buildLeading(),
      subtitle: _buildSubtitle(),
    );
  }

  Widget _buildLeading() {
    switch (torrent.status) {
      case TorrentStatus.loading:
        return const StatusBadge(icon: Icons.sync, color: _blue, loading: true);
      case TorrentStatus.success:
        return const StatusBadge(icon: Icons.check_rounded, color: _green);
      case TorrentStatus.error:
        return const StatusBadge(icon: Icons.error_rounded, color: _red);
      default:
        return const StatusBadge(icon: Icons.queue_rounded, color: _amber);
    }
  }

  Widget _buildSubtitle() {
    switch (torrent.status) {
      case TorrentStatus.loading:
        return const Text('Procesando…');
      case TorrentStatus.success:
        return const Text('Listo');
      case TorrentStatus.error:
        return Text('Error: ${torrent.errorMessage}');
      default:
        return const StatusPill(label: 'queued', color: _amber);
    }
  }
}

class _BaseTorrentWidget extends StatelessWidget {
  final LibraryItem item;
  final Widget leading;
  final Widget? subtitle;
  final String? trailing;
  final VoidCallback? onDetailTap;

  const _BaseTorrentWidget({
    required this.item,
    required this.leading,
    this.subtitle,
    this.trailing,
    this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LibraryPageState>(context);
    final isCensored = state.isTorrentNamesCensored;
    final isSelected = state.selectedItems.any(
      (selectedItem) =>
          selectedItem.id == item.id &&
          selectedItem.runtimeType == item.runtimeType,
    );

    void handleTap() {
      if (state.isSelecting) {
        state.toggleSelection(item);
      } else {
        onDetailTap?.call();
      }
    }

    return LibraryItemCard(
      title:
          Settings.getValue<bool>(
            Constants.useTorrentNameParsing,
            defaultValue: false,
          )!
          ? parse(item.name)['title']
          : item.name,
      censored: isCensored,
      selected: isSelected,
      selecting: state.isSelecting,
      leading: leading,
      subtitle: subtitle,
      trailing: trailing,
      onTap: handleTap,
      onLongPress: () => state.startSelection(item),
    );
  }
}
