import 'package:flutter/material.dart';

import 'package:qutty/l10n/l10n.dart';

/// A reusable M3 settings section with title, optional subtitle and items.
class SettingsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Card(
            clipBehavior: Clip.antiAlias,
            color: theme.colorScheme.surfaceContainerLow,
            child: Column(children: _buildItems(theme)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItems(ThemeData theme) {
    final widgets = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      widgets.add(children[i]);
      if (i < children.length - 1) {
        widgets.add(
          Divider(
            height: 1,
            indent: 56,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        );
      }
    }
    return widgets;
  }
}

/// Settings tile that adapts to leading widgets and trailing controls.
class SettingsTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final bool destructive;

  const SettingsTile({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleColor = destructive ? scheme.error : null;
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: titleColor == null ? null : TextStyle(color: titleColor),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing:
          trailing ??
          (onTap == null
              ? null
              : Icon(Icons.chevron_right, color: scheme.onSurfaceVariant)),
      onTap: onTap,
      enabled: enabled,
    );
  }
}

/// Status pill used by connection/role indicators.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final background = color.withValues(alpha: 0.16);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sliver-friendly error/empty placeholder.
class StatusPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const StatusPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                style: TextStyle(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Reusable loading indicator.
class LoadingCenter extends StatelessWidget {
  const LoadingCenter({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// A human readable size, such as "1.5 MB".
///
/// The numbers are written the way a person would say them out loud, so a
/// cache of 1.5 megabytes reads as "1.5 MB" rather than as a byte count.
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text = unit == 0 || value >= 100
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  // Whole numbers are written whole: "64 MB" rather than "64.0 MB".
  final trimmed = text.endsWith('.0')
      ? text.substring(0, text.length - 2)
      : text;
  return '$trimmed ${units[unit]}';
}

/// Returns a friendly relative time description for a past timestamp.
///
/// [l10n] is required rather than read from a context because the callers are
/// stateful screens whose async callbacks run long after the build that created
/// them; an empty or null value falls back to the active locale instead.
String formatRelativeDateTime(
  DateTime? value, {
  DateTime? now,
  AppLocalizations? l10n,
}) {
  final strings = l10n ?? L10n.current;
  if (value == null) return '—';
  final ref = now ?? DateTime.now();
  final diff = ref.difference(value.toLocal());
  if (diff.inSeconds < 60) return strings.timeJustNow;
  if (diff.inMinutes < 60) return strings.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return strings.timeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return strings.timeDaysAgo(diff.inDays);
  return _date(value);
}

String _date(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}

IconData iconForChatType(String chatType) {
  switch (chatType) {
    case 'channel':
      return Icons.campaign_outlined;
    case 'dm':
      return Icons.forum_outlined;
    default:
      return Icons.groups_2_outlined;
  }
}

/// The display name of a chat role. Takes the localizations explicitly for the
/// same reason as [formatRelativeDateTime].
String labelForRole(String role, {AppLocalizations? l10n}) {
  final strings = l10n ?? L10n.current;
  switch (role) {
    case 'creator':
      return strings.roleOwner;
    case 'admin':
      return strings.roleAdmin;
    case 'restricted':
      return strings.roleRestricted;
    default:
      return strings.roleMember;
  }
}
