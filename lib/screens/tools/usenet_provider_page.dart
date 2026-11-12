import 'package:atba/screens/tools/account_page.dart' show AsyncSection;
import 'package:atba/screens/tools/tool_kit.dart';
import 'package:atba/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:torbox_api/torbox_api.dart';

class UsenetProviderPage extends StatefulWidget {
  const UsenetProviderPage({super.key});

  @override
  State<UsenetProviderPage> createState() => _UsenetProviderPageState();
}

class _UsenetProviderPageState extends State<UsenetProviderPage> {
  int _version = 0;
  bool _reveal = false;

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Proveedor Usenet',
      actions: [
        IconButton(
          tooltip: _reveal ? 'Ocultar contraseñas' : 'Mostrar contraseñas',
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _reveal ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              key: ValueKey(_reveal),
            ),
          ),
          onPressed: () => setState(() => _reveal = !_reveal),
        ),
      ],
      slivers: [
        const SliverToBoxAdapter(
          child: SectionHeader(title: 'Datos de conexión'),
        ),
        SliverToBoxAdapter(
          child: AsyncSection<UsenetProviderConnectionData>(
            key: ValueKey('conn$_version'),
            load: (api) => api.usenet.getProviderConnection(),
            builder: (context, c) => EntranceAnimation(
              child: SurfaceCard(
                child: Column(
                  children: [
                    InfoRow(label: 'Host', value: c.host, copyable: true),
                    InfoRow(label: 'Port', value: '${c.port}', copyable: true),
                    InfoRow(label: 'SSL', value: c.ssl ? 'Sí' : 'No'),
                    InfoRow(
                      label: 'Usuario',
                      value: c.username,
                      copyable: true,
                    ),
                    InfoRow(
                      label: 'Contraseña',
                      value: c.password,
                      copyable: true,
                      obscure: !_reveal,
                    ),
                    InfoRow(label: 'Conexiones', value: '${c.connections}'),
                    InfoRow(label: 'Retención', value: '${c.retention} días'),
                    if (c.limitations.isNotEmpty)
                      InfoRow(label: 'Limitaciones', value: c.limitations),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader(title: 'Tu cuenta')),
        SliverToBoxAdapter(
          child: AsyncSection<UsenetProviderAccountData>(
            key: ValueKey('acc$_version'),
            load: (api) => api.usenet.getProviderAccount(),
            builder: (context, a) => EntranceAnimation(
              index: 1,
              child: SurfaceCard(
                child: Column(
                  children: [
                    InfoRow(label: 'Host', value: a.host, copyable: true),
                    InfoRow(label: 'Port', value: '${a.port}', copyable: true),
                    InfoRow(label: 'SSL', value: a.ssl ? 'Sí' : 'No'),
                    InfoRow(
                      label: 'Usuario',
                      value: a.username,
                      copyable: true,
                    ),
                    InfoRow(
                      label: 'Contraseña',
                      value: a.password,
                      copyable: true,
                      obscure: !_reveal,
                    ),
                    InfoRow(label: 'Conexiones', value: '${a.connections}'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.lock_reset_rounded),
                        label: const Text('Restablecer contraseña'),
                        onPressed: () async {
                          final ok = await confirmAction(
                            context,
                            title: '¿Restablecer la contraseña de Usenet?',
                            message: 'Los clientes que usen la contraseña actual dejarán de funcionar hasta que la actualices.',
                            confirmLabel: 'Restablecer',
                          );
                          if (!ok || !context.mounted) return;
                          final r = await runApiAction(
                            context,
                            (api) => api.usenet.resetProviderPassword(),
                            successMessage: 'Contraseña restablecida',
                          );
                          if (r != null) setState(() => _version++);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
