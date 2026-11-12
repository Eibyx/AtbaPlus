import 'package:atba/screens/tools/tool_kit.dart';
import 'package:atba/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:torbox_api/torbox_api.dart';

/// Edits the server-side TorBox account settings (`/user/settings`).
///
/// Every change is sent immediately as a single-field update, so the toggle
/// animates optimistically and rolls back if the request fails.
class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ApiLoader<UserData>(
      title: 'Ajustes de TorBox',
      load: (api) => api.user.getUserData(settings: true),
      builder: (context, user, reload) {
        final s = user.settings ?? const UserSettings();
        return [SliverToBoxAdapter(child: _SettingsBody(settings: s))];
      },
    );
  }
}

class _SettingsBody extends StatefulWidget {
  final UserSettings settings;
  const _SettingsBody({required this.settings});

  @override
  State<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends State<_SettingsBody> {
  late UserSettings s = widget.settings;

  Future<void> _update(
    UserSettings optimistic,
    Future<TorBoxResponse<Null>> Function(UserService user) call,
  ) async {
    final previous = s;
    setState(() => s = optimistic);
    final r = await runApiAction(
      context,
      (api) => call(api.user),
      successMessage: 'Guardado',
    );
    if (r == null && mounted) setState(() => s = previous);
  }

  Widget _switch({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool? value,
    required UserSettings Function(bool v) apply,
    required Future<TorBoxResponse<Null>> Function(UserService u, bool v) call,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value ?? false,
      onChanged: (v) => _update(apply(v), (u) => call(u, v)),
    );
  }

  Widget _text({
    required String title,
    required IconData icon,
    required String? value,
    bool secret = false,
    required UserSettings Function(String v) apply,
    required Future<TorBoxResponse<Null>> Function(UserService u, String v)
    call,
  }) {
    final shown = (value ?? '').isEmpty
        ? 'Sin configurar'
        : secret
        ? '••••••••'
        : value!;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(shown, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.edit_rounded, size: 18),
      onTap: () async {
        final controller = TextEditingController(text: secret ? '' : value);
        final result = await showToolSheet<String>(
          context,
          title: title,
          builder: (sheet) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                obscureText: secret,
                decoration: InputDecoration(labelText: title),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(sheet, controller.text.trim()),
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
        if (result == null) return;
        await _update(apply(result), (u) => call(u, result));
      },
    );
  }

  Widget _group(String title, int index, List<Widget> children) {
    return EntranceAnimation(
      index: index,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _group('Descargas', 0, [
          ListTile(
            leading: const Icon(Icons.upload_rounded),
            title: const Text('Seeding'),
            trailing: DropdownButton<int>(
              value: (s.seedTorrents ?? 1).clamp(1, 3),
              underline: const SizedBox(),
              borderRadius: BorderRadius.circular(16),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Automático')),
                DropdownMenuItem(value: 2, child: Text('Siempre')),
                DropdownMenuItem(value: 3, child: Text('Nunca')),
              ],
              onChanged: (v) {
                if (v == null) return;
                _update(
                  s.copyWith(seedTorrents: v),
                  (u) => u.editSettings(seedTorrents: v),
                );
              },
            ),
          ),
          _switch(
            title: 'Permitir descargas en ZIP',
            icon: Icons.folder_zip_rounded,
            value: s.allowZipped,
            apply: (v) => s.copyWith(allowZipped: v),
            call: (u, v) => u.editSettings(allowZipped: v),
          ),
          _switch(
            title: 'Añadir nombre de archivo a los enlaces',
            icon: Icons.link_rounded,
            value: s.appendFilenameToLinks,
            apply: (v) => s.copyWith(appendFilenameToLinks: v),
            call: (u, v) => u.editSettings(appendFilenameToLinks: v),
          ),
          _text(
            title: 'Selección de CDN',
            icon: Icons.dns_rounded,
            value: s.cdnSelection,
            apply: (v) => s.copyWith(cdnSelection: v),
            call: (u, v) => u.editSettings(cdnSelection: v),
          ),
        ]),
        _group('Notificaciones', 1, [
          _switch(
            title: 'Email',
            icon: Icons.email_rounded,
            value: s.emailNotifications,
            apply: (v) => s.copyWith(emailNotifications: v),
            call: (u, v) => u.editSettings(emailNotifications: v),
          ),
          _switch(
            title: 'Web',
            icon: Icons.web_rounded,
            value: s.webNotifications,
            apply: (v) => s.copyWith(webNotifications: v),
            call: (u, v) => u.editSettings(webNotifications: v),
          ),
          _switch(
            title: 'Móvil',
            icon: Icons.phone_iphone_rounded,
            value: s.mobileNotifications,
            apply: (v) => s.copyWith(mobileNotifications: v),
            call: (u, v) => u.editSettings(mobileNotifications: v),
          ),
          _switch(
            title: 'RSS',
            icon: Icons.rss_feed_rounded,
            value: s.rssNotifications,
            apply: (v) => s.copyWith(rssNotifications: v),
            call: (u, v) => u.editSettings(rssNotifications: v),
          ),
          _switch(
            title: 'Discord',
            icon: Icons.discord_rounded,
            value: s.discordNotifications,
            apply: (v) => s.copyWith(discordNotifications: v),
            call: (u, v) => u.editSettings(discordNotifications: v),
          ),
          _switch(
            title: 'Telegram',
            icon: Icons.telegram_rounded,
            value: s.telegramNotifications,
            apply: (v) => s.copyWith(telegramNotifications: v),
            call: (u, v) => u.editSettings(telegramNotifications: v),
          ),
          _text(
            title: 'Telegram ID',
            icon: Icons.badge_rounded,
            value: s.telegramId,
            apply: (v) => s.copyWith(telegramId: v),
            call: (u, v) => u.editSettings(telegramId: v),
          ),
          _switch(
            title: 'Webhook',
            icon: Icons.webhook_rounded,
            value: s.webhookNotifications,
            apply: (v) => s.copyWith(webhookNotifications: v),
            call: (u, v) => u.editSettings(webhookNotifications: v),
          ),
          _text(
            title: 'URL del webhook',
            icon: Icons.http_rounded,
            value: s.webhookUrl,
            apply: (v) => s.copyWith(webhookUrl: v),
            call: (u, v) => u.editSettings(webhookUrl: v),
          ),
          _switch(
            title: 'JDownloader',
            icon: Icons.download_rounded,
            value: s.jdownloaderNotifications,
            apply: (v) => s.copyWith(jdownloaderNotifications: v),
            call: (u, v) => u.editSettings(jdownloaderNotifications: v),
          ),
        ]),
        _group('Integraciones en la nube', 2, [
          _text(
            title: 'ID de carpeta de Google Drive',
            icon: Icons.add_to_drive_rounded,
            value: s.googleDriveFolderId,
            apply: (v) => s.copyWith(googleDriveFolderId: v),
            call: (u, v) => u.editSettings(googleDriveFolderId: v),
          ),
          _text(
            title: 'Ruta de OneDrive',
            icon: Icons.cloud_rounded,
            value: s.onedriveSavePath,
            apply: (v) => s.copyWith(onedriveSavePath: v),
            call: (u, v) => u.editSettings(onedriveSavePath: v),
          ),
          _text(
            title: 'ID de carpeta de Gofile',
            icon: Icons.folder_rounded,
            value: s.gofileFolderId,
            apply: (v) => s.copyWith(gofileFolderId: v),
            call: (u, v) => u.editSettings(gofileFolderId: v),
          ),
          _text(
            title: 'Clave API de Gofile',
            icon: Icons.key_rounded,
            value: s.gofileApiKey,
            secret: true,
            apply: (v) => s.copyWith(gofileApiKey: v),
            call: (u, v) => u.editSettings(gofileApiKey: v),
          ),
          _text(
            title: 'ID de carpeta de 1fichier',
            icon: Icons.folder_rounded,
            value: s.onefichierFolderId,
            apply: (v) => s.copyWith(onefichierFolderId: v),
            call: (u, v) => u.editSettings(onefichierFolderId: v),
          ),
          _text(
            title: 'Clave API de 1fichier',
            icon: Icons.key_rounded,
            value: s.onefichierApiKey,
            secret: true,
            apply: (v) => s.copyWith(onefichierApiKey: v),
            call: (u, v) => u.editSettings(onefichierApiKey: v),
          ),
          _text(
            title: 'Clave API de Pixeldrain',
            icon: Icons.key_rounded,
            value: s.pixeldrainApiKey,
            secret: true,
            apply: (v) => s.copyWith(pixeldrainApiKey: v),
            call: (u, v) => u.editSettings(pixeldrainApiKey: v),
          ),
          _text(
            title: 'Email de MEGA',
            icon: Icons.alternate_email_rounded,
            value: s.megaEmail,
            apply: (v) => s.copyWith(megaEmail: v),
            call: (u, v) => u.editSettings(megaEmail: v),
          ),
          _text(
            title: 'Contraseña de MEGA',
            icon: Icons.password_rounded,
            value: s.megaPassword,
            secret: true,
            apply: (v) => s.copyWith(megaPassword: v),
            call: (u, v) => u.editSettings(megaPassword: v),
          ),
        ]),
        _group('WebDAV', 3, [
          _switch(
            title: 'Vista de carpetas',
            icon: Icons.account_tree_rounded,
            value: s.webdavUseFolderView,
            apply: (v) => s.copyWith(webdavUseFolderView: v),
            call: (u, v) => u.editSettings(webdavUseFolderView: v),
          ),
          _switch(
            title: 'Aplanar carpetas',
            icon: Icons.layers_clear_rounded,
            value: s.webdavFlatten,
            apply: (v) => s.copyWith(webdavFlatten: v),
            call: (u, v) => u.editSettings(webdavFlatten: v),
          ),
          _switch(
            title: 'Usar archivos locales',
            icon: Icons.sd_storage_rounded,
            value: s.webdavUseLocalFiles,
            apply: (v) => s.copyWith(webdavUseLocalFiles: v),
            call: (u, v) => u.editSettings(webdavUseLocalFiles: v),
          ),
        ]),
        _group('Reproductor web', 4, [
          _switch(
            title: 'Transcodificar siempre',
            icon: Icons.transform_rounded,
            value: s.webPlayerAlwaysTranscode,
            apply: (v) => s.copyWith(webPlayerAlwaysTranscode: v),
            call: (u, v) => u.editSettings(webPlayerAlwaysTranscode: v),
          ),
          _switch(
            title: 'Saltar intro siempre',
            icon: Icons.skip_next_rounded,
            value: s.webPlayerAlwaysSkipIntro,
            apply: (v) => s.copyWith(webPlayerAlwaysSkipIntro: v),
            call: (u, v) => u.editSettings(webPlayerAlwaysSkipIntro: v),
          ),
          _switch(
            title: 'Scrobbling',
            icon: Icons.history_rounded,
            value: s.webPlayerEnableScrobbling,
            apply: (v) => s.copyWith(webPlayerEnableScrobbling: v),
            call: (u, v) => u.editSettings(webPlayerEnableScrobbling: v),
          ),
          _text(
            title: 'Idioma de audio preferido',
            icon: Icons.audiotrack_rounded,
            value: s.webPlayerAudioPreferredLanguage,
            apply: (v) => s.copyWith(webPlayerAudioPreferredLanguage: v),
            call: (u, v) => u.editSettings(webPlayerAudioPreferredLanguage: v),
          ),
          _text(
            title: 'Idioma de subtítulos preferido',
            icon: Icons.subtitles_rounded,
            value: s.webPlayerSubtitlePreferredLanguage,
            apply: (v) => s.copyWith(webPlayerSubtitlePreferredLanguage: v),
            call: (u, v) =>
                u.editSettings(webPlayerSubtitlePreferredLanguage: v),
          ),
        ]),
        _group('Addon de Stremio', 5, [
          _switch(
            title: 'Permitir contenido adulto',
            icon: Icons.explicit_rounded,
            value: s.stremioAllowAdult,
            apply: (v) => s.copyWith(stremioAllowAdult: v),
            call: (u, v) => u.editSettings(stremioAllowAdult: v),
          ),
          _switch(
            title: 'Permitir ZIP',
            icon: Icons.folder_zip_rounded,
            value: s.stremioAllowZipped,
            apply: (v) => s.copyWith(stremioAllowZipped: v),
            call: (u, v) => u.editSettings(stremioAllowZipped: v),
          ),
          _switch(
            title: 'Emojis en descripciones',
            icon: Icons.emoji_emotions_rounded,
            value: s.stremioEmojiInDescription,
            apply: (v) => s.copyWith(stremioEmojiInDescription: v),
            call: (u, v) => u.editSettings(stremioEmojiInDescription: v),
          ),
          _switch(
            title: 'Solo streams de "Tu contenido"',
            icon: Icons.video_library_rounded,
            value: s.stremioOnlyYourMediaStreams,
            apply: (v) => s.copyWith(stremioOnlyYourMediaStreams: v),
            call: (u, v) => u.editSettings(stremioOnlyYourMediaStreams: v),
          ),
          _switch(
            title: 'Esperar descargas de torrents',
            icon: Icons.hourglass_bottom_rounded,
            value: s.stremioWaitForDownloadTorrent,
            apply: (v) => s.copyWith(stremioWaitForDownloadTorrent: v),
            call: (u, v) => u.editSettings(stremioWaitForDownloadTorrent: v),
          ),
          _switch(
            title: 'Esperar descargas Usenet',
            icon: Icons.hourglass_bottom_rounded,
            value: s.stremioWaitForDownloadUsenet,
            apply: (v) => s.copyWith(stremioWaitForDownloadUsenet: v),
            call: (u, v) => u.editSettings(stremioWaitForDownloadUsenet: v),
          ),
        ]),
        _group('Interfaz', 6, [
          _switch(
            title: 'Velocidad en el título de la pestaña',
            icon: Icons.tab_rounded,
            value: s.downloadSpeedInTab,
            apply: (v) => s.copyWith(downloadSpeedInTab: v),
            call: (u, v) => u.editSettings(downloadSpeedInTab: v),
          ),
          _switch(
            title: 'Mostrar tracker en torrents',
            icon: Icons.track_changes_rounded,
            value: s.showTrackerInTorrents,
            apply: (v) => s.copyWith(showTrackerInTorrents: v),
            call: (u, v) => u.editSettings(showTrackerInTorrents: v),
          ),
        ]),
      ],
    );
  }
}
