# Simple VimeoPlayer Usage

## Portrait vs Landscape Video Control

The VimeoPlayer now has a simple `portrait` parameter that automatically handles fullscreen logic.

### Basic Usage

```dart
// For Portrait Videos (like TikTok, Instagram Stories)
VimeoPlayer(
  controller: controller,
  portrait: true,  // This enables portrait fullscreen logic
  onScreenToggled: _toggleFullscreen,
)

// For Landscape Videos (like YouTube)
VimeoPlayer(
  controller: controller,
  portrait: false, // This enables landscape fullscreen logic
  onScreenToggled: _toggleFullscreen,
)
```

### What happens automatically:

#### When `portrait: true`:
- Fullscreen mode uses portrait-optimized dimensions
- Video width: 90% of screen width
- Video height: 60% of screen width (portrait aspect ratio)
- Perfect for vertical videos

#### When `portrait: false`:
- Fullscreen mode uses landscape-optimized dimensions
- Video takes full screen with standard aspect ratio
- Perfect for horizontal videos

### Complete Example:

```dart
class MyVideoPlayer extends StatefulWidget {
  @override
  _MyVideoPlayerState createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  late VimeoPlayerController controller;
  bool _isPortraitMode = true; // Toggle between portrait/landscape

  @override
  void initState() {
    super.initState();
    controller = VimeoPlayerController(
      initialVideoId: 'your_video_id',
      flags: VimeoPlayerFlags(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VimeoPlayer(
        controller: controller,
        portrait: _isPortraitMode, // Simple boolean parameter!
        onScreenToggled: () {
          // Handle fullscreen toggle
        },
        onReady: () {
          print('Player ready!');
        },
      ),
    );
  }
}
```

### That's it! 

No complex logic needed. Just set `portrait: true` for vertical videos and `portrait: false` for horizontal videos. The player automatically handles all the fullscreen dimension calculations.
