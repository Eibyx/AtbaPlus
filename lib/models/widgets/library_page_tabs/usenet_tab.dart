import 'package:atba/models/widgets/downloadable_item_widget.dart';
import 'package:atba/models/widgets/search_bar.dart';
import 'package:atba/services/library_page_state.dart';
import 'package:atba/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UsenetTab extends StatelessWidget {
  final LibraryPageState state;

  const UsenetTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (state.isSearching)
          DownloadsSearchBar(
            controller: state.searchController,
            focusNode: state.searchControllerFocusNode,
          ),
        SliverFillRemaining(
          hasScrollBody: true,
          child: RefreshIndicator(
            key: state.usenetRefreshIndicatorKey,
            onRefresh: () async {
              await state.refreshUsenet(bypassCache: true);
            },
            child: FutureBuilder(
              future: state.usenetFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data as Map<String, dynamic>;
                  if (data.containsKey("success") && data["success"] != true) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'No se pudieron cargar los datos: ${data["detail"]}',
                              style: const TextStyle(color: Colors.red),
                            ),
                            data["stackTrace"] != null
                                ? ElevatedButton(
                                    child: const Text(
                                      'Copiar detalles del error',
                                    ),
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: data["stackTrace"].toString(),
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Detalles copiados'),
                                        ),
                                      );
                                    },
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                    );
                  }

                  return state.usenetDownloads.isNotEmpty
                      ? ListView.builder(
                          physics: const ScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8, bottom: 96),
                          itemCount: state.filteredSortedUsenetDownloads.length,
                          itemBuilder: (context, index) {
                            final download =
                                state.filteredSortedUsenetDownloads[index];
                            return EntranceAnimation(
                              index: index < 10 ? index : 0,
                              child: DownloadableItemWidget(item: download),
                            );
                          },
                        )
                      : const Center(child: Text('No hay descargas Usenet'));
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
