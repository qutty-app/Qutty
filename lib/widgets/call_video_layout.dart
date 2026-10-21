import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart'
    show
        Participant,
        Room,
        TrackSource,
        VideoTrack,
        VideoTrackRenderer,
        VideoViewFit,
        VideoViewMirrorMode;

import 'package:qutty/widgets/avatar.dart';

/// Whether a [CallVideoFeed] carries a camera or a shared screen.
enum CallVideoKind { camera, screenShare }

/// One videos feed inside a call: a single participant's camera or cast.
///
/// Kept free of LiveKit types so the layout rules can be reasoned about (and
/// tested) without a media server. The renderer pairs a feed with its track by
/// [id].
class CallVideoFeed {
  const CallVideoFeed({
    required this.id,
    required this.participantId,
    required this.displayName,
    required this.kind,
    required this.isLocal,
  });

  /// Stable key, unique per participant and kind (`<identity>:cam`/`:cast`).
  final String id;
  final String participantId;
  final String displayName;
  final CallVideoKind kind;
  final bool isLocal;
}

/// What a [CallSlot] shows: a participant's picture, camera, or cast.
enum CallSlotKind { avatar, camera, screenShare }

/// One tile in a group call.
///
/// A participant contributes a single picture tile when they have no video, one
/// tile for a live cast or camera, and two tiles (cast and camera) when both are
/// live. The local participant leads the strip.
class CallSlot {
  const CallSlot({
    required this.id,
    required this.participantId,
    required this.displayName,
    required this.kind,
    required this.isLocal,
  });

  /// Stable key, unique per participant and kind
  /// (`<identity>:cam`, `<identity>:cast`, `<identity>:avatar`).
  final String id;
  final String participantId;
  final String displayName;
  final CallSlotKind kind;
  final bool isLocal;
}

/// Which feeds are shown large, in a corner, or along the bottom strip.
class CallVideoArrangement {
  const CallVideoArrangement({
    this.stageId,
    this.pipId,
    this.stripIds = const [],
  });

  /// The large feed, or null when there is nothing to show.
  final String? stageId;

  /// The small tappable corner feed (null when more than one remote is in the
  /// call, where the [stripIds] strip takes over).
  final String? pipId;

  /// One entry per participant, in display order, for the bottom strip.
  final List<String> stripIds;

  bool get isEmpty => stageId == null && pipId == null && stripIds.isEmpty;
}

CallVideoFeed? _first(
  List<CallVideoFeed> feeds,
  String participantId,
  CallVideoKind kind,
) {
  for (final feed in feeds) {
    if (feed.participantId == participantId && feed.kind == kind) return feed;
  }
  return null;
}

CallVideoFeed? _castOf(List<CallVideoFeed> feeds, String participantId) =>
    _first(feeds, participantId, CallVideoKind.screenShare);

CallVideoFeed? _camOf(List<CallVideoFeed> feeds, String participantId) =>
    _first(feeds, participantId, CallVideoKind.camera);

/// The feed a participant is spotlighted with, preferring their cast.
CallVideoFeed? preferredCallVideo(
  List<CallVideoFeed> feeds,
  String participantId,
) => _castOf(feeds, participantId) ?? _camOf(feeds, participantId);

/// The feed shown on a participant's strip tile, preferring their camera.
CallVideoFeed? stripCallVideo(
  List<CallVideoFeed> feeds,
  String participantId,
) => _camOf(feeds, participantId) ?? _castOf(feeds, participantId);

/// Orders participant ids remote-first with the local participant last.
List<String> callParticipantOrder(List<CallVideoFeed> feeds) {
  final ids = <String>[];
  for (final feed in feeds) {
    if (!ids.contains(feed.participantId)) ids.add(feed.participantId);
  }
  final remote = <String>[];
  final local = <String>[];
  for (final id in ids) {
    final feed = feeds.firstWhere((f) => f.participantId == id, orElse: () => feeds.first);
    (feed.isLocal ? local : remote).add(id);
  }
  return [...remote, ...local];
}

