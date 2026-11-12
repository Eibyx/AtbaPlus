import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:atba/screens/home_page.dart';
import 'package:atba/models/permission_model.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final Map<String, bool> _grantedPermissions = {};
  final PermissionModel _permissionModel = PermissionModel();

  Future<PermissionStatus> requestPermission(Permission permission) async {
    return await permission.request();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> permissions = [
      {
        'icon': Icons.folder,
        'title': 'Acceso al almacenamiento',
        'description': 'Para guardar y abrir archivos descargados.',
        'permission': Permission.storage,
      },
      {
        'icon': Icons.notifications,
        'title': 'Notificaciones',
        'description': 'Para avisarte del estado de tus descargas.',
        'permission': Permission.notification,
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Permisos')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...permissions.map((perm) {
              bool isGranted = _grantedPermissions[perm['title']] ?? false;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      perm['icon'],
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            perm['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            perm['description'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    isGranted
                        ? const Icon(Icons.check, color: Colors.green)
                        : ElevatedButton(
                            onPressed: () async {
                              bool granted = await _permissionModel
                                  .grantPermission(perm['permission'], context);
                              if (granted) {
                                setState(() {
                                  _grantedPermissions[perm['title']] = true;
                                });
                              } else {
                                if (perm['permission'] == Permission.storage) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No elegiste carpeta. Puedes continuar sin dar acceso.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text('Permitir'),
                          ),
                  ],
                ),
              );
            }),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
