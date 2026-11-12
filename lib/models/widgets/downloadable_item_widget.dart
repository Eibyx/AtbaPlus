import 'package:atba/models/library_items/downloadable_item.dart';
import 'package:atba/models/widgets/downloadable_item_detail_screen.dart';
import 'package:atba/models/widgets/library_item_card.dart';
import 'package:atba/widgets/motion.dart';
import 'package:atba/services/library_page_state.dart';
import 'package:atba/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DownloadableItemWidget extends StatelessWidget {
  final DownloadableItem item;

  const DownloadableItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<LibraryPageState>(context);
    final isSelected = state.selectedItems.any(
      (selectedItem) => selectedItem.id == item.id,
    );
    final isCensored = state.isTorrentNamesCensored;

    void handleTap() {
      if (state.isSelecting) {
        state.toggleSelection(item);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DownloadableItemDetailScreen(item: item),
          ),
        );
      }
    }

    final (IconData icon, Color color) = switch (item.itemStatus) {
      DownloadableItemStatus.error => (
        Icons.error_rounded,
        const Color(0xFFF87171),
      ),
      DownloadableItemStatus.success => (
        Icons.check_rounded,
        const Color(0xFF34D399),
      ),
      _ => switch (item.downloadState.toLowerCase()) {
        final s when s.contains('download') => (
          Icons.cloud_download_rounded,
          const Color(0xFF60A5FA),
        ),
        final s when s.contains('complete') || s.contains('cached') => (
          Icons.check_circle_rounded,
          const Color(0xFF34D399),
        ),
        final s when s.contains('error') || s.contains('fail') => (
          Icons.error_rounded,
          const Color(0xFFF87171),
        ),
        final s when s.contains('pause') || s.contains('queue') => (
          Icons.pause_rounded,
          const Color(0xFFFBBF24),
        ),
        _ => (Icons.insert_drive_file_rounded, const Color(0xFF9CA3AF)),
      },
    };

    return LibraryItemCard(
      title: item.name,
      censored: isCensored,
      selected: isSelected,
      selecting: state.isSelecting,
      leading: StatusBadge(
        icon: icon,
        color: color,
        loading: item.itemStatus == DownloadableItemStatus.loading,
      ),
      subtitle: switch (item.itemStatus) {
        DownloadableItemStatus.loading => const Text('Working…'),
        DownloadableItemStatus.error => Text(
          item.errorMessage ?? 'Error loading item',
        ),
        DownloadableItemStatus.success => const Text('Done'),
        _ => Align(
          alignment: Alignment.centerLeft,
          child: StatusPill(label: item.downloadState, color: color),
        ),
      },
      trailing: getReadableSize(item.size),
      onLongPress: () => state.startSelection(item),
      onTap: handleTap,
    );
  }
}
