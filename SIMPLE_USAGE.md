# Super Simple VimeoPlayer Usage

## No Complex Logic Needed! 🎉

The VimeoPlayer now handles ALL fullscreen logic internally. You just need to set `portrait: true/false` and everything works automatically!

## Basic Usage

```dart
import 'package:vimeo_player_package/vimeo_player_package.dart';

class MyVideoPlayer extends StatefulWidget {
  @override
  _MyVideoPlayerState createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  late VimeoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VimeoPlayerController(
      initialVideoId: 'your_vimeo_video_id',
      flags: VimeoPlayerFlags(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VimeoBuilder(
      player: VimeoPlayer(
        controller: controller,
        portrait: true, // That's it! No other logic needed
        onReady: () {
          print('Player ready!');
        },
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: Text('Video Player')),
          body: Center(child: player),
        );
      },
    );
  }
}
```

## What Happens Automatically:

### When `portrait: true`:
- ✅ Fullscreen button automatically handles portrait orientation
- ✅ Video dimensions: 90% width, 60% height (portrait aspect ratio)
- ✅ Device rotates to portrait in fullscreen
- ✅ System UI hides for immersive experience
- ✅ Perfect for TikTok, Instagram Stories, vertical videos

### When `portrait: false`:
- ✅ Fullscreen button automatically handles landscape orientation  
- ✅ Video dimensions: 90% width, 56% height (16:9 aspect ratio)
- ✅ Device rotates to landscape in fullscreen
- ✅ System UI hides for immersive experience
- ✅ Perfect for YouTube, movies, horizontal videos

## No More Complex Code!

### ❌ Before (Complex):
```dart
// You had to write all this complex logic:
void _toggleFullscreen() {
  setState(() {
    _isFullScreen = !_isFullScreen;
  });
  
  if (_isFullScreen) {
    if (_isPortraitMode) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    controller.updateValue(controller.value.copyWith(isFullscreen: true));
  } else {
    // More complex exit logic...
  }
}
```

### ✅ Now (Simple):
```dart
// Just this one line:
VimeoPlayer(
  controller: controller,
  portrait: true, // or false
)
```

## Complete Example:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyVideoPlayer(),
    );
  }
}

class MyVideoPlayer extends StatefulWidget {
  @override
  _MyVideoPlayerState createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  late VimeoPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VimeoPlayerController(
      initialVideoId: '1003797907', // Your Vimeo video ID
      flags: VimeoPlayerFlags(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VimeoBuilder(
      player: VimeoPlayer(
        controller: controller,
        portrait: true, // Set to false for landscape videos
        onReady: () {
          print('Player is ready!');
        },
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: Text('My Video')),
          body: Center(child: player),
        );
      },
    );
  }
}
```

## That's It! 🚀

- No orientation handling code needed
- No fullscreen logic needed  
- No dimension calculations needed
- No SystemChrome calls needed
- Just set `portrait: true/false` and everything works!

The package handles all the complexity internally, so you can focus on building your app! 🎯