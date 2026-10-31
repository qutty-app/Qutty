import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:qutty/api/app_manager.dart';
import 'package:qutty/services/media_cache.dart';

/// A picture that is kept on the device so it can be shown without a
/// connection.
///
/// The app draws pictures from several places -- avatars, attachments,
/// stickers -- and each of them is worth keeping: without them an offline
/// conversation is a column of placeholders. The file is fetched once, kept
/// on disk and drawn from there afterwards.
///
/// Whether the picture is already stored is answered from the cache's memory,
/// never from the disk: a drawing path that waited for the disk would freeze
/// the frame. A picture that is not stored yet comes from the network, and is
/// fetched in the background so the next visit does not need it.
///
/// When the media cache is switched off the picture comes straight from the
/// network and nothing is written to disk.
class CachedImage extends StatefulWidget {
  /// The picture to show. A path is resolved against [baseUrl].
  final String url;

  /// The server the url belongs to, used when the url is a path.
  final String baseUrl;

  final double? width;
  final double? height;
  final BoxFit? fit;

  /// Shown while the picture is on its way.
  final Widget? placeholder;

  /// Shown when the picture cannot be shown at all.
  final Widget Function(BuildContext context, Object error, StackTrace? stack)?
  errorBuilder;

  const CachedImage({
    super.key,
    required this.url,
    this.baseUrl = '',
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorBuilder,
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  @override
  void initState() {
    super.initState();
    _keep();
  }

  @override
  void didUpdateWidget(covariant CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.baseUrl != widget.baseUrl) {
      _keep();
    }
  }

  /// Keeps the picture on the device for the next time it is shown.
  void _keep() {
    final url = _absoluteUrl;
    if (url.isEmpty) return;
    final manager = AppManager.instance;
    if (!manager.cacheMedia) return;
    MediaCache.instance.prefetch(url, headers: manager.mediaHeadersFor(url));
  }

  /// The absolute url of the picture, with the server's address filled in
  /// when the url is only a path.
  String get _absoluteUrl {
    final url = widget.url.trim();
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = widget.baseUrl;
    if (base.isEmpty) return url;
    return '${base.endsWith('/') ? base.substring(0, base.length - 1) : base}$url';
  }

  /// Whether the picture is an SVG, which is drawn by another renderer.
  bool get _isSvg {
    final path = Uri.tryParse(_absoluteUrl)?.path.toLowerCase() ?? '';
    return path.endsWith('.svg');
  }

  @override
  Widget build(BuildContext context) {
    final url = _absoluteUrl;
    if (url.isEmpty) return widget.placeholder ?? const SizedBox.shrink();
    final stored = MediaCache.instance.cachedFileFor(url);
    if (stored != null) return _fileView(stored);
    return Image.network(
      url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: widget.errorBuilder,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : widget.placeholder ?? const SizedBox.shrink(),
    );
  }

  /// The picture, drawn from the file on the device.
  Widget _fileView(File file) {
    if (_isSvg) {
      return SvgPicture.file(
        file,
        width: widget.width,
        height: widget.height,
        fit: widget.fit ?? BoxFit.contain,
        placeholderBuilder: (_) =>
            widget.placeholder ?? const SizedBox.shrink(),
      );
    }
    return Image.file(
      file,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      // A file that vanished between the lookup and the draw is a cache miss
      // rather than a broken picture, so the network gets a turn.
      errorBuilder:
          widget.errorBuilder ??
          (context, error, stack) => Image.network(
            _absoluteUrl,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            errorBuilder: widget.errorBuilder,
          ),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 150),
          child: child,
        );
      },
    );
  }
}
