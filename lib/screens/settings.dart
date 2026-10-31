import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' show MediaDevice;

import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/api/web_socket_service.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/screens/account_dialogs.dart';
import 'package:qutty/services/notification_service.dart';
import 'package:qutty/widgets/avatar.dart';
import 'package:qutty/widgets/settings_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = AppManager.instance;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, _) {
          final profile = manager.profile;
          final scheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (profile != null) _ProfileHeader(profile: profile),
              SettingsSection(
                title: l10n.settingsCustomization,
                children: [
                  SettingsTile(
                    leading: const Icon(Icons.tune_outlined),
                    title: l10n.settingsCustomization,
                    subtitle: l10n.settingsCustomizationSubtitle,
                    onTap: () => context.push('/settings/customization'),
                  ),
                  SettingsTile(
                    leading: const Icon(Icons.translate_outlined),
                    title: l10n.languageTitle,
                    // A null locale means the device decides, so say that
                    // rather than naming a language the user never picked.
                    subtitle: manager.locale == null
                        ? l10n.languageSystemDefault
                        : languageName(manager.locale!),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/language'),
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.settingsConnectivity,
                children: [_ConnectionTile(status: manager.connectionStatus)],
              ),
              SettingsSection(
                title: l10n.cacheOfflineSection,
                children: [
                  SettingsTile(
                    leading: const Icon(Icons.offline_bolt_outlined),
                    title: l10n.cacheTitle,
                    subtitle: l10n.cacheTitleSubtitle,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/cache'),
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.settingsNotifications,
                children: const [_NotificationsTile()],
              ),
              SettingsSection(
                title: l10n.settingsAudio,
                children: [
                  _AudioDeviceTile(
                    leading: Icons.mic_none_outlined,
                    title: l10n.settingsAudioInput,
                    kind: _AudioDeviceKind.input,
                  ),
                  _AudioDeviceTile(
                    leading: Icons.volume_up_outlined,
                    title: l10n.settingsAudioOutput,
                    kind: _AudioDeviceKind.output,
                  ),
                  _AudioDeviceTile(
                    leading: Icons.videocam_outlined,
                    title: l10n.settingsAudioCamera,
                    kind: _AudioDeviceKind.camera,
                  ),
                  SettingsTile(
                    leading: const Icon(Icons.noise_control_off_outlined),
                    title: l10n.settingsAudioNoiseReduction,
                    subtitle: l10n.settingsAudioNoiseReductionSubtitle,
                    trailing: Switch(
                      value: manager.noiseReduction,
                      onChanged: manager.setNoiseReduction,
                    ),
                    onTap: () =>
                        manager.setNoiseReduction(!manager.noiseReduction),
                  ),
                  _VolumeTile(
                    leading: Icons.mic_none_outlined,
                    title: l10n.settingsAudioMicVolume,
                    value: manager.microphoneVolume,
                    onChanged: manager.setMicrophoneVolume,
                  ),
                  _VolumeTile(
                    leading: Icons.volume_up_outlined,
                    title: l10n.settingsAudioSpeakerVolume,
                    value: manager.speakerVolume,
                    onChanged: manager.setSpeakerVolume,
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.settingsAccount,
                children: [
                  SettingsTile(
                    leading: const Icon(Icons.person_outline),
                    title: l10n.settingsEditProfile,
                    onTap: () => context.push('/settings/profile'),
                  ),
                  SettingsTile(
                    leading: const Icon(Icons.lock_outline),
                    title: l10n.settingsChangePassword,
                    subtitle: l10n.settingsChangePasswordSubtitle,
                    onTap: () =>
                        _showAccountDialog(context, kind: _DialogKind.password),
                  ),
                  SettingsTile(
                    leading: const Icon(Icons.alternate_email),
                    title: l10n.settingsChangeEmail,
                    subtitle: profile?.email ?? l10n.settingsNoEmailOnFile,
                    onTap: () =>
                        _showAccountDialog(context, kind: _DialogKind.email),
                  ),
                  SettingsTile(
                    leading: const Icon(Icons.devices_outlined),
                    title: l10n.settingsActiveSessions,
                    subtitle: l10n.settingsActiveSessionsSubtitle,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SessionsScreen()),
                    ),
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.settingsAccounts,
                children: [
                  for (final account in manager.accounts)
                    SettingsTile(
                      leading: Icon(
                        account.id == manager.activeAccountId
                            ? Icons.check_circle_outline
                            : Icons.account_circle_outlined,
                      ),
                      title: account.label,
                      subtitle: account.baseUrl == "https://api.qutty.app" ? "" : account.baseUrl,
                      trailing: account.id == manager.activeAccountId
                          ? const Icon(Icons.check, size: 20)
                          : IconButton(
                              tooltip: l10n.settingsRemoveAccount,
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () =>
                                  manager.removeAccount(account.id),
                            ),
                      onTap: account.id == manager.activeAccountId
                          ? null
                          : () => manager.switchAccount(account.id),
                    ),
                  SettingsTile(
                    leading: const Icon(Icons.person_add_alt_outlined),
                    title: l10n.settingsAddAccount,
                    subtitle: l10n.settingsAddAccountSubtitle,
                    onTap: () async {
                      await manager.prepareAddAccount();
                      if (context.mounted) context.go('/auth');
                    },
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.settingsAccountSafety,
                children: [
                  SettingsTile(
                    leading: const Icon(Icons.delete_forever_outlined),
                    title: l10n.settingsDeleteAccount,
                    subtitle: l10n.settingsDeleteAccountSubtitle,
                    destructive: true,
                    onTap: () => _confirmDeleteAccount(context),
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.developerPortal,
                subtitle: l10n.developerPortalSubtitle,
                children: [
                  SettingsTile(
                    leading: const Icon(Icons.smart_toy_outlined),
                    title: l10n.botsTitle,
                    subtitle: l10n.botsSubtitle,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/developer/bots'),
                  ),
                  SettingsTile(
                    leading: const Icon(Icons.emoji_emotions_outlined),
                    title: l10n.ugcTitle,
                    subtitle: l10n.ugcSubtitle,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/developer/ugc'),
                  ),
                ],
              ),
              SettingsSection(
                title: l10n.settingsAbout,
                children: [
                  SettingsTile(
                    leading: const Icon(Icons.info_outline),
                    title: l10n.appName,
                    subtitle: l10n.settingsVersionPlaceholder,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/about'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(color: scheme.error),
                  ),
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.settingsLogOut),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAccountDialog(
    BuildContext context, {
    required _DialogKind kind,
  }) async {
    final api = AppManager.instance.api;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => switch (kind) {
        _DialogKind.password => PasswordDialog(api: api),
        _DialogKind.email => EmailDialog(
          api: api,
          currentEmail: AppManager.instance.profile?.email,
        ),
      },
    );
    if (result == true && context.mounted) {
      final message = switch (kind) {
        _DialogKind.password => context.l10n.settingsPasswordUpdated,
        _DialogKind.email => context.l10n.settingsEmailUpdated,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsLogOutTitle),
        content: Text(l10n.settingsLogOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsLogOut),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await AppManager.instance.logout();
      if (context.mounted) context.go('/auth');
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final username = AppManager.instance.profile?.handles.isNotEmpty == true
        ? AppManager.instance.profile!.handles.first
        : '';
    final usernameController = TextEditingController(text: username);
    final passwordController = TextEditingController();
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsDeleteAccountTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.settingsDeleteAccountBody),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: l10n.username),
              autocorrect: false,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.password),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await AppManager.instance.api.deleteAccount(
        usernameController.text.trim(),
        passwordController.text,
      );
      await AppManager.instance.logout();
      if (context.mounted) context.go('/auth');
    } on ApiException catch (exception) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    }
  }
}

enum _DialogKind { password, email }

enum _AudioDeviceKind { input, output, camera }

/// A sentinel entry the device picker returns to fall back to the platform's
/// own default device. An empty device id means "system default".
const _systemDefaultDevice = MediaDevice('', '', '', null);

/// Settings row that opens a picker for one class of media device.
class _AudioDeviceTile extends StatelessWidget {
  const _AudioDeviceTile({
    required this.leading,
    required this.title,
    required this.kind,
  });

  final IconData leading;
  final String title;
  final _AudioDeviceKind kind;

  String _selectedLabel(AppManager manager, AppLocalizations l10n) {
    final label = switch (kind) {
      _AudioDeviceKind.input => manager.audioInputDeviceLabel,
      _AudioDeviceKind.output => manager.audioOutputDeviceLabel,
      _AudioDeviceKind.camera => manager.videoInputDeviceLabel,
    };
    return (label == null || label.isEmpty)
        ? l10n.settingsAudioSystemDefault
        : label;
  }

  String? _selectedId(AppManager manager) => switch (kind) {
    _AudioDeviceKind.input => manager.audioInputDeviceId,
    _AudioDeviceKind.output => manager.audioOutputDeviceId,
    _AudioDeviceKind.camera => manager.videoInputDeviceId,
  };

  Future<List<MediaDevice>> _devices(AppManager manager) => switch (kind) {
    _AudioDeviceKind.input => manager.audioInputDevices(),
    _AudioDeviceKind.output => manager.audioOutputDevices(),
    _AudioDeviceKind.camera => manager.videoInputDevices(),
  };

  Future<void> _select(MediaDevice device) => switch (kind) {
    _AudioDeviceKind.input => AppManager.instance.setAudioInputDevice(device),
    _AudioDeviceKind.output => AppManager.instance.setAudioOutputDevice(device),
    _AudioDeviceKind.camera => AppManager.instance.setVideoInputDevice(device),
  };

  Future<void> _pick(BuildContext context) async {
    final manager = AppManager.instance;
    final l10n = context.l10n;
    List<MediaDevice> devices;
    try {
      devices = await _devices(manager);
    } catch (_) {
      devices = const [];
    }
    if (!context.mounted) return;
    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsAudioNoDevices)),
      );
      return;
    }
    final currentId = _selectedId(manager);
    final selected = await showDialog<MediaDevice>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          for (final device in <MediaDevice>[_systemDefaultDevice, ...devices])
            ListTile(
              title: Text(
                device.deviceId.isEmpty
                    ? l10n.settingsAudioSystemDefault
                    : device.label.isEmpty
                    ? device.deviceId
                    : device.label,
              ),
              trailing: (currentId ?? '') == device.deviceId
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () => Navigator.pop(context, device),
            ),
        ],
      ),
    );
    if (selected == null) return;
    await _select(selected);
  }

  @override
  Widget build(BuildContext context) {
    final manager = AppManager.instance;
    return SettingsTile(
      leading: Icon(leading),
      title: title,
      subtitle: _selectedLabel(manager, context.l10n),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _pick(context),
    );
  }
}

