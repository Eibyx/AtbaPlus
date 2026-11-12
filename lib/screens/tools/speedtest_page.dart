import 'dart:async';
import 'dart:math' as math;

import 'package:atba/screens/tools/tool_kit.dart';
import 'package:atba/theme/app_theme.dart';
import 'package:atba/widgets/motion.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:torbox_api/torbox_api.dart';

/// Downloads a TorBox speed-test file from a chosen CDN region and measures
/// throughput live.
class SpeedtestPage extends StatefulWidget {
  const SpeedtestPage({super.key});

  @override
  State<SpeedtestPage> createState() => _SpeedtestPageState();
}

class _SpeedtestPageState extends State<SpeedtestPage> {
  static const _maxDuration = Duration(seconds: 12);

  List<SpeedtestFileData>? _servers;
  SpeedtestFileData? _selected;
  String? _error;
  bool _running = false;
  double _mbps = 0;
  double _peak = 0;
  double _progress = 0;
  CancelToken? _cancel;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  Future<void> _loadServers() async {
    final api = torboxApiOf(context);
    if (api == null) {
      setState(() => _error = 'Primero añade tu clave API.');
      return;
    }
    try {
      final r = await api.general.getSpeedtestFiles(testLength: 1);
      if (!mounted) return;
      final list = r.data ?? [];
      setState(() {
        _servers = list;
        _selected =
            list.where((s) => s.closest).firstOrNull ?? list.firstOrNull;
      });
    } catch (e) {
      if (mounted) setState(() => _error = describeError(e));
    }
  }

  Future<void> _run() async {
    final server = _selected;
    if (server == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _running = true;
      _mbps = 0;
      _peak = 0;
      _progress = 0;
    });
    final cancel = _cancel = CancelToken();
    final sw = Stopwatch()..start();
    var received = 0;
    final timer = Timer(_maxDuration, () => cancel.cancel('time'));
    try {
      final response = await Dio().get<ResponseBody>(
        server.url,
        cancelToken: cancel,
        options: Options(responseType: ResponseType.stream),
      );
      var lastUi = 0;
      await for (final chunk in response.data!.stream) {
        received += chunk.length;
        final ms = sw.elapsedMilliseconds;
        if (ms - lastUi > 120 && mounted) {
          lastUi = ms;
          final mbps = received * 8 / (ms / 1000) / 1e6;
          setState(() {
            _mbps = mbps;
            _peak = math.max(_peak, mbps);
            _progress = ms / _maxDuration.inMilliseconds;
          });
        }
      }
    } on DioException catch (e) {
      if (!CancelToken.isCancel(e) && mounted) {
        showToast(context, describeError(e), type: ToastType.error);
      }
    } catch (e) {
      if (mounted) showToast(context, describeError(e), type: ToastType.error);
    } finally {
      timer.cancel();
      sw.stop();
      if (mounted) {
        final secs = sw.elapsedMilliseconds / 1000;
        setState(() {
          _running = false;
          _progress = 1;
          if (secs > 0 && received > 0) _mbps = received * 8 / secs / 1e6;
        });
        if (received > 0) {
          showToast(
            context,
            'Media de ${_mbps.toStringAsFixed(1)} Mbps desde ${server.name}',
            type: ToastType.success,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ToolScaffold(
      title: 'Test de velocidad',
      slivers: [
        if (_error != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.speed_rounded,
              title: 'Test de velocidad no disponible',
              message: _error,
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: EntranceAnimation(
              child: SurfaceCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: _mbps),
                        duration: AppMotion.medium,
                        curve: AppMotion.emphasized,
                        builder: (context, v, _) => CustomPaint(
                          painter: _GaugePainter(
                            value: (v / math.max(100, _peak * 1.2)).clamp(0, 1),
                            color: scheme.primary,
                            track: scheme.surfaceContainerHigh,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  v.toStringAsFixed(v >= 100 ? 0 : 1),
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                  ),
                                ),
                                Text('Mbps', style: theme.textTheme.labelLarge),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedOpacity(
                      opacity: _running ? 1 : 0,
                      duration: AppMotion.fast,
                      child: AnimatedProgressBar(value: _progress),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _peak > 0
                          ? 'Pico de ${_peak.toStringAsFixed(1)} Mbps'
                          : ' ',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _servers == null
                            ? null
                            : _running
                            ? () => _cancel?.cancel('user')
                            : _run,
                        icon: Icon(
                          _running
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(_running ? 'Detener' : 'Empezar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SectionHeader(title: 'Servidor')),
          if (_servers == null)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else
            SliverList.builder(
              itemCount: _servers!.length,
              itemBuilder: (context, i) {
                final s = _servers![i];
                final selected = s == _selected;
                return EntranceAnimation(
                  index: i,
                  child: SurfaceCard(
                    highlighted: selected,
                    onTap: _running
                        ? null
                        : () => setState(() => _selected = s),
                    child: Row(
                      children: [
                        IconBadge(
                          icon: Icons.location_on_rounded,
                          color: selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                          size: 36,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name, style: theme.textTheme.titleSmall),
                              Text(s.region, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        if (s.closest)
                          StatusPill(
                            label: 'Más cercano',
                            color: scheme.primary,
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

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color track;

  _GaugePainter({
    required this.value,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;
    final rect = Offset.zero & size;
    final stroke = size.width * 0.08;
    final arcRect = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(arcRect, start, sweep, false, base);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + sweep,
        colors: [color.withValues(alpha: 0.5), color],
        transform: const GradientRotation(0),
      ).createShader(rect);
    if (value > 0) canvas.drawArc(arcRect, start, sweep * value, false, fg);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color || old.track != track;
}
