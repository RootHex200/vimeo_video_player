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
}
