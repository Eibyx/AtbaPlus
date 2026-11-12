import 'dart:convert';

import 'package:atba/models/custom_addon.dart';
import 'package:atba/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:http/http.dart' as http;

class StemioAddonsSettingsWidget extends StatefulWidget {
  const StemioAddonsSettingsWidget({
    super.key,
    required this.providers,
    required this.languages,
    required this.qualities,
  });

  final Map<String, String> providers;
  final Map<String, String> languages;
  final Map<String, String> qualities;

  @override
  State<StemioAddonsSettingsWidget> createState() =>
      _StemioAddonsSettingsWidgetState();
}

class _StemioAddonsSettingsWidgetState
    extends State<StemioAddonsSettingsWidget> {
  List<CustomAddon> customStremioAddons = [];

  @override
  void initState() {
    super.initState();
    final addonsJson = Settings.getValue(
      Constants.customStremioAddons,
      defaultValue: "[]",
    )!;
    try {
      final decoded = jsonDecode(addonsJson);
      if (decoded is List) {
        customStremioAddons = decoded
            .map((e) => CustomAddon.fromJson(e))
            .toList();
      }
    } catch (e) {
      // Handle error or set to default
    }
  }

  void _saveAddons() {
    Settings.setValue(
      Constants.customStremioAddons,
      jsonEncode(customStremioAddons),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpandableSettingsTile(
      title: "Addons de Stremio",
      leading: const Icon(Icons.language),
      children: [
        CheckboxSettingsTile(
          leading: const Icon(Icons.add_box),
          title: "Addon de TorBox",
          settingKey: Constants.torboxAddonEnabled,
        ),
        SimpleSettingsTile(
          title: "Torrentio",
          leading: const Icon(Icons.language),
          child: SettingsScreen(
            title: 'Ajustes de Torrentio',
            children: <Widget>[
              CheckboxSettingsTile(
                title: "Activar Torrentio",
                settingKey: Constants.torrentioEnabled,
                childrenIfEnabled: [
                  ExpandableSettingsTile(
                    title: "Proveedores",
                    children: [
                      for (var provider in widget.providers.keys)
                        CheckboxSettingsTile(
                          settingKey: '${Constants.keyProviderPrefix}$provider',
                          title: widget.providers[provider] ?? provider,
                          defaultValue: true,
                        ),
                    ],
                  ),
                  DropDownSettingsTile<int>(
                    title: "Ordenar por",
                    settingKey: Constants.torrentioSortBy,
                    values: const <int, String>{
                      1: 'Por calidad y luego seeders',
                      2: 'Por calidad y luego tamaño',
                      3: 'Por seeders',
                      4: 'Por tamaño',
                    },
                    selected: 1,
                  ),
                  ExpandableSettingsTile(
                    title: "Idioma prioritario",
                    children: [
                      for (var language
                          in widget.languages.keys.toList()..sort())
                        CheckboxSettingsTile(
                          settingKey: '${Constants.keyLanguagePrefix}$language',
                          title: widget.languages[language] ?? language,
                          defaultValue: false,
                        ),
                    ],
                  ),
                  ExpandableSettingsTile(
                    title: "Excluir calidades",
                    children: [
                      for (var quality in widget.qualities.keys)
                        CheckboxSettingsTile(
                          settingKey:
                              '${Constants.keyExcludeQualityPrefix}$quality',
                          title: widget.qualities[quality] ?? quality,
                          defaultValue: false,
                        ),
                    ],
                  ),
                  TextInputSettingsTile(
                    settingKey: Constants.torrentioMaxResultsPerQuality,
                    title: 'Máx. resultados por calidad',
                    keyboardType: TextInputType.number,
                    helperText: 'Vacío = sin límite. ',
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      if (int.tryParse(value) == null) {
                        return 'Número no válido';
                      }
                      return null;
                    },
                  ),
                  TextInputSettingsTile(
                    settingKey: Constants.torrentioVideoSizeLimit,
                    title: 'Límite de tamaño de vídeo',
                    keyboardType: TextInputType.number,
                    helperText: 'Vacío = sin límite; usa una coma para separar películas y series, p. ej. 5GB ; 800MB ; 10GB,2GB',
                    validator: (value) {
                      if (value == null || value.isEmpty) return null;
                      if (!RegExp(r'^([0-9.]*(?:MB|GB),?)+$').hasMatch(value)) {
                        return 'Tamaño no válido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        SettingsContainer(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: customStremioAddons.length,
                  itemBuilder: (context, index) {
                    final addon = customStremioAddons[index];
                    return ListTile(
                      key: ValueKey(addon.url),
                      title: Text(addon.name),
                      subtitle: Text(addon.url),
                      leading: const Icon(Icons.language_sharp),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            customStremioAddons.removeAt(index);
                          });
                          _saveAddons();
                        },
                      ),
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final addon = customStremioAddons.removeAt(oldIndex);
                      customStremioAddons.insert(newIndex, addon);
                    });
                    _saveAddons();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                  child: TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          final manifestController = TextEditingController();
                          return AlertDialog(
                            title: const Text("URL del manifest del addon"),
                            content: SingleChildScrollView(
                              child: TextField(
                                controller: manifestController,
                                decoration: const InputDecoration(
                                  hintText: "Escribe la URL…",
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                },
                                child: const Text("Cancelar"),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final addonManifest = await loadAddonManifest(
                                    manifestController.text,
                                  );
                                  final message = addonManifest.hasParsingError
                                      ? "Error: ${addonManifest.errorMessage}"
                                      : "${addonManifest.name} añadido";
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        message,
                                        style: TextStyle(
                                          color: addonManifest.hasParsingError
                                              ? Colors.red
                                              : null,
                                        ),
                                      ),
                                    ),
                                  );
                                  if (!addonManifest.hasParsingError) {
                                    setState(() {
                                      customStremioAddons.add(
                                        CustomAddon(
                                          name: addonManifest.name!,
                                          url: manifestController.text,
                                        ),
                                      );
                                    });
                                    _saveAddons();
                                  }
                                  Navigator.of(dialogContext).pop();
                                },
                                child: const Text("Añadir"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Añadir addon"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class ParsedAddon {
  final bool hasParsingError;
  final String? errorMessage;
  final String? name;

  ParsedAddon({required this.hasParsingError, this.errorMessage, this.name});
}

Future<ParsedAddon> loadAddonManifest(String url) async {
  Uri? addonUrl = Uri.tryParse(url);
  if (addonUrl == null) {
    return ParsedAddon(hasParsingError: true, errorMessage: "URL no válida");
  }
  try {
    final response = await http.read(addonUrl);
    final json = jsonDecode(response);
    final name = json["name"];
    return ParsedAddon(hasParsingError: false, name: name);
  } catch (error) {
    return ParsedAddon(hasParsingError: true, errorMessage: "$error");
  }
}
