import 'package:flutter/material.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:qutty/widgets/cached_image.dart';

export 'package:qutty/api/ugc_tags.dart';

/// Edge length of a UGC item sent as the whole message -- a sticker.
///
/// The item is the figure, so it gets a fixed square no matter what shape the
/// uploaded image was.
const double kUgcStickerSize = 256;

/// Edge length of a UGC item sitting inside text -- an emoji.
///
/// Punctuation, not a picture: it stays near the size of the glyphs around it
/// and never scales with the message.
const double kUgcEmojiSize = 16;

/// Renders one UGC item referenced by id.
///
/// The item is resolved through [AppManager], which caches it and fetches it on
/// first sight, so a message that mentions the same item twice draws it from
/// one request. While it is unresolved -- or if it never resolves -- a neutral
/// placeholder holds its place rather than collapsing the line.
class UgcView extends StatefulWidget {
  final int id;

  /// Edge length of the drawn image, in logical pixels. Both sides take it, so
  /// the item is always drawn square.
  final double size;

  const UgcView({super.key, required this.id, required this.size});

  @override
  State<UgcView> createState() => _UgcViewState();
}

class _UgcViewState extends State<UgcView> {
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant UgcView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) _resolve();
  }

  /// Asks the manager for the item. It notifies when the fetch settles, and the
  /// chat rebuilds, so this only has to start the work.
  void _resolve() {
    final manager = AppManager.instance;
    if (manager.ugcItem(widget.id) == null) {
      manager.ensureUgcItems([widget.id]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = AppManager.instance.ugcItem(widget.id);
    if (item == null) return _placeholder(context);
    return _image(context, item);
  }

  Widget _placeholder(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(widget.size * 0.15),
      ),
      child: Icon(
        Icons.emoji_emotions_outlined,
        size: widget.size * 0.5,
        color: colors.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _image(BuildContext context, UgcItem item) {
    final url = AppManager.instance.api.absoluteUrl(item.url);
    return CachedImage(
      url: url,
      baseUrl: AppManager.instance.api.baseUrl,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      placeholder: _placeholder(context),
      errorBuilder: (context, error, stack) => _placeholder(context),
    );
  }
}

/// A UGC item's thumbnail, for a picker grid where the item is already known.
class UgcThumb extends StatelessWidget {
  final UgcItem item;
  final double size;

  const UgcThumb({super.key, required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    final url = AppManager.instance.api.absoluteUrl(item.url);
    final placeholder = Icon(
      Icons.image_outlined,
      size: size * 0.5,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return CachedImage(
      url: url,
      baseUrl: AppManager.instance.api.baseUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholder: placeholder,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }
}
