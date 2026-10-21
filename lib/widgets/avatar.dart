import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    final resolvedUrl = image.startsWith('http')
        ? image
        : '${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}$image';
    if (image.isEmpty || !resolvedUrl.toLowerCase().endsWith('.svg')) {
      final imageProvider = image.isEmpty ? null : NetworkImage(resolvedUrl);
      return CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? (_initial.isEmpty
                  ? Icon(fallbackIcon, size: radius)
                  : Text(_initial))
            : null,
      );
    }
    Widget fallback() => CircleAvatar(
      radius: radius,
      child: _initial.isEmpty
          ? Icon(fallbackIcon, size: radius)
          : Text(_initial),
    );
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(
        child: SvgPicture.network(
          resolvedUrl,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => fallback(),
          errorBuilder: (_, _, _) => fallback(),
        ),
      ),
    );
  }
}
