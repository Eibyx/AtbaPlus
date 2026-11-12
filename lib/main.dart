import 'dart:io';

import 'package:atba/models/library_items/library_item.dart';
import 'package:atba/services/update_service.dart';
import 'package:atba/services/web_js_interop_service/web_js_interop_service.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import 'package:provider/provider.dart';

import 'services/shared_prefs_service.dart';
import 'services/secure_storage_service.dart';
import 'services/torbox_service.dart';
import 'services/stremio_service.dart';

import 'screens/setup/api_screen.dart';
import 'screens/home_page.dart';

import 'package:flutter_settings_screens/flutter_settings_screens.dart';

import 'app_state.dart';
import 'theme/themed_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  if (kIsWeb) sendPostMessage();

  await initSettings();

  final sharedPrefsService = SharedPrefsService();
  await sharedPrefsService.init();

  final secureStorageService = SecureStorageService();

  final isFirstRun = sharedPrefsService.getString('isFirstRun') == null;

  final apiService = TorboxAPI(secureStorageService: secureStorageService);
  await apiService.init();

  final hasApiKey = apiService.hasApiKey;

  LibraryItem.initApiService(apiService);
  final stremioService = StremioRequests();

  if (!kIsWeb) {
    FileDownloader().configureNotification(
      tapOpensFile: true,
      progressBar: true,
      running: TaskNotification('Descargando', '{progress} {filename}'),
      complete: TaskNotification('Descarga terminada', '{filename}'),
      error: TaskNotification("Error", "{filename}"),
      paused: TaskNotification("En pausa", "{filename}"),
      canceled: TaskNotification("Cancelada", "{filename}"),
    );
  }
  FileDownloader().configure(
    globalConfig: (Config.useExternalStorage, "always"),
  );

  // Store exceptions mapped by taskId
  final Map<String, TaskException?> errorDetails = {};

  //  to listen for task status updates
  void taskStatusCallback(TaskStatusUpdate update) {
    if (update.status == TaskStatus.failed) {
      errorDetails[update.task.taskId] = update.exception;
    }
  }

  Future<void> notificationTapCallback(
    Task task,
    NotificationType notificationType,
  ) async {
    if (notificationType == NotificationType.error) {
      final exception = errorDetails[task.taskId];
      if (exception != null) {
        print('Error for task ${task.taskId}: ${exception.description}');
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/downloadError.txt');
        file.writeAsString(exception.description);
        OpenFile.open(file.path);
      }
    }
  }

  FileDownloader().registerCallbacks(
    taskStatusCallback: taskStatusCallback,
    taskNotificationTapCallback: notificationTapCallback,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPrefsService>.value(value: sharedPrefsService),
        Provider<SecureStorageService>.value(value: secureStorageService),
        Provider<TorboxAPI>.value(value: apiService),
        ProxyProvider<TorboxAPI, UpdateService>(
          update: (_, torboxApi, _) => UpdateService(torboxApi),
        ),
        ChangeNotifierProvider<StremioRequests>.value(value: stremioService),
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState(
            sharedPrefsService: sharedPrefsService,
            secureStorageService: secureStorageService,
            apiService: apiService,
          )..initializeApp(),
        ),
      ],
      child: AtbaApp(isFirstRun: isFirstRun, hasApiKey: hasApiKey),
    ),
  );
}

Future<void> initSettings() async {
  await Settings.init(cacheProvider: SharePreferenceCache());
}

class AtbaApp extends StatelessWidget {
  final bool isFirstRun;
  final bool hasApiKey;
  const AtbaApp({required this.isFirstRun, required this.hasApiKey, super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.isLoading) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
          );
        }
        if (appState.hasError) {
          return const MaterialApp(home: ErrorScreen());
        }

        return ThemedApp(
          home: isFirstRun
              ? (hasApiKey ? const HomeScreen() : ApiKeyScreen())
              : const HomeScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Ocurrió un error. Reinicia la app.')),
    );
  }
}
