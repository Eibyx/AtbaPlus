import 'dart:async' show StreamSubscription;
import 'dart:io';

import 'package:atba/services/torbox_service.dart' show TorboxAPI;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:listen_sharing_intent/listen_sharing_intent.dart';

import 'package:atba/screens/library_page.dart';
import 'package:atba/screens/watch_page.dart';
import 'package:atba/screens/settings/settings_page.dart';
import 'package:atba/screens/tools/tools_page.dart';
import 'package:atba/theme/app_theme.dart';
import 'package:atba/widgets/motion.dart';
import 'package:torbox_api/torbox_api.dart';

/// Root screen of the app (tabs). The MaterialApp lives in [ThemedApp].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const MyHomePage();
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription? _intentSubscription;
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();

    initDeepLinks();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // Only initialize sharing intent on mobile platforms
      initHandleIntent();
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _intentSubscription?.cancel();
    super.dispose();
  }

  Future<void> handleTorrentFiles(List<SharedMediaFile> value) async {
    final apiService = Provider.of<TorboxAPI>(context, listen: false);
    for (final file in value) {
      if (file.type == SharedMediaType.file) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Añadiendo torrent: ${file.path}')),
        );
        final response = await apiService.createTorrent(
          dotTorrentFile: TorboxFileUpload(
            filename: file.path.split(Platform.pathSeparator).last,
            bytes: await File(file.path).readAsBytes(),
          ),
        );
        if (response.success) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('¡Torrent añadido!')));
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(response.detailOrUnknown)));
        }
      } else if (file.type == SharedMediaType.text) {
        final uri = Uri.tryParse(file.path);
        if (uri == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Enlace no válido: ${file.path}')),
          );
          continue;
        }
        // Handle text sharing (for links)
        if (uri.scheme == "magnet") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Añadiendo torrent: ${file.path}')),
          );
          final response = await apiService.createTorrent(
            magnetLink: file.path,
          );
          if (response.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('¡Torrent añadido!')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No se pudo añadir el torrent: ${response.error}',
                ),
              ),
            );
          }
        } else {
          // add as web download
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Añadiendo descarga: ${file.path}')),
          );
          final response = await apiService.createWebDownload(uri.toString());
          if (response.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('¡Descarga añadida!')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'No se pudo añadir la descarga: ${response.error}',
                ),
              ),
            );
          }
        }
      }
    }
  }

  Future<void> initHandleIntent() async {
    _intentSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (value) async {
        await handleTorrentFiles(value);
      },
      onError: (err) {
        print("getIntentDataStream error: $err");
      },
    );

    // Get the media sharing coming from outside the app while the app is closed (e.g. open torrent file in file app)
    ReceiveSharingIntent.instance.getInitialMedia().then((value) async {
      if (value.isEmpty) return;
      await handleTorrentFiles(value);
      // Tell the library that we are done processing the intent.
      ReceiveSharingIntent.instance.reset();
    });
  }

  Future<void> initDeepLinks() async {
    // Handle links
    _linkSubscription = AppLinks().uriLinkStream.listen((uri) async {
      if (uri.scheme != "magnet") {
        return; // this will also catch opening files, but not sharing files, so we only use it for links
      }
      final apiService = Provider.of<TorboxAPI>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Añadiendo torrent: ${uri.toString()}')),
      );
      final response = await apiService.createTorrent(
        magnetLink: uri.toString(),
      );
      if (response.success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('¡Torrent añadido!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo añadir el torrent: ${response.error}'),
          ),
        );
      }
    });
  }

  static const List<Widget> _pages = <Widget>[
    LibraryPage(),
    WatchPage(),
    ToolsPage(),
    SettingsPage(),
  ];

  static const _navItems = <FloatingNavItem>[
    FloatingNavItem(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder_rounded,
      label: 'Biblioteca',
    ),
    FloatingNavItem(
      icon: Icons.play_circle_outline_rounded,
      selectedIcon: Icons.play_circle_rounded,
      label: 'Ver',
    ),
    FloatingNavItem(
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      label: 'Herramientas',
    ),
    FloatingNavItem(
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune_rounded,
      label: 'Ajustes',
    ),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Back on another tab returns to the library first.
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return;
        }
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;

          showToast(
            context,
            'Pulsa atrás otra vez para salir',
            duration: const Duration(seconds: 2),
          );
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: AppMotion.medium,
          switchInCurve: AppMotion.emphasized,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_selectedIndex),
            child: _pages[_selectedIndex],
          ),
        ),
        bottomNavigationBar: FloatingNavBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: _navItems,
        ),
      ),
    );
  }
}
