import 'package:flutter_test/flutter_test.dart';
import 'package:qutty/api/app_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final manager = AppManager.instance;

  test('call preferences are stored under stable keys', () async {
    SharedPreferences.setMockInitialValues({});

    await manager.setCallCameraOn(true);
    await manager.setCallCameraFace('back');
    await manager.setCallLoudspeaker(false);
    await manager.setCallMicOn(false);
    await manager.setCallScreenShareAllowed(false);

    expect(manager.callCameraOn, isTrue);
    expect(manager.callCameraFace, 'back');
    expect(manager.callLoudspeaker, isFalse);
    expect(manager.callMicOn, isFalse);
    expect(manager.callScreenShareAllowed, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('qutty.call_camera_on'), isTrue);
    expect(prefs.getString('qutty.call_camera_face'), 'back');
    expect(prefs.getBool('qutty.call_loudspeaker'), isFalse);
    expect(prefs.getBool('qutty.call_mic_on'), isFalse);
    expect(prefs.getBool('qutty.call_screen_share'), isFalse);

    // Reset for other tests sharing the singleton.
    await manager.setCallCameraFace('front');
    await manager.setCallCameraOn(false);
    await manager.setCallLoudspeaker(true);
    await manager.setCallMicOn(true);
    await manager.setCallScreenShareAllowed(true);
  });

  test('an unknown camera face falls back to the front camera', () async {
    SharedPreferences.setMockInitialValues({});
    await manager.setCallCameraFace('sideways');
    expect(manager.callCameraFace, 'front');
  });

  test(
    'the fallback selector flag persists and forces the in-app picker',
    () async {
      SharedPreferences.setMockInitialValues({});
      await manager.setFallbackSelectorCast(false);
      expect(manager.fallbackSelectorCast, isFalse);

      await manager.setFallbackSelectorCast(true);
      expect(manager.fallbackSelectorCast, isTrue);
      expect(manager.platformOwnsScreenSharePicker, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('qutty.fallback_selector_cast'), isTrue);

      await manager.setFallbackSelectorCast(false);
    },
  );

  test('the force group call flag persists under a stable key', () async {
    SharedPreferences.setMockInitialValues({});
    await manager.setForceGroupCall(false);
    expect(manager.forceGroupCall, isFalse);

    await manager.setForceGroupCall(true);
    expect(manager.forceGroupCall, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('qutty.force_group_call_layout'), isTrue);

    await manager.setForceGroupCall(false);
  });
}
