import 'dart:async';

import 'package:atba/screens/tools/tool_kit.dart';
import 'package:atba/utils.dart';
import 'package:atba/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:torbox_api/torbox_api.dart';

class ServiceStatusPage extends StatefulWidget {
  const ServiceStatusPage({super.key});

  @override
  State<ServiceStatusPage> createState() => _ServiceStatusPageState();
}

class _ServiceStatusPageState extends State<ServiceStatusPage> {
  final _key = GlobalKey<ApiLoaderState<ServiceStatsData>>();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _key.currentState?.reload(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _num(int? v) {
    if (v == null) return '—';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    return ApiLoader<ServiceStatsData>(
      key: _key,
      title: 'Service status',
      load: (api) => api.general.getStats(),
      builder: (context, s, reload) => [
        SliverToBoxAdapter(
          child: SurfaceCard(
            child: Row(
              children: [
                Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.8, end: 1.3, duration: 900.ms)
                    .fade(begin: 0.5, end: 1),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text('TorBox is up · refreshes every 15s'),
                ),
              ],
            ),
          ),
        ),
        StatGrid(
          tiles: [
            StatTile(
              label: 'Users',
              value: _num(s.totalUsers),
              icon: Icons.people_rounded,
              color: const Color(0xFF60A5FA),
            ),
            StatTile(
              index: 1,
              label: 'Servers',
              value: _num(s.totalServers),
              icon: Icons.dns_rounded,
              color: const Color(0xFFA78BFA),
            ),
            StatTile(
              index: 2,
              label: 'Active torrents',
              value: _num(s.activeTorrents),
              icon: Icons.hub_rounded,
              color: const Color(0xFFFBBF24),
            ),
            StatTile(
              index: 3,
              label: 'Total downloads',
              value: _num(s.totalDownloads),
              icon: Icons.download_done_rounded,
              color: const Color(0xFF34D399),
            ),
            StatTile(
              index: 4,
              label: 'Download speed',
              value: '${getReadableSize(s.downloadSpeed ?? 0)}/s',
              icon: Icons.south_rounded,
              color: const Color(0xFF22D3EE),
            ),
            StatTile(
              index: 5,
              label: 'Upload speed',
              value: '${getReadableSize(s.uploadSpeed ?? 0)}/s',
              icon: Icons.north_rounded,
              color: const Color(0xFFF472B6),
            ),
            if (s.totalStreams != null)
              StatTile(
                index: 6,
                label: 'Streams',
                value: _num(s.totalStreams),
                icon: Icons.play_circle_rounded,
                color: const Color(0xFFFB923C),
              ),
            if (s.totalPlaybacks != null)
              StatTile(
                index: 7,
                label: 'Playbacks',
                value: _num(s.totalPlaybacks),
                icon: Icons.movie_rounded,
                color: const Color(0xFF4ADE80),
              ),
            if (s.p95FetchTime != null)
              StatTile(
                index: 8,
                label: 'p95 fetch time',
                value: '${s.p95FetchTime} ms',
                icon: Icons.timer_rounded,
                color: const Color(0xFF818CF8),
              ),
            if (s.p95StreamTime != null)
              StatTile(
                index: 9,
                label: 'p95 stream start',
                value: '${s.p95StreamTime} ms',
                icon: Icons.timelapse_rounded,
                color: const Color(0xFF2DD4BF),
              ),
          ],
        ),
      ],
    );
  }
}
