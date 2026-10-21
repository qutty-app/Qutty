import 'package:flutter/material.dart';

import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';

/// Shows the desktop screen/window picker and returns the chosen source, or
/// null if the user backs out.
///
/// [loadSources] defaults to the platform's desktop capturer; tests inject a
/// stub so the dialog can be exercised without a platform channel.
Future<ScreenShareSource?> showScreenShareSourcePicker(
  BuildContext context, {
  Future<List<ScreenShareSource>> Function()? loadSources,
}) {
  return showDialog<ScreenShareSource>(
    context: context,
    builder: (context) => _ScreenSharePickerDialog(
      loadSources: loadSources ?? AppManager.instance.listScreenShareSources,
    ),
  );
}

class _ScreenSharePickerDialog extends StatefulWidget {
  const _ScreenSharePickerDialog({required this.loadSources});

  final Future<List<ScreenShareSource>> Function() loadSources;

  @override
  State<_ScreenSharePickerDialog> createState() =>
      _ScreenSharePickerDialogState();
}

class _ScreenSharePickerDialogState extends State<_ScreenSharePickerDialog> {
  late Future<List<ScreenShareSource>> _sources;

  @override
  void initState() {
    super.initState();
    _sources = widget.loadSources();
  }

  void _reload() {
    setState(() => _sources = widget.loadSources());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.screenSharePickTitle),
      content: SizedBox(
        width: 420,
        height: 420,
        child: FutureBuilder<List<ScreenShareSource>>(
          future: _sources,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _PickerMessage(
                icon: Icons.error_outline,
                message: l10n.screenSharePickError,
                action: TextButton(
                  onPressed: _reload,
                  child: Text(l10n.screenSharePickRetry),
                ),
              );
            }
            final sources = snapshot.data ?? const <ScreenShareSource>[];
            if (sources.isEmpty) {
              return _PickerMessage(
                icon: Icons.desktop_access_disabled_outlined,
                message: l10n.screenSharePickEmpty,
                action: TextButton(
                  onPressed: _reload,
                  child: Text(l10n.screenSharePickRetry),
                ),
              );
            }
            return _SourceList(sources: sources);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}

class _SourceList extends StatelessWidget {
  const _SourceList({required this.sources});

  final List<ScreenShareSource> sources;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screens = sources.where((s) => s.isScreen).toList();
    final windows = sources.where((s) => !s.isScreen).toList();
    return ListView(
      children: [
        if (screens.isNotEmpty) ...[
          _GroupHeader(label: l10n.screenSharePickScreens),
          for (final source in screens) _SourceTile(source: source),
        ],
        if (windows.isNotEmpty) ...[
          _GroupHeader(label: l10n.screenSharePickWindows),
          for (final source in windows) _SourceTile(source: source),
        ],
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.source});

  final ScreenShareSource source;

  @override
  Widget build(BuildContext context) {
    final thumbnail = source.thumbnail;
    if (thumbnail == null) {
      return ListTile(
        leading: Icon(source.isScreen ? Icons.monitor : Icons.window_outlined),
        title: Text(source.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        onTap: () => Navigator.of(context).pop(source),
      );
    }
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.memory(
          thumbnail,
          width: 64,
          height: 36,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          // Some platforms hand back a format Flutter can't decode; fall back
          // to the plain source icon rather than showing a broken image.
          errorBuilder: (context, _, _) => _SourceIcon(source: source),
        ),
      ),
      title: Text(source.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => Navigator.of(context).pop(source),
    );
  }
}

class _SourceIcon extends StatelessWidget {
  const _SourceIcon({required this.source});

  final ScreenShareSource source;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    height: 36,
    child: Icon(source.isScreen ? Icons.monitor : Icons.window_outlined),
  );
}

class _PickerMessage extends StatelessWidget {
  const _PickerMessage({
    required this.icon,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        action,
      ],
    ),
  );
}
