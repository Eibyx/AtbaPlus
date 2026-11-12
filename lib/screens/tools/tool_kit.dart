import 'package:atba/services/torbox_service.dart';
import 'package:atba/theme/app_theme.dart';
import 'package:atba/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:torbox_api/torbox_api.dart';

/// Returns the typed TorBox client, or null if no API key is set.
TorboxApi? torboxApiOf(BuildContext context) =>
    Provider.of<TorboxAPI>(context, listen: false).api;

/// Converts any thrown error into a user-readable message.
String describeError(Object error) {
  if (error is TorboxApiException) {
    return error.detail ?? error.errorCode ?? error.message;
  }
  return error.toString();
}

/// Runs [call] and shows a toast for success / failure. Returns the response
/// on success, null otherwise.
Future<TorBoxResponse<T>?> runApiAction<T>(
  BuildContext context,
  Future<TorBoxResponse<T>> Function(TorboxApi api) call, {
  String? successMessage,
}) async {
  final api = torboxApiOf(context);
  if (api == null) {
    showToast(context, 'Primero añade tu clave API', type: ToastType.error);
    return null;
  }
  try {
    final response = await call(api);
    if (!context.mounted) return response;
    if (response.success) {
      showToast(
        context,
        successMessage ?? response.detail ?? 'Listo',
        type: ToastType.success,
      );
      return response;
    }
    showToast(
      context,
      response.detail ?? response.error ?? 'La petición falló',
      type: ToastType.error,
    );
  } catch (e) {
    if (context.mounted) {
      showToast(context, describeError(e), type: ToastType.error);
    }
  }
  return null;
}

/// Copies [text] to the clipboard with a toast.
Future<void> copyToClipboard(
  BuildContext context,
  String text, {
  String label = 'Copiado al portapapeles',
}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showToast(context, label, type: ToastType.success);
}

/// Scaffold with a large collapsing title used by every tool screen.
class ToolScaffold extends StatelessWidget {
  final String title;
  final List<Widget> slivers;
  final List<Widget>? actions;
  final Future<void> Function()? onRefresh;
  final Widget? floatingActionButton;

  const ToolScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.actions,
    this.onRefresh,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final scroll = CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverAppBar.medium(
          title: Text(title),
          actions: actions,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        ...slivers,
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: onRefresh == null
          ? scroll
          : RefreshIndicator(onRefresh: onRefresh!, child: scroll),
    );
  }
}

/// Loads data from the TorBox API and renders loading / error / data states
/// with animated transitions. Exposes [ApiLoaderState.reload] via a key.
class ApiLoader<T> extends StatefulWidget {
  final Future<TorBoxResponse<T>> Function(TorboxApi api) load;
  final List<Widget> Function(BuildContext context, T data, VoidCallback reload)
  builder;
  final String title;
  final List<Widget> Function(BuildContext context, VoidCallback reload)?
  actions;
  final Widget? Function(BuildContext context, VoidCallback reload)? fab;
  final bool Function(T data)? isEmpty;
  final Widget? emptyState;

  const ApiLoader({
    super.key,
    required this.title,
    required this.load,
    required this.builder,
    this.actions,
    this.fab,
    this.isEmpty,
    this.emptyState,
  });

  @override
  State<ApiLoader<T>> createState() => ApiLoaderState<T>();
}

class ApiLoaderState<T> extends State<ApiLoader<T>> {
  T? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    final api = torboxApiOf(context);
    if (api == null) {
      setState(() {
        _loading = false;
        _error = 'Añade tu clave API de TorBox en Ajustes para usar esta herramienta.';
      });
      return;
    }
    if (_data == null) setState(() => _loading = true);
    try {
      final response = await widget.load(api);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (response.success && response.data != null) {
          _data = response.data as T;
          _error = null;
        } else if (response.success) {
          _data = null;
          _error = null;
        } else {
          _error = response.detail ?? response.error ?? 'La petición falló';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = describeError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> body;
    if (_loading && _data == null) {
      body = [
        const SliverFillRemaining(
          hasScrollBody: true,
          child: SkeletonList(count: 6),
        ),
      ];
    } else if (_error != null && _data == null) {
      body = [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Algo salió mal',
            message: _error,
            action: FilledButton.icon(
              onPressed: reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ),
        ),
      ];
    } else if (_data == null ||
        (widget.isEmpty != null && widget.isEmpty!(_data as T))) {
      body = [
        SliverFillRemaining(
          hasScrollBody: false,
          child:
              widget.emptyState ??
              const EmptyState(icon: Icons.inbox_rounded, title: 'No hay nada'),
        ),
      ];
    } else {
      body = widget.builder(context, _data as T, reload);
    }
    return ToolScaffold(
      title: widget.title,
      onRefresh: reload,
      actions: widget.actions?.call(context, reload),
      floatingActionButton: widget.fab?.call(context, reload),
      slivers: body,
    );
  }
}

/// A key/value row, optionally copyable.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  final bool obscure;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.copyable = false,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: copyable ? () => copyToClipboard(context, value) : null,
      pressedScale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: Text(
                obscure ? '•' * value.length.clamp(6, 16) : value,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (copyable) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.copy_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Large number tile used on dashboards.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int index;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return EntranceAnimation(
      index: index,
      child: SurfaceCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconBadge(icon: icon, color: color, size: 30),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-column grid of [StatTile]s as a sliver.
class StatGrid extends StatelessWidget {
  final List<StatTile> tiles;

  const StatGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      sliver: SliverGrid.count(
        crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
        children: tiles,
      ),
    );
  }
}

/// Shows a modern bottom sheet with a title and [child].
Future<R?> showToolSheet<R>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext context) builder,
}) {
  return showModalBottomSheet<R>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            builder(context),
          ],
        ),
      ),
    ),
  );
}

/// Asks for confirmation before a destructive action.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  bool destructive = true,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Formats an ISO date string as a short, local date/time.
String formatDate(String? iso, {bool withTime = true}) {
  if (iso == null) return '—';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  String two(int v) => v.toString().padLeft(2, '0');
  final date = '${d.year}-${two(d.month)}-${two(d.day)}';
  return withTime ? '$date ${two(d.hour)}:${two(d.minute)}' : date;
}

/// Relative "x ago" label.
String timeAgo(String? iso) {
  final d = iso == null ? null : DateTime.tryParse(iso);
  if (d == null) return '—';
  final diff = DateTime.now().difference(d.toLocal());
  if (diff.inDays > 30) return formatDate(iso, withTime: false);
  if (diff.inDays > 0) return 'hace ${diff.inDays} d';
  if (diff.inHours > 0) return 'hace ${diff.inHours} h';
  if (diff.inMinutes > 0) return 'hace ${diff.inMinutes} min';
  return 'ahora mismo';
}

/// Pads list items consistently.
const EdgeInsets kSheetFieldGap = EdgeInsets.only(bottom: 12);

/// Default radius for small inner elements.
BorderRadius get kInnerRadius => BorderRadius.circular(AppRadius.md);
