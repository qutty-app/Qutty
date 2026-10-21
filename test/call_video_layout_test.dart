import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/widgets/call_video_layout.dart';

CallVideoFeed _feed(
  String participant,
  CallVideoKind kind, {
  bool local = false,
}) {
  return CallVideoFeed(
    id: '$participant:${kind == CallVideoKind.camera ? 'cam' : 'cast'}',
    participantId: participant,
    displayName: participant,
    kind: kind,
    isLocal: local,
  );
}

CallSlot _slot(
  String participant,
  CallSlotKind kind, {
  bool local = false,
}) {
  final suffix = switch (kind) {
    CallSlotKind.camera => 'cam',
    CallSlotKind.screenShare => 'cast',
    CallSlotKind.avatar => 'avatar',
  };
  return CallSlot(
    id: '$participant:$suffix',
    participantId: participant,
    displayName: participant,
    kind: kind,
    isLocal: local,
  );
}

void main() {
  test('default slot selection is empty without slots', () {
    expect(defaultCallSlotSelection(const []), isNull);
  });

  test('default slot selection prefers your own camera', () {
    final slots = [
      _slot('me', CallSlotKind.avatar, local: true),
      _slot('me', CallSlotKind.camera, local: true),
      _slot('me', CallSlotKind.screenShare, local: true),
    ];
    expect(defaultCallSlotSelection(slots), 'me:cam');
  });

  test('default slot selection falls back through cast then avatar', () {
    expect(
      defaultCallSlotSelection([
        _slot('me', CallSlotKind.avatar, local: true),
        _slot('me', CallSlotKind.screenShare, local: true),
      ]),
      'me:cast',
    );
    expect(
      defaultCallSlotSelection([_slot('me', CallSlotKind.avatar, local: true)]),
      'me:avatar',
    );
  });

  test('default slot selection uses remotes when you have no slot', () {
    final slots = [
      _slot('a', CallSlotKind.avatar),
      _slot('b', CallSlotKind.camera),
    ];
    expect(defaultCallSlotSelection(slots), 'b:cam');
  });

  test('no feeds yields an empty arrangement', () {
    final arrangement = defaultCallArrangement(const []);
    expect(arrangement.isEmpty, isTrue);
  });

  test('your own cast is shown large with your camera in the corner', () {
    final feeds = [
      _feed('me', CallVideoKind.camera, local: true),
      _feed('me', CallVideoKind.screenShare, local: true),
    ];
    final arrangement = defaultCallArrangement(feeds);
    expect(arrangement.stageId, 'me:cast');
    expect(arrangement.pipId, 'me:cam');
    expect(arrangement.stripIds, isEmpty);
  });

  test('your cast and his cast pair up, remote taking the stage', () {
    final feeds = [
      _feed('me', CallVideoKind.screenShare, local: true),
      _feed('them', CallVideoKind.screenShare),
    ];
    final arrangement = defaultCallArrangement(feeds);
    expect(arrangement.stageId, 'them:cast');
    expect(arrangement.pipId, 'me:cast');
  });

  test(
    'a solo remote camera takes the stage with your camera in the corner',
    () {
      final feeds = [
        _feed('me', CallVideoKind.camera, local: true),
        _feed('them', CallVideoKind.camera),
      ];
      final arrangement = defaultCallArrangement(feeds);
      expect(arrangement.stageId, 'them:cam');
      expect(arrangement.pipId, 'me:cam');
    },
  );

  test('more than one remote switches to a bottom strip', () {
    final feeds = [
      _feed('me', CallVideoKind.camera, local: true),
      _feed('a', CallVideoKind.camera),
      _feed('b', CallVideoKind.screenShare),
    ];
    final arrangement = defaultCallArrangement(feeds);
    expect(arrangement.pipId, isNull);
    expect(arrangement.stageId, 'b:cast');
    // Remotes first, the local participant last.
    expect(arrangement.stripIds, ['a', 'b', 'me']);
  });

  test('spotlight prefers a cast and the strip tile prefers a camera', () {
    final feeds = [
      _feed('a', CallVideoKind.camera),
      _feed('a', CallVideoKind.screenShare),
    ];
    expect(preferredCallVideo(feeds, 'a')?.id, 'a:cast');
    expect(stripCallVideo(feeds, 'a')?.id, 'a:cam');
  });
}