/// A labelled slider used for input and output volume.
class _VolumeTile extends StatelessWidget {
  const _VolumeTile({
    required this.leading,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData leading;
  final String title;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(leading, color: scheme.onSurfaceVariant),
              const SizedBox(width: 16),
              Expanded(child: Text(title)),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          Slider(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Profile profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Avatar(
                baseUrl: AppManager.instance.api.baseUrl,
                imageUrl: profile.avatarUrl,
                displayName: profile.displayName,
                radius: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (profile.handles.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${profile.handles.first}',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    if (profile.bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.settingsEditProfileTooltip,
                onPressed: () => context.push('/settings/profile'),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsTile extends StatelessWidget {
  const _NotificationsTile();

  @override
  Widget build(BuildContext context) {
    final manager = AppManager.instance;
    final service = NotificationService.instance;
    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        final l10n = context.l10n;
        return SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: Text(l10n.notificationsToggle),
          // Local notifications and background push share one switch: splitting
          // them would let a user mute alerts but still be woken by FCM.
          subtitle: Text(
            !manager.notificationsEnabled
                ? l10n.notificationsOffForDevice
                // A build with no transport can still alert while it is open,
                // because the socket delivers the message directly. Saying so is
                // more useful than implying background delivery that cannot
                // happen.
                : manager.pushTransport == PushTransport.websocket
                ? l10n.notificationsOpenBackgroundConnection
                : manager.pushTransport == null
                ? l10n.notificationsOpenOnly
                : l10n.notificationsOpenWithBackground,
          ),
          value: manager.notificationsEnabled,
          // Permission is requested here rather than at startup so the prompt
          // follows an explicit action. Asking after enabling would leave the
          // switch on while the OS silently blocks everything.
          onChanged: (value) async {
            if (value) {
              final granted = await service.requestPermission();
              if (!granted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.notificationsPermissionHint)),
                  );
                }
                return;
              }
            }
            await manager.setNotificationsEnabled(value);
          },
        );
      },
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  final ConnectionStatus status;
  const _ConnectionTile({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, color, icon) = _describe(status, l10n);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      subtitle: Text(l10n.connectionStatus),
      trailing: TextButton(
        onPressed: AppManager.instance.connectWebSocket,
        child: Text(l10n.connectionReconnect),
      ),
    );
  }

