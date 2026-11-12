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
      title: 'Usenet provider',
      actions: [
        IconButton(
          tooltip: _reveal ? 'Hide passwords' : 'Show passwords',
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
          child: SectionHeader(title: 'Connection details'),
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
                    InfoRow(label: 'SSL', value: c.ssl ? 'Yes' : 'No'),
                    InfoRow(
                      label: 'Username',
                      value: c.username,
                      copyable: true,
                    ),
                    InfoRow(
                      label: 'Password',
                      value: c.password,
                      copyable: true,
                      obscure: !_reveal,
                    ),
                    InfoRow(label: 'Connections', value: '${c.connections}'),
                    InfoRow(label: 'Retention', value: '${c.retention} days'),
                    if (c.limitations.isNotEmpty)
                      InfoRow(label: 'Limitations', value: c.limitations),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SectionHeader(title: 'Your account')),
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
                    InfoRow(label: 'SSL', value: a.ssl ? 'Yes' : 'No'),
                    InfoRow(
                      label: 'Username',
                      value: a.username,
                      copyable: true,
                    ),
                    InfoRow(
                      label: 'Password',
                      value: a.password,
                      copyable: true,
                      obscure: !_reveal,
                    ),
                    InfoRow(label: 'Connections', value: '${a.connections}'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.lock_reset_rounded),
                        label: const Text('Reset password'),
                        onPressed: () async {
                          final ok = await confirmAction(
                            context,
                            title: 'Reset Usenet password?',
                            message: 'Clients using the current password will stop working until you update them.',
                            confirmLabel: 'Reset',
                          );
                          if (!ok || !context.mounted) return;
                          final r = await runApiAction(
                            context,
                            (api) => api.usenet.resetProviderPassword(),
                            successMessage: 'Password reset',
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