/// The default spotlight/corner/strip layout for the given feeds.
///
/// With zero or one remote participant the call uses a large stage plus a
/// tappable corner: a cast is shown large and the camera in the corner (or the
/// two casts are paired), and tapping the corner swaps them. With two or more
/// remote participants a bottom strip lists everyone and the stage spotlights
/// the selected participant.
CallVideoArrangement defaultCallArrangement(List<CallVideoFeed> feeds) {
  if (feeds.isEmpty) return const CallVideoArrangement();
  final order = callParticipantOrder(feeds);
  final localFeed =
      feeds.firstWhere((f) => f.isLocal, orElse: () => feeds.first);
  final localId = localFeed.participantId;
  final remoteIds = [
    for (final id in order)
      if (id != localId) id,
  ];

  CallVideoFeed? stage;
  for (final id in remoteIds) {
    stage ??= _castOf(feeds, id);
  }
  for (final id in remoteIds) {
    stage ??= _camOf(feeds, id);
  }
  stage ??= _castOf(feeds, localId) ?? _camOf(feeds, localId) ?? feeds.first;

  if (remoteIds.length >= 2) {
    return CallVideoArrangement(stageId: stage.id, stripIds: order);
  }

  final pip = _pickPip(feeds, stage);
  return CallVideoArrangement(stageId: stage.id, pipId: pip?.id);
}

/// Pairs the stage with the best corner feed, preferring the opposite kind so a
/// cast sits next to a camera.
CallVideoFeed? _pickPip(List<CallVideoFeed> feeds, CallVideoFeed stage) {
  final others = [
    for (final feed in feeds)
      if (feed.id != stage.id) feed,
  ];
  if (others.isEmpty) return null;
  final wantKind = stage.kind == CallVideoKind.camera
      ? CallVideoKind.screenShare
      : CallVideoKind.camera;
  for (final feed in others) {
    if (feed.kind == wantKind) return feed;
  }
  return others.first;
}

/// Collects the camera/cast feeds currently live in [room].
List<CallVideoFeed> buildCallVideoFeeds(Room room) {
  final feeds = <CallVideoFeed>[];
  void collect(Participant? participant, bool isLocal) {
    if (participant == null) return;
    final identity = participant.identity;
    final cast = participant.getTrackPublicationBySource(
      TrackSource.screenShareVideo,
    );
    if (cast != null && cast.track != null && !cast.muted) {
      feeds.add(
        CallVideoFeed(
          id: '$identity:cast',
          participantId: identity,
          displayName: participant.name,
          kind: CallVideoKind.screenShare,
          isLocal: isLocal,
        ),
      );
    }
    final cam = participant.getTrackPublicationBySource(TrackSource.camera);
    if (cam != null && cam.track != null && !cam.muted) {
      feeds.add(
        CallVideoFeed(
          id: '$identity:cam',
          participantId: identity,
          displayName: participant.name,
          kind: CallVideoKind.camera,
          isLocal: isLocal,
        ),
      );
    }
  }

  collect(room.localParticipant, true);
  for (final remote in room.remoteParticipants.values) {
    collect(remote, false);
  }
  return feeds;
}

/// Every slot the participants in [room] contribute.
///
/// A participant with video contributes one tile per live source (cast and/or
/// camera); a participant without video contributes a single picture tile. The
/// local participant comes first, then the remotes.
List<CallSlot> buildCallSlots(Room room) {
  final slots = <CallSlot>[];
  void collect(Participant? participant, bool isLocal) {
    if (participant == null) return;
    final identity = participant.identity;
    final name = participant.name;
    final cast = participant.getTrackPublicationBySource(
      TrackSource.screenShareVideo,
    );
    final cam = participant.getTrackPublicationBySource(TrackSource.camera);
    final hasCast = cast != null && cast.track != null && !cast.muted;
    final hasCam = cam != null && cam.track != null && !cam.muted;
    if (hasCast) {
      slots.add(
        CallSlot(
          id: '$identity:cast',
          participantId: identity,
          displayName: name,
          kind: CallSlotKind.screenShare,
          isLocal: isLocal,
        ),
      );
    }
    if (hasCam) {
      slots.add(
        CallSlot(
          id: '$identity:cam',
          participantId: identity,
          displayName: name,
          kind: CallSlotKind.camera,
          isLocal: isLocal,
        ),
      );
    }
    if (!hasCast && !hasCam) {
      slots.add(
        CallSlot(
          id: '$identity:avatar',
          participantId: identity,
          displayName: name,
          kind: CallSlotKind.avatar,
          isLocal: isLocal,
        ),
      );
    }
  }

  collect(room.localParticipant, true);
  for (final remote in room.remoteParticipants.values) {
    collect(remote, false);
  }
  return slots;
}