  (String, Color, IconData) _describe(
    ConnectionStatus status,
    AppLocalizations l10n,
  ) {
    switch (status) {
      case ConnectionStatus.connected:
        return (
          l10n.connectionConnected,
          Colors.green,
          Icons.check_circle_outline,
        );
      case ConnectionStatus.connecting:
        return (l10n.connectionConnecting, Colors.orange, Icons.sync);
      case ConnectionStatus.error:
        return (l10n.connectionDisconnected, Colors.red, Icons.error_outline);
      case ConnectionStatus.disconnected:
        return (
          l10n.connectionDisconnected,
          Colors.grey,
          Icons.cloud_off_outlined,
        );
    }
  }
}

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  Future<List<SessionInfo>>? _future;

  @override
  void initState() {
    super.initState();
    _future = AppManager.instance.api.sessions();
  }

  Future<void> _refresh() async {
    setState(() => _future = AppManager.instance.api.sessions());
    await _future;
  }

  Future<void> _revoke(SessionInfo session) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sessionsRevokeTitle(session.name)),
        content: Text(l10n.sessionsRevokeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonRevoke),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AppManager.instance.api.deleteSession(session.id);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.sessionsRevoked)));
      }
    } on ApiException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsActiveSessions)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<SessionInfo>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingCenter();
            }
            if (snapshot.hasError) {
              return StatusPlaceholder(
                icon: Icons.error_outline,
                title: l10n.sessionsLoadFailed,
                message: snapshot.error.toString(),
                action: FilledButton(
                  onPressed: _refresh,
                  child: Text(l10n.commonTryAgain),
                ),
              );
            }
            final sessions = snapshot.data ?? const <SessionInfo>[];
            if (sessions.isEmpty) {
              return StatusPlaceholder(
                icon: Icons.devices_other_outlined,
                title: l10n.sessionsNone,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final session = sessions[index];
                final isCurrent = session.isCurrent;
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      isCurrent
                          ? Icons.phone_android_outlined
                          : Icons.computer_outlined,
                    ),
                  ),
                  title: Text(session.name),
                  subtitle: Text(
                    [
                      if (isCurrent) l10n.sessionsThisDevice,
                      if (session.lastIp.isNotEmpty) session.lastIp,
                      l10n.sessionsLastActive(
                        formatRelativeDateTime(session.lastOnline, l10n: l10n),
                      ),
                    ].join(' • '),
                  ),
                  trailing: isCurrent
                      ? StatusBadge(
                          label: l10n.sessionsCurrentBadge,
                          color: Colors.green,
                          icon: Icons.bolt,
                        )
                      : IconButton(
                          tooltip: l10n.commonRevoke,
                          icon: const Icon(Icons.logout),
                          onPressed: () => _revoke(session),
                        ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Bring in formatRelativeDateTime from settings_ui via export.
String formatRelativeDateTimeImportAlias(DateTime? value) =>
    formatRelativeDateTime(value);
