import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../shared/widgets/glass/glass_text_field.dart';
import '../../domain/models/network_server_config.dart';
import '../providers/network_servers_providers.dart';

/// Modal dialog for configuring remote network storage endpoints (WebDAV, Nextcloud, NAS).
class ServerConfigDialog extends ConsumerStatefulWidget {
  const ServerConfigDialog({super.key, this.initialConfig});

  final NetworkServerConfig? initialConfig;

  static Future<void> show(BuildContext context, {NetworkServerConfig? initialConfig}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (ctx) => ServerConfigDialog(initialConfig: initialConfig),
    );
  }

  @override
  ConsumerState<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends ConsumerState<ServerConfigDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _pathController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  late NetworkServerType _serverType;
  late bool _useSsl;
  bool _isTesting = false;
  bool? _testResult;

  @override
  void initState() {
    super.initState();
    final cfg = widget.initialConfig;
    _nameController = TextEditingController(text: cfg?.name ?? 'Synology DiskStation');
    _hostController = TextEditingController(text: cfg?.host ?? '192.168.1.100');
    _portController = TextEditingController(text: (cfg?.port ?? 5006).toString());
    _pathController = TextEditingController(text: cfg?.path ?? '/music');
    _usernameController = TextEditingController(text: cfg?.username ?? '');
    _passwordController = TextEditingController(text: cfg?.password ?? '');

    _serverType = cfg?.type ?? NetworkServerType.webdav;
    _useSsl = cfg?.useSsl ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _pathController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  NetworkServerConfig _buildConfig() {
    return NetworkServerConfig(
      id: widget.initialConfig?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _serverType,
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? (_useSsl ? 443 : 80),
      path: _pathController.text.trim().isEmpty ? '/' : _pathController.text.trim(),
      username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
      password: _passwordController.text.trim().isEmpty ? null : _passwordController.text.trim(),
      useSsl: _useSsl,
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final cfg = _buildConfig();
    final client = ref.read(networkStorageClientProvider);
    final success = await client.testConnection(cfg);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = success;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final config = _buildConfig();
    final repo = ref.read(networkServersRepositoryProvider);
    await repo.saveServer(config);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: const Color(0xFF0F141C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withOpacity(0.15),
                    ),
                    child: Icon(Icons.dns_rounded, color: colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    widget.initialConfig != null ? 'Edit Server Profile' : 'Add Network Storage',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Server Type Segmented Selector
              SegmentedButton<NetworkServerType>(
                segments: const [
                  ButtonSegment(
                    value: NetworkServerType.webdav,
                    label: Text('WebDAV'),
                    icon: Icon(Icons.folder_shared_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: NetworkServerType.nextcloud,
                    label: Text('Nextcloud'),
                    icon: Icon(Icons.cloud_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: NetworkServerType.customHttp,
                    label: Text('HTTP/Stream'),
                    icon: Icon(Icons.stream_rounded, size: 16),
                  ),
                ],
                selected: {_serverType},
                onSelectionChanged: (set) {
                  setState(() {
                    _serverType = set.first;
                    if (_serverType == NetworkServerType.webdav) {
                      _portController.text = _useSsl ? '5006' : '5005';
                      _pathController.text = '/music';
                    } else if (_serverType == NetworkServerType.nextcloud) {
                      _portController.text = '443';
                      _pathController.text = '/remote.php/dav/files/username/Music';
                    }
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Server Friendly Name
              GlassTextField(
                key: const ValueKey('server_name_field'),
                controller: _nameController,
                hintText: 'Profile Name (e.g. Synology Vault)',
                labelText: 'Name',
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Host / IP Address
              GlassTextField(
                key: const ValueKey('server_host_field'),
                controller: _hostController,
                hintText: '192.168.1.100 or nas.local',
                labelText: 'Host / IP',
                prefixIcon: Icons.link_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Port and SSL Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GlassTextField(
                      key: const ValueKey('server_port_field'),
                      controller: _portController,
                      hintText: 'Port',
                      labelText: 'Port',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.numbers_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('HTTPS (SSL)', style: AppTypography.bodySmall.copyWith(color: Colors.white)),
                          Switch(
                            value: _useSsl,
                            activeColor: Colors.white,
                            activeTrackColor: colorScheme.primary,
                            onChanged: (val) {
                              setState(() {
                                _useSsl = val;
                                if (_serverType == NetworkServerType.webdav) {
                                  _portController.text = val ? '5006' : '5005';
                                } else {
                                  _portController.text = val ? '443' : '80';
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Root Path
              GlassTextField(
                key: const ValueKey('server_path_field'),
                controller: _pathController,
                hintText: '/music or /remote.php/webdav',
                labelText: 'Remote Directory Path',
                prefixIcon: Icons.folder_open_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Username & Password
              GlassTextField(
                key: const ValueKey('server_username_field'),
                controller: _usernameController,
                hintText: 'Username (optional)',
                labelText: 'Username',
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),

              GlassTextField(
                key: const ValueKey('server_password_field'),
                controller: _passwordController,
                hintText: 'Password (optional)',
                labelText: 'Password',
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: AppSpacing.md),

              // Test Connection Banner
              if (_testResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: _testResult!
                        ? const Color(0xFF00E676).withOpacity(0.15)
                        : Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
                    border: Border.all(
                      color: _testResult!
                          ? const Color(0xFF00E676).withOpacity(0.4)
                          : Colors.redAccent.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testResult! ? Icons.check_circle_rounded : Icons.error_rounded,
                        color: _testResult! ? const Color(0xFF00E676) : Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _testResult!
                              ? 'Connection verified! Server is reachable.'
                              : 'Could not connect. Verify host, port, and credentials.',
                          style: AppTypography.bodySmall.copyWith(
                            color: _testResult! ? const Color(0xFF00E676) : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('test_server_connection_button'),
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text('Test Ping', style: AppTypography.labelMedium),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('save_server_button'),
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Save', style: AppTypography.labelMedium),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
