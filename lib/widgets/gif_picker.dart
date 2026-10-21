import 'dart:async';

import 'package:flutter/material.dart';

import 'package:qutty/api/api_service.dart';
import 'package:qutty/l10n/l10n.dart';

/// How long typing pauses before a search is sent.
///
/// KLIPY's test keys allow only 100 calls an hour, so searching on every
/// keystroke would burn the budget on a five letter word.
const _searchDebounce = Duration(milliseconds: 350);

/// The GIF tab: a search field, a chip row, and a grid of results.
///
/// KLIPY has no user-facing collections, so "Favourites" is a chip we serve
/// ourselves from our own table; every other chip is a term KLIPY publishes in
/// its category vocabulary, and selecting one searches for it.
class GifPicker extends StatefulWidget {
  final ApiService api;

  /// Called with the chosen GIF. The widget does not resolve or send it: the
  /// caller owns the download, so a failure there is reported in the composer
  /// rather than inside the picker.
  final ValueChanged<GifInfo> onSelected;

  /// Slugs the user has already saved, so hearts start filled.
  final Set<String> initialFavorites;

  const GifPicker({
    super.key,
    required this.api,
    required this.onSelected,
    this.initialFavorites = const {},
  });

  @override
  State<GifPicker> createState() => _GifPickerState();
}

class _GifPickerState extends State<GifPicker> {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  late Set<String> _favorites = {...widget.initialFavorites};

  List<GifInfo> _items = const [];
  int _page = 1;
  bool _hasNext = false;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  /// Guards against a slow first page overwriting the results of a newer
  /// request: the user can type again while the first request is in flight.
  int _requestId = 0;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    // Favourites are the default view, so the saved slugs are needed on open
    // both to show them and to mark them in search results.
    unawaited(_loadFavorites());
    _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// What the user has typed, which is also what selects the view.
  ///
  /// An empty box is the saved GIFs, so the two are one decision rather than a
  /// view toggle plus a filter.
  String get _query => _search.text.trim();

  /// True when the box is empty, which is the default favourites view.
  bool get _showingFavorites => _query.isEmpty;

  /// Loads the saved slugs so hearts are correct wherever GIFs are shown.
  ///
  /// This runs on open rather than only in the favourites view, because a
  /// favourite the user already saved has to read as saved in search results
  /// too, not just in the tab that lists them.
  Future<void> _loadFavorites() async {
    try {
      final page = await widget.api.gifFavorites();
      if (!mounted) return;
      setState(() => _favorites = {for (final gif in page.items) gif.slug});
    } catch (_) {
      // An unknown heart state is better than blocking the tab; the server is
      // the source of truth the next time the user toggles one.
    }
  }

