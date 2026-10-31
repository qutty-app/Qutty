import 'package:flutter/material.dart';

import 'package:qutty/widgets/cached_image.dart';

class Avatar extends StatelessWidget {
  final String displayName;
  final String imageUrl;
  final String baseUrl;
  final double radius;
  final IconData fallbackIcon;

  const Avatar({
    super.key,
    required this.displayName,
    this.imageUrl = '',
    required this.baseUrl,
    this.radius = 20,
    this.fallbackIcon = Icons.person_outline,
  });

  String get _initial => displayName.trim().isEmpty
      ? ''
      : displayName.trim().substring(0, 1).toUpperCase();

  @override
  Widget build(BuildContext context) {
    final image = imageUrl.trim();
    if (image.isEmpty) return _fallback(context);
    final resolvedUrl = image.startsWith('http')
        ? image
        : '${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}$image';
    final scheme = Theme.of(context).colorScheme;
    return ClipOval(
      child: ColoredBox(
        // The colour a circle avatar draws behind its picture, so a
        // transparent image does not show the page through it.
        color: scheme.surfaceContainerHighest,
        child: CachedImage(
          url: resolvedUrl,
          baseUrl: baseUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: _fallback(context),
          errorBuilder: (context, error, stack) => _fallback(context),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) => CircleAvatar(
    radius: radius,
    child: _initial.isEmpty
        ? Icon(fallbackIcon, size: radius)
        : Text(_initial),
  );
}