/// The slot spotlighted at the top before the user picks one: the local
/// participant's webcam, then their cast, then their picture, then anything.
String? defaultCallSlotSelection(List<CallSlot> slots) {
  if (slots.isEmpty) return null;
  final own = [
    for (final slot in slots)
      if (slot.isLocal) slot,
  ];
  final pool = own.isNotEmpty ? own : slots;
  for (final kind in const [
    CallSlotKind.camera,
    CallSlotKind.screenShare,
    CallSlotKind.avatar,
  ]) {
    for (final slot in pool) {
      if (slot.kind == kind) return slot.id;
    }
  }
  return slots.first.id;
}

/// Maps each feed [id] to the LiveKit track that renders it.
Map<String, VideoTrack> callVideoTracks(Room room) {
  final tracks = <String, VideoTrack>{};
  void collect(Participant? participant) {
    if (participant == null) return;
    final identity = participant.identity;
    final cast = participant.getTrackPublicationBySource(
      TrackSource.screenShareVideo,
    );
    if (cast?.track is VideoTrack) {
      tracks['$identity:cast'] = cast!.track as VideoTrack;
    }
    final cam = participant.getTrackPublicationBySource(TrackSource.camera);
    if (cam?.track is VideoTrack) {
      tracks['$identity:cam'] = cam!.track as VideoTrack;
    }
  }

  collect(room.localParticipant);
  for (final remote in room.remoteParticipants.values) {
    collect(remote);
  }
  return tracks;
}

/// Renders a call's video: a large stage, a tappable corner feed, and a bottom
/// strip once more than one remote participant is present.
class CallVideoStage extends StatefulWidget {
  const CallVideoStage({
    super.key,
    required this.feeds,
    required this.tracks,
    this.avatarBaseUrl = '',
    this.selfLabel = 'You',
  });

  final List<CallVideoFeed> feeds;
  final Map<String, VideoTrack> tracks;
  final String avatarBaseUrl;
  final String selfLabel;

  @override
  State<CallVideoStage> createState() => _CallVideoStageState();
}

class _CallVideoStageState extends State<CallVideoStage> {
  String? _stageOverride;
  String? _pipOverride;
  late Object _signature;

  @override
  void initState() {
    super.initState();
    _signature = _feedSignature(widget.feeds);
  }

  @override
  void didUpdateWidget(CallVideoStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final signature = _feedSignature(widget.feeds);
    if (signature != _signature) {
      _signature = signature;
      // The feeds changed under the user; drop any manual pairing so the
      // default arrangement applies until they choose again.
      _stageOverride = null;
      _pipOverride = null;
    }
  }

  static Object _feedSignature(List<CallVideoFeed> feeds) =>
      [for (final feed in feeds) feed.id].join('|');

  CallVideoFeed? _feed(String? id) {
    if (id == null) return null;
    for (final feed in widget.feeds) {
      if (feed.id == id) return feed;
    }
    return null;
  }

  void _swap() {
    final base = defaultCallArrangement(widget.feeds);
    final stageId = _stageOverride ?? base.stageId;
    final pipId = _pipOverride ?? base.pipId;
    if (stageId == null || pipId == null) return;
    setState(() {
      _stageOverride = pipId;
      _pipOverride = stageId;
    });
  }

