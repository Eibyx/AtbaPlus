import 'dart:convert';

import 'package:atba/l10n.dart';

import 'package:atba/models/library_items/queued_torrent.dart';
import 'package:atba/models/widgets/downloads_prompt.dart';
import 'package:atba/screens/jobs_status_page.dart';
import 'package:atba/screens/settings/library_settings_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:atba/config/constants.dart';
import 'package:atba/models/widgets/library_page_tabs/torrents_tab.dart';
import 'package:atba/models/widgets/library_page_tabs/web_downloads_tab.dart';
import 'package:atba/models/widgets/library_page_tabs/usenet_tab.dart';
import 'package:atba/models/widgets/library_page_tabs/add_tabs.dart';
import 'package:atba/services/torbox_service.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:iconsx_plus/iconsx_plus.dart';
import 'package:provider/provider.dart';
import 'package:atba/services/library_page_state.dart';
import 'package:icon_craft/icon_craft.dart';
import 'package:atba/theme/app_theme.dart';
import 'package:atba/widgets/motion.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasBeenViewedOnce = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<TorboxAPI>(context, listen: false);
    return ChangeNotifierProvider(
      create: (_) => LibraryPageState(context),
      child: Consumer<LibraryPageState>(
        builder: (context, state, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!_hasBeenViewedOnce &&
                Settings.getValue<bool>(
                  Constants.useCache,
                  defaultValue: true,
                )! &&
                Settings.getValue<bool>(
                  Constants.loadUncachedLibraryOnStart,
                  defaultValue: true,
                )! &&
                (await state.isCacheNotEmpty())) {
              _hasBeenViewedOnce = true;
              state.onLibraryPageFirstView();
            }
          });
          return PopScope(
            onPopInvokedWithResult: (didPop, result) {
              final focus = FocusManager
                  .instance
                  .primaryFocus; // mostly just the search focus
              if (focus != null) {
                focus.unfocus();
                return;
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: AnimatedSwitcher(
                  duration: AppMotion.medium,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    state.isSelecting
                        ? "${state.selectedItems.length} seleccionados"
                        : 'Biblioteca',
                    key: ValueKey(
                      state.isSelecting
                          ? 'sel${state.selectedItems.length}'
                          : 'title',
                    ),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md + 2),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Torrents'),
                        Tab(text: 'Web'),
                        Tab(text: 'Usenet'),
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (state.isSelecting)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.select_all_rounded),
                          onPressed: () {
                            state.selectAllItems();
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.flip_rounded),
                          onPressed: () {
                            state.invertSelection();
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.clear_rounded),
                          onPressed: () {
                            state.clearSelection();
                          },
                        ),
                      ],
                    )
                  else
                    Row(children: buildIcons(context, state)),
                ],
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  buildTorrentsTab(state, context),
                  WebDownloadsTab(state: state),
                  UsenetTab(state: state),
                ],
              ),
              bottomNavigationBar: state.isSelecting
                  ? Glass(
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  if (state.selectedItems.any(
                                    (item) => item is QueuedTorrent,
                                  )) ...[
                                    IconButton(
                                      icon: Icon(Icons.play_arrow_rounded),
                                      onPressed: () {
                                        state.resumeSelectedItems();
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_rounded),
                                      onPressed: () {
                                        state.deleteSelectedItems();
                                      },
                                    ),
                                  ] else ...[
                                    IconButton(
                                      icon: Icon(Icons.stop_rounded),
                                      onPressed: () {
                                        state.stopSelectedItems();
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.refresh_rounded),
                                      onPressed: () {
                                        state.reannounceSelectedItems();
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_rounded),
                                      onPressed: () {
                                        state.deleteSelectedItems();
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.download_rounded),
                                      onPressed: () async {
                                        if (Settings.getValue<String>(
                                              Constants.folderPath,
                                            ) ==
                                            null) {
                                          bool granted =
                                              await showPermissionDialog(
                                                context,
                                              );
                                          if (granted) {
                                            state.downloadSelectedItems();
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Permiso denegado. No se puede descargar.',
                                                    ),
                                                  ),
                                                );
                                          }
                                        } else {
                                          state.downloadSelectedItems();
                                        }
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .slideY(
                          begin: 1,
                          duration: AppMotion.medium,
                          curve: AppMotion.emphasized,
                        )
                        .fadeIn()
                  : null,
              floatingActionButton: state.isSelecting
                  ? const SizedBox.shrink()
                  : AnimatedBuilder(
                      animation: _tabController.animation!,
                      builder: (context, child) {
                        // Calculate the current and next tab index
                        final animationValue = _tabController.animation!.value;
                        final currentIndex = _tabController.index;
                        final nextIndex = animationValue.round();
                        // Determine if we're transitioning and how far
                        final transitionProgress =
                            (animationValue - currentIndex).abs();
                        // If transition is more than halfway, use next tab's icon
                        int iconTabIndex;
                        if (transitionProgress > 0.5) {
                          iconTabIndex = nextIndex;
                        } else {
                          iconTabIndex = currentIndex;
                        }
                        Icon getFabIcon() {
                          switch (iconTabIndex) {
                            case 0:
                              return const Icon(AntDesign.node_index_outline);
                            case 1:
                              return const Icon(Icons.cloud_download);
                            case 2:
                              return const Icon(Icons.hub);
                            default:
                              return const Icon(AntDesign.node_index_outline);
                          }
                        }

                        List<SpeedDialChild> getSpeedDialChildren() {
                          switch (iconTabIndex) {
                            case 1: // Web Downloads
                              return [
                                SpeedDialChild(
                                  child: const Icon(Icons.cloud_download),
                                  label: 'Enlace web',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddWebDownloadsTab(
                                              apiService: apiService,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ];
                            case 2: // Usenet
                              return [
                                SpeedDialChild(
                                  child: const Icon(Icons.link),
                                  label: 'NZB desde URL',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddNzbLinkTab(),
                                      ),
                                    );
                                  },
                                ),
                                SpeedDialChild(
                                  child: const Icon(Icons.upload_file),
                                  label: 'NZB desde archivo',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddNzbFileTab(),
                                      ),
                                    );
                                  },
                                ),
                                /*SpeedDialChild(
                                  child: const Icon(Icons.search),
                                  label: 'Search',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddUsenetSearchTab(),
                                      ),
                                    );
                                  },
                                ),*/
                              ];
                            case 0:
                            default:
                              return [
                                SpeedDialChild(
                                  child: const Icon(Icons.upload_file),
                                  label: 'Archivo .torrent',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddTorrentFileTab(),
                                      ),
                                    );
                                  },
                                ),
                                SpeedDialChild(
                                  child: const Icon(BoxIcons.bx_magnet),
                                  label: 'Magnet',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddMagnetTab(),
                                      ),
                                    );
                                  },
                                ),
                                /*SpeedDialChild(
                                  child: const Icon(Icons.search),
                                  label: 'Search',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddSearchTorrentTab(),
                                      ),
                                    );
                                  },
                                ),*/
                              ];
                          }
                        }

                        return SpeedDial(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(AppRadius.lg),
                            ),
                          ),
                          elevation: 0,
                          overlayOpacity: 0.35,
                          spacing: 8,
                          spaceBetweenChildren: 8,
                          animationCurve: Curves.easeOutBack,
                          childrenButtonSize: const Size(52, 52),
                          activeChild: const Icon(Icons.close),
                          direction: SpeedDialDirection.up,
                          children: getSpeedDialChildren(),
                          child: IconCraft(
                            const Icon(Icons.add),
                            getFabIcon(),
                            alignment: const Alignment(1.5, 1.5),
                          ),
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }

  IconButton buildBlurIcon(LibraryPageState state) {
    return IconButton(
      icon: state.isTorrentNamesCensored
          ? Icon(Icons.visibility)
          : Icon(Icons.visibility_off),
      tooltip: "Difuminar nombres",
      onPressed: () {
        state.toggleTorrentNamesCensoring();
      },
    );
  }

  IconButton buildFilterIcon(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.filter_list),
      tooltip: 'Filtrar',
      onPressed: () => _showFilterBottomSheet(context),
    );
  }

  MenuAnchor buildSortIcon(LibraryPageState state, BuildContext context) {
    return MenuAnchor(
      builder:
          (BuildContext context, MenuController controlller, Widget? child) {
            return IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () {
                if (controlller.isOpen) {
                  controlller.close();
                } else {
                  controlller.open();
                }
              },
              tooltip: "Ordenar",
            );
          },
      menuChildren: List<MenuItemButton>.generate(
        LibraryPageState.sortingOptions.length,
        (int index) => MenuItemButton(
          onPressed: () {
            state.updateSortingOption(
              LibraryPageState.sortingOptions.keys.elementAt(index),
            );
            // Navigator.pop(context);
          },
          child: Row(
            children: [
              Text(tr(LibraryPageState.sortingOptions.keys.elementAt(index))),
              if (state.selectedSortingOption ==
                  LibraryPageState.sortingOptions.keys.elementAt(index))
                Row(
                  children: [
                    SizedBox(width: 4),
                    Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconButton buildSearchIcon(LibraryPageState state) {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: () {
        state.toggleSearch();
      },
      tooltip: "Buscar",
    );
  }

  IconButton buildRefreshIcon(LibraryPageState state) {
    return IconButton(
      icon: const Icon(Icons.refresh_rounded),
      tooltip: "Actualizar",
      onPressed: () {
        state.torrentRefreshIndicatorKey.currentState?.show();
        state.webRefreshIndicatorKey.currentState?.show();
        state.usenetRefreshIndicatorKey.currentState?.show();
      },
    );
  }

  IconButton buildJobsIcon(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.work),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JobsStatusPage()),
        );
      },
      tooltip: "Trabajos de integración",
    );
  }

  List<Widget> buildIcons(BuildContext context, LibraryPageState state) {
    List<String> sortedIcons = jsonDecode(
      Settings.getValue(
        Constants.libraryIconsOrdering,
        defaultValue:
            LibrarySettingsTile.valueMaps[Constants.libraryIconsOrdering],
      )!,
    ).cast<String>();
    Map<String, bool> enabledIcons = jsonDecode(
      Settings.getValue(Constants.libraryIconsEnabled, defaultValue: "{}")!,
    ).cast<String, bool>();
    return sortedIcons.where((i) => enabledIcons[i] ?? true).map((iconString) {
      switch (LibraryIcons.fromString(iconString)) {
        case LibraryIcons.jobs:
          return buildJobsIcon(context);
        case LibraryIcons.reload:
          return buildRefreshIcon(state);
        case LibraryIcons.search:
          return buildSearchIcon(state);
        case LibraryIcons.sort:
          return buildSortIcon(state, context);
        case LibraryIcons.filter:
          return buildFilterIcon(context);
        case LibraryIcons.blur:
          return buildBlurIcon(state);
      }
    }).toList();
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (context2) {
        return ChangeNotifierProvider<LibraryPageState>.value(
          value: context.watch<LibraryPageState>(),
          builder: (context, _) {
            return Theme(
              data: Theme.of(context).copyWith(),
              child: StatefulBuilder(
                builder: (BuildContext _, StateSetter setState) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ListTile(title: Text('Principal')),
                        _buildMainFilters(context, setState),
                        // const ListTile(title: Text("Qualities")),
                        // _buildQualityFilters(context, setState),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMainFilters(BuildContext context, StateSetter setState) {
    return Consumer<LibraryPageState>(
      builder: (context, state, child) {
        return Wrap(
          spacing: 8.0,
          children: LibraryPageState.filters.keys.map((filter) {
            return FilterChip(
              label: Text(tr(filter), style: const TextStyle(fontSize: 12)),
              selected: state.selectedMainFilters.contains(filter),
              onSelected: (selected) {
                setState(() {
                  state.updateFilter(filter, selected);
                });
              },
              showCheckmark: false,
            );
          }).toList(),
        );
      },
    );
  }
}