  /// Fetches page one, replacing whatever is on screen.
  Future<void> _reload() async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _hasNext = false;
    });

    try {
      final page = _showingFavorites
          ? await widget.api.gifFavorites()
          : await widget.api.searchGifs(query: _query);
      if (!mounted || id != _requestId) return;
      setState(() {
        _items = page.items;
        _hasNext = page.hasNext;
        // In the favourites view the response is also the authority on which
        // slugs are saved, so refresh the hearts from it rather than making a
        // second identical request.
        if (_showingFavorites) {
          _favorites = {for (final gif in page.items) gif.slug};
        }
        _loading = false;
      });
    } on ApiException catch (exception) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = exception.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = L10n.current.mediaPickerGifLoadFailed;
        _loading = false;
      });
    }
  }

  /// Appends the next page when the grid nears its end.
  Future<void> _maybeLoadMore() async {
    if (!_hasNext || _loading || _loadingMore) return;
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 160) {
      return;
    }
    // The saved list is served whole, so there is no next page to ask for.
    if (_showingFavorites) return;

    setState(() => _loadingMore = true);
    final id = _requestId;
    try {
      final page = await widget.api.searchGifs(query: _query, page: _page + 1);
      if (!mounted || id != _requestId) return;
      setState(() {
        // Guard against a duplicate arriving if the listener fired twice.
        final seen = {for (final gif in _items) gif.slug};
        _items = [..._items, ...page.items.where((gif) => seen.add(gif.slug))];
        _page = page.page;
        _hasNext = page.hasNext;
        _loadingMore = false;
      });
    } catch (_) {
      // Leave _hasNext set so a later scroll retries rather than giving up.
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// Typing searches; emptying the box goes back to the saved GIFs.
  ///
  /// The debounce is not only about KLIPY's hourly budget: without it, deleting
  /// the last character would fire a request for the default view on every
  /// keystroke of the way back.
  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, _reload);
  }

  /// Clears the box, which is how the user returns to their saved GIFs.
  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    _reload();
  }

  Future<void> _toggleFavorite(GifInfo gif) async {
    final saved = !_favorites.contains(gif.slug);
    // Flip immediately: the heart is a direct manipulation and waiting for a
    // round trip makes the tap feel dropped.
    setState(() {
      saved ? _favorites.add(gif.slug) : _favorites.remove(gif.slug);
    });
    try {
      saved
          ? await widget.api.addGifFavorite(gif)
          : await widget.api.removeGifFavorite(gif.slug);
    } catch (_) {
      if (!mounted) return;
      // Put the heart back the way it was, since the server did not agree.
      setState(() {
        saved ? _favorites.remove(gif.slug) : _favorites.add(gif.slug);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _searchField(l10n, colors),
        Expanded(child: _body(l10n, colors)),
        // KLIPY's developer terms make displaying their branding a condition of
        // using the API, so this is a requirement rather than decoration.
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            l10n.mediaPickerGifPoweredBy,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.outline,
              fontSize: 9,
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchField(AppLocalizations l10n, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
      child: SizedBox(
        height: 32,
        child: TextField(
          controller: _search,
          onChanged: _onQueryChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: l10n.mediaPickerGifSearchHint,
            hintStyle: const TextStyle(fontSize: 13),
            prefixIcon: const Icon(Icons.search, size: 16),
            prefixIconConstraints: const BoxConstraints(minWidth: 30),
            // Clearing the box is how the user returns to their saved GIFs,
            // now that the favourites chip no longer exists.
            suffixIcon: _showingFavorites
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    splashRadius: 14,
                    tooltip: l10n.mediaPickerGifClearSearch,
                    onPressed: _clearSearch,
                  ),
            suffixIconConstraints: const BoxConstraints(minWidth: 30),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, ColorScheme colors) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _message(
        icon: Icons.error_outline,
        text: _error!,
        action: TextButton(
          onPressed: _reload,
          child: Text(l10n.commonTryAgain),
        ),
      );
    }
    if (_items.isEmpty) {
      // An empty default view needs different words from an empty search: with
      // no heart on the cells, "nothing found" would not tell the user how to
      // save their first GIF.
      return _message(
        icon: _showingFavorites ? Icons.favorite_border : Icons.search_off,
        text: _showingFavorites
            ? l10n.mediaPickerGifNoFavorites
            : l10n.mediaPickerGifEmpty,
      );
    }

    return GridView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 80,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: _items.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // The extra slot only exists while paging, so it is a null-aware
        // element rather than a branch on a boolean.
        final gif = index < _items.length ? _items[index] : null;
        if (gif == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _cell(gif, l10n);
      },
    );
  }

  Widget _cell(GifInfo gif, AppLocalizations l10n) {
    final saved = _favorites.contains(gif.slug);
    return Semantics(
      button: true,
      label: gif.title.isEmpty ? l10n.mediaPickerGifSend : gif.title,
      child: InkWell(
        onTap: () => widget.onSelected(gif),
        // The heart is a 30pt target, under the 44pt guideline, so long-press
        // offers an equally reachable way to save a GIF.
        onLongPress: () => _toggleFavorite(gif),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // A broken thumbnail should not leave a hole in the grid, so the
            // cell keeps its shape and just says nothing was loaded.
            Image.network(
              gif.displayUrl,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stack) => ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined, size: 16),
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              // Sized and placed so the heart cannot swallow the send tap.
              // IconButton's Material 3 box is 40x40 even when its InkWell is
              // only 20x20, and on a ~75pt cell a 40x40 corner box covers the
              // centre -- which meant tapping a GIF to send it favourited it
              // instead. shrinkWrap plus an explicit 30x30 keeps the heart's
              // hit area in the corner; the geometry is pinned by a test.
              child: IconButton(
                tooltip: saved
                    ? l10n.mediaPickerGifUnfavorite
                    : l10n.mediaPickerGifFavorite,
                style: IconButton.styleFrom(
                  minimumSize: const Size(30, 30),
                  maximumSize: const Size(30, 30),
                  padding: EdgeInsets.zero,
                  // Without shrinkWrap the button still claims a 48dp target.
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                iconSize: 15,
                onPressed: () => _toggleFavorite(gif),
                icon: Icon(
                  // Outlined when not liked, so an unliked GIF still shows that
                  // liking is available rather than looking already-saved.
                  saved ? Icons.favorite : Icons.favorite_border,
                  color: saved ? Colors.red : Colors.white,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String text,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