  void _spotlight(String participantId) {
    final feed = preferredCallVideo(widget.feeds, participantId);
    if (feed == null) return;
    setState(() {
      _stageOverride = feed.id;
      _pipOverride = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.feeds.isEmpty) return const SizedBox.shrink();

    final ids = {for (final feed in widget.feeds) feed.id};
    final base = defaultCallArrangement(widget.feeds);

    var stageId = _stageOverride;
    if (stageId == null || !ids.contains(stageId)) stageId = base.stageId;

    var pipId = _pipOverride;
    if (pipId == null || !ids.contains(pipId) || pipId == stageId) {
      pipId =
          (base.pipId != null &&
              base.pipId != stageId &&
              ids.contains(base.pipId))
          ? base.pipId
          : null;
    }

    final stage = _feed(stageId);
    final pip = _feed(pipId);
    if (stage == null && widget.feeds.isNotEmpty) {
      final fallback = widget.feeds.first;
      final tracks = widget.tracks;
      return _VideoSurface(
        key: ValueKey(fallback.id),
        feed: fallback,
        track: tracks[fallback.id],
        baseUrl: widget.avatarBaseUrl,
        selfLabel: widget.selfLabel,
      );
    }
    if (stage == null) return const SizedBox.shrink();
    final strip = [
      for (final id in base.stripIds)
        if (_participantHasFeed(id)) id,
    ];

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _VideoSurface(
                key: ValueKey(stage.id),
                feed: stage,
                track: widget.tracks[stage.id],
                baseUrl: widget.avatarBaseUrl,
                selfLabel: widget.selfLabel,
              ),
              if (pip != null)
                Positioned(
                  right: 12,
                  bottom: 12,
                  width: 112,
                  height: 150,
                  child: GestureDetector(
                    onTap: _swap,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _VideoSurface(
                        key: ValueKey(pip.id),
                        feed: pip,
                        track: widget.tracks[pip.id],
                        baseUrl: widget.avatarBaseUrl,
                        selfLabel: widget.selfLabel,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (strip.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: strip.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final participantId = strip[index];
                  final feed =
                      stripCallVideo(widget.feeds, participantId) ??
                      preferredCallVideo(widget.feeds, participantId);
                  if (feed == null) return const SizedBox.shrink();
                  final selected = feed.participantId == stage.participantId;
                  return GestureDetector(
                    onTap: () => _spotlight(participantId),
                    child: Container(
                      width: 112,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _VideoSurface(
                          key: ValueKey(feed.id),
                          feed: feed,
                          track: widget.tracks[feed.id],
                          baseUrl: widget.avatarBaseUrl,
                          selfLabel: widget.selfLabel,
                          compact: true,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  bool _participantHasFeed(String participantId) {
    for (final feed in widget.feeds) {
      if (feed.participantId == participantId) return true;
    }
    return false;
  }
}

/// Renders a group call: the selected slot large at the top, every slot in a
/// horizontal strip below, and the call controls underneath the caller.
///
/// Tapping a tile moves it to the top; the selection falls back to the local
/// participant whenever their slot disappears (or on first build).
class CallGroupLayout extends StatefulWidget {
  const CallGroupLayout({
    super.key,
    required this.slots,
    required this.tracks,
    this.avatarBaseUrl = '',
    this.selfLabel = 'You',
  });

  final List<CallSlot> slots;
  final Map<String, VideoTrack> tracks;
  final String avatarBaseUrl;
  final String selfLabel;

  @override
  State<CallGroupLayout> createState() => _CallGroupLayoutState();
}

class _CallGroupLayoutState extends State<CallGroupLayout> {
  String? _selectedId;

  CallSlot? _slot(String? id) {
    if (id == null) return null;
    for (final slot in widget.slots) {
      if (slot.id == id) return slot;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slots.isEmpty) return const SizedBox.shrink();

    final ids = {for (final slot in widget.slots) slot.id};
    var selectedId = _selectedId;
    if (selectedId == null || !ids.contains(selectedId)) {
      selectedId = defaultCallSlotSelection(widget.slots);
    }
    final selected = _slot(selectedId);
    if (selected == null) return const SizedBox.shrink();

    return Column(
      children: [
        Expanded(
          child: _SlotSurface(
            key: ValueKey('stage:${selected.id}'),
            slot: selected,
            track: widget.tracks[selected.id],
            baseUrl: widget.avatarBaseUrl,
            selfLabel: widget.selfLabel,
          ),
        ),
        if (widget.slots.length > 1)
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.slots.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final slot = widget.slots[index];
                final isSelected = slot.id == selected.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedId = slot.id),
                  child: Container(
                    width: 112,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _SlotSurface(
                        key: ValueKey('strip:${slot.id}'),
                        slot: slot,
                        track: widget.tracks[slot.id],
                        baseUrl: widget.avatarBaseUrl,
                        selfLabel: widget.selfLabel,
                        compact: true,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SlotSurface extends StatelessWidget {
  const _SlotSurface({
    super.key,
    required this.slot,
    required this.track,
    required this.baseUrl,
    required this.selfLabel,
    this.compact = false,
  });

  final CallSlot slot;
  final VideoTrack? track;
  final String baseUrl;
  final String selfLabel;
  final bool compact;

  String get _label => slot.displayName.isNotEmpty
      ? slot.displayName
      : slot.isLocal
      ? selfLabel
      : slot.participantId;

  @override
  Widget build(BuildContext context) {
    final video = track;
    if (slot.kind == CallSlotKind.avatar || video == null) {
      return _AvatarTile(label: _label, baseUrl: baseUrl, compact: compact);
    }
    final mirror = slot.isLocal && slot.kind == CallSlotKind.camera;
    return ColoredBox(
      color: Colors.black,
      child: VideoTrackRenderer(
        video,
        key: ValueKey('${slot.id}:renderer'),
        fit: slot.kind == CallSlotKind.screenShare
            ? VideoViewFit.contain
            : VideoViewFit.cover,
        mirrorMode: mirror
            ? VideoViewMirrorMode.mirror
            : VideoViewMirrorMode.off,
        placeholderBuilder: (context) =>
            _AvatarTile(label: _label, baseUrl: baseUrl, compact: compact),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.label,
    required this.baseUrl,
    this.compact = false,
  });

  final String label;
  final String baseUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Avatar(
            baseUrl: baseUrl,
            imageUrl: '',
            displayName: label,
            radius: compact ? 18 : 40,
          ),
          SizedBox(height: compact ? 4 : 12),
          Text(
            label,
            style: compact
                ? Theme.of(context).textTheme.bodySmall
                : Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _VideoSurface extends StatelessWidget {
  const _VideoSurface({
    super.key,
    required this.feed,
    required this.track,
    required this.baseUrl,
    required this.selfLabel,
    this.compact = false,
  });

  final CallVideoFeed feed;
  final VideoTrack? track;
  final String baseUrl;
  final String selfLabel;
  final bool compact;

  String get _label => feed.displayName.isNotEmpty
      ? feed.displayName
      : feed.isLocal
      ? selfLabel
      : feed.participantId;

  @override
  Widget build(BuildContext context) {
    final video = track;
    if (video == null) {
      return _Placeholder(label: _label, baseUrl: baseUrl, compact: compact);
    }
    final mirror = feed.isLocal && feed.kind == CallVideoKind.camera;
    return ColoredBox(
      color: Colors.black,
      child: VideoTrackRenderer(
        video,
        key: ValueKey('${feed.id}:renderer'),
        fit: feed.kind == CallVideoKind.screenShare
            ? VideoViewFit.contain
            : VideoViewFit.cover,
        mirrorMode: mirror
            ? VideoViewMirrorMode.mirror
            : VideoViewMirrorMode.off,
        placeholderBuilder: (context) =>
            _Placeholder(label: _label, baseUrl: baseUrl, compact: compact),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.label,
    required this.baseUrl,
    this.compact = false,
  });

  final String label;
  final String baseUrl;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Avatar(
        baseUrl: baseUrl,
        imageUrl: '',
        displayName: label,
        radius: compact ? 18 : 40,
      ),
    );
  }
}
