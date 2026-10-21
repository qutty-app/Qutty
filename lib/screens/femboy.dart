// The transport and jump-to dialogs below are still being wired into this
// screen, so the analyzer has not seen a caller for them yet.
// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/api/web_socket_service.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/services/notification_service.dart';
import 'package:qutty/widgets/logo/logo.dart';
import 'package:qutty/widgets/settings_ui.dart';

class FemboyLegs extends StatelessWidget {
  const FemboyLegs({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = AppManager.instance;
    return Scaffold(
      appBar: AppBar(title: Text("Femboys:3")),
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, _) {
          final scheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Logo(variant: LogoVariant.textWithBgAlt, height: 128),
              Card(
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: scheme.error, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Warning an easter egg>:3",
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
              Center(
                child: Text(
                  ":3",
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
              Image.asset("assets/uwu/griboed.jpg"),
              Center(
                child: Text(
                  "QuttyTeam - Griboed",
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
              // SettingsSection(
              //   title: l10n.settingsConnectivity,
              //   children: [
              //     _ConnectionTile(status: manager.connectionStatus),
              //     SettingsTile(
              //       leading: const Icon(Icons.cloud_outlined),
              //       title: l10n.debugApiEndpoint,
              //       subtitle: manager.api.baseUrl,
              //       onTap: () => _showApiUrlDialog(context),
              //     ),
              //   ],
              // ),
              // SettingsSection(
              //   title: l10n.settingsNotifications,
              //   children: const [_TransportTile()],
              // ),
              // SettingsSection(
              //   title: l10n.developerOptions,
              //   children: [
              //     SettingsTile(
              //       leading: const Icon(Icons.code_outlined),
              //       title: l10n.debugDeveloperInfo,
              //       subtitle: l10n.debugDeveloperInfoSubtitle,
              //       trailing: Switch(
              //         value: manager.developerInfo,
              //         onChanged: manager.setDeveloperInfo,
              //       ),
              //       onTap: () =>
              //           manager.setDeveloperInfo(!manager.developerInfo),
              //     ),
              //     SettingsTile(
              //       leading: const Icon(Icons.groups_outlined),
              //       title: l10n.debugForceGroupCall,
              //       subtitle: l10n.debugForceGroupCallSubtitle,
              //       trailing: Switch(
              //         value: manager.forceGroupCall,
              //         onChanged: manager.setForceGroupCall,
              //       ),
              //       onTap: () => manager.setForceGroupCall(
              //         !manager.forceGroupCall,
              //       ),
              //     ),
              //     SettingsTile(
              //       leading: const Icon(Icons.navigation_outlined),
              //       title: l10n.debugJumpTo,
              //       subtitle: l10n.debugJumpToSubtitle,
              //       onTap: () => _showJumpToDialog(context),
              //     ),
              //     SettingsTile(
              //       leading: const Icon(Icons.done_all_outlined),
              //       title: l10n.settingsReadCount,
              //       subtitle: l10n.settingsReadCountSubtitle,
              //       trailing: Switch(
              //         value: manager.forceReadCount,
              //         onChanged: manager.setForceReadCount,
              //       ),
              //       onTap: () =>
              //           manager.setForceReadCount(!manager.forceReadCount),
              //     ),
              //     SettingsTile(
              //       leading: const Icon(Icons.screen_share_outlined),
              //       title: l10n.debugFallbackSelectorCast,
              //       subtitle: l10n.debugFallbackSelectorCastSubtitle,
              //       trailing: Switch(
              //         value: manager.fallbackSelectorCast,
              //         onChanged: manager.setFallbackSelectorCast,
              //       ),
              //       onTap: () => manager.setFallbackSelectorCast(
              //         !manager.fallbackSelectorCast,
              //       ),
              //     ),
              //   ],
              // ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showJumpToDialog(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: '/');
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.debugJumpToTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.debugPageUrlOrRoute,
            hintText: '/settings/dev',
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(context, controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.commonOpen),
          ),
        ],
      ),
    );
    if (value == null || value.isEmpty) return;

    String target = value.trim();
    if (target.startsWith('http://') || target.startsWith('https://')) {
      final uri = Uri.tryParse(target);
      if (uri != null) {
        final path = uri.path.isEmpty ? '/' : uri.path;
        final query = uri.query.isEmpty ? '' : '?${uri.query}';
        final fragment = uri.fragment.isEmpty ? '' : '#${uri.fragment}';
        target = '$path$query$fragment';
      }
    }
    if (!target.startsWith('/')) {
      target = '/$target';
    }

    if (!context.mounted) return;
    context.push(target);
  }

  Future<void> _showApiUrlDialog(BuildContext context) async {
    final l10n = context.l10n;
    final controller = TextEditingController(
      text: AppManager.instance.api.baseUrl,
    );
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.debugApiEndpoint),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.debugBaseUrl,
            hintText: 'https://api.qutty.app',
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (value != null && value.isNotEmpty) {
      await AppManager.instance.setApiUrl(value);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.debugApiEndpointUpdated)));
    }
  }
}

/// Shows how this build receives messages.
///
/// Only builds that can choose show a picker. Where there is nothing to choose --
/// iOS has APNs alone and desktop only ever has its socket -- the same field
/// displays the transport in use instead, so the row never reads as an empty
/// control.
class _TransportTile extends StatelessWidget {
  const _TransportTile();

  @override
  Widget build(BuildContext context) {
    final service = NotificationService.instance;
    final available = service.availableTransports;
    final reported = service.reportedTransport;
    final l10n = context.l10n;

    if (available.length > 1) {
      final selected = service.selectedTransport ?? reported;
      return SettingsTile(
        leading: const Icon(Icons.swap_horiz_outlined),
        title: l10n.debugTransport,
        subtitle: selected?.label ?? l10n.debugTransportNotSelected,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showTransportDialog(context, available, selected),
      );
    }

    return SettingsTile(
      leading: const Icon(Icons.notifications_outlined),
      title: l10n.debugTransport,
      subtitle: reported?.description ?? l10n.debugTransportUnavailable,
      trailing: Text(reported?.label ?? '-'),
      // Nothing to pick, so this is a status line rather than a control. Making
      // it tappable would promise a choice that does not exist.
      onTap: null,
    );
  }

  Future<void> _showTransportDialog(
    BuildContext context,
    List<PushTransport> available,
    PushTransport? selected,
  ) async {
    final service = NotificationService.instance;
    final chosen = await showDialog<PushTransport>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.debugTransport),
        children: [
          RadioGroup<PushTransport>(
            groupValue: selected,
            onChanged: (value) {
              if (value != null) Navigator.pop(context, value);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final transport in available)
                  RadioListTile<PushTransport>(
                    value: transport,
                    title: Text(transport.label),
                    subtitle: Text(transport.description),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (chosen == null) return;
    await service.selectTransport(chosen);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.debugTransportNowUsing(chosen.label)),
      ),
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
      subtitle: Text(l10n.connectionLiveWebsocket),
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

// Bring in formatRelativeDateTime from settings_ui via export.
String formatRelativeDateTimeImportAlias(DateTime? value) =>
    formatRelativeDateTime(value);
