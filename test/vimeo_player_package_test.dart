import 'package:flutter_test/flutter_test.dart';

import 'package:vimeo_player_package/flutter_vimeo_player.dart';

void main() {
  test('VimeoPlayerController creation', () {
    final controller = VimeoPlayerController(
      initialVideoId: 'test123',
      flags: VimeoPlayerFlags(),
    );
    expect(controller.initialVideoId, 'test123');
    expect(controller.value.isReady, false);
    expect(controller.value.isPlaying, false);
  });

  test('VimeoPlayerFlags default values', () {
    final flags = VimeoPlayerFlags();
    expect(flags.autoPlay, false);
    expect(flags.controls, true);
    expect(flags.loop, false);
    expect(flags.muted, false);
  });

  test('VimeoPlayerController volume methods', () {
    final controller = VimeoPlayerController(
      initialVideoId: 'test123',
      flags: VimeoPlayerFlags(),
    );

    // Test that volume methods exist and can be called
    expect(() => controller.setVolume(0.5), returnsNormally);
    expect(() => controller.mute(), returnsNormally);
    expect(() => controller.unmute(), returnsNormally);
  });

  test('VimeoPlayerController quality methods', () {
    final controller = VimeoPlayerController(
      initialVideoId: 'test123',
      flags: VimeoPlayerFlags(),
    );

    // Test that quality methods exist and can be called
    expect(() => controller.setQuality('Auto'), returnsNormally);
    expect(() => controller.setQuality('1080p'), returnsNormally);
    expect(() => controller.setQuality('720p'), returnsNormally);
    expect(() => controller.setQuality('480p'), returnsNormally);
    expect(() => controller.setQuality('360p'), returnsNormally);
  });

  test('VimeoPlayerController playback rate methods', () {
    final controller = VimeoPlayerController(
      initialVideoId: 'test123',
      flags: VimeoPlayerFlags(),
    );

    // Test that playback rate methods exist and can be called
    expect(() => controller.setPlaybackRate(0.5), returnsNormally);
    expect(() => controller.setPlaybackRate(0.75), returnsNormally);
    expect(() => controller.setPlaybackRate(1.0), returnsNormally);
    expect(() => controller.setPlaybackRate(1.25), returnsNormally);
    expect(() => controller.setPlaybackRate(1.5), returnsNormally);
    expect(() => controller.setPlaybackRate(2.0), returnsNormally);
  });
}
