# Vimeo Player Package

A Flutter package for playing Vimeo videos with advanced fullscreen support for both portrait and landscape orientations.

## Features

- 🎥 **Vimeo Video Playback** - Play any Vimeo video using video ID
- 📱 **Portrait & Landscape Support** - Automatic orientation handling for different video types
- 🖥️ **Smart Fullscreen** - Intelligent fullscreen mode with proper aspect ratios
- 🎮 **Custom Controls** - Built-in video controls with modern UI
- ⚡ **Performance Optimized** - Smooth playback with WebView integration
- 🎨 **Customizable** - Easy to integrate and customize

## Getting Started

### Prerequisites

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  vimeo_player_package: ^1.0.0
  flutter_inappwebview: ^6.0.0
```

### Installation

```bash
flutter pub get
```

## Usage

### Basic Usage

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
    return Scaffold(
      body: VimeoPlayer(
        controller: controller,
        portrait: true, // Set to true for portrait videos, false for landscape
        onReady: () {
          print('Player ready!');
        },
      ),
    );
  }
}
```

### Portrait vs Landscape Videos

The package automatically handles different video orientations with a simple `portrait` parameter:

#### For Portrait Videos (TikTok, Instagram Stories, etc.)
```dart
VimeoPlayer(
  controller: controller,
  portrait: true, // Enables portrait fullscreen logic
  onScreenToggled: _toggleFullscreen,
)
```

#### For Landscape Videos (YouTube, etc.)
```dart
VimeoPlayer(
  controller: controller,
  portrait: false, // Enables landscape fullscreen logic
  onScreenToggled: _toggleFullscreen,
)
```

### Fullscreen Implementation

```dart
import 'package:flutter/services.dart';

void _toggleFullscreen() {
  setState(() {
    _isFullScreen = !_isFullScreen;
  });
  
  if (_isFullScreen) {
    if (_isPortraitMode) {
      // Force portrait orientation for portrait videos
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      // Force landscape orientation for landscape videos
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    controller.updateValue(controller.value.copyWith(isFullscreen: true));
  } else {
    _exitFullscreen();
  }
}

void _exitFullscreen() {
  setState(() {
    _isFullScreen = false;
  });
  
  // Allow all orientations when exiting fullscreen
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Restore system UI
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  controller.updateValue(controller.value.copyWith(isFullscreen: false));
}
```

### Advanced Usage with VimeoBuilder

```dart
VimeoBuilder(
  player: VimeoPlayer(
    controller: controller,
    portrait: _isPortraitMode,
    onScreenToggled: _toggleFullscreen,
    skipDuration: 10, // Skip duration in seconds for double-tap
    onReady: () {
      print('Player is ready!');
    },
  ),
  builder: (context, player) {
    return Scaffold(
      appBar: _isFullScreen ? null : AppBar(title: Text('Video Player')),
      body: _isFullScreen 
        ? Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: player,
          )
        : Center(child: player),
    );
  },
)
```

## API Reference

### VimeoPlayer

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `controller` | `VimeoPlayerController` | Required | The video controller |
| `portrait` | `bool` | `false` | Set to `true` for portrait videos, `false` for landscape |
| `onScreenToggled` | `VoidCallback?` | `null` | Called when fullscreen is toggled |
| `skipDuration` | `int` | `5` | Skip duration in seconds for double-tap |
| `onReady` | `VoidCallback?` | `null` | Called when player is ready |
| `aspectRatio` | `double` | `16/9` | Video aspect ratio |
| `width` | `double?` | `null` | Custom width |
| `height` | `double?` | `null` | Custom height |

### VimeoPlayerController

```dart
// Create controller
final controller = VimeoPlayerController(
  initialVideoId: 'your_video_id',
  flags: VimeoPlayerFlags(
    autoPlay: false,
  ),
);

// Control playback
controller.play();
controller.pause();
controller.seekTo(30.0); // Seek to 30 seconds
controller.setVolume(0.5); // Set volume to 50%
controller.mute();
controller.unmute();

// Quality and speed control
controller.setQuality('720p');
controller.setPlaybackRate(1.5); // 1.5x speed

// Fullscreen control
controller.updateValue(controller.value.copyWith(isFullscreen: true));
```

### VimeoPlayerFlags

```dart
VimeoPlayerFlags(
  autoPlay: false, // Auto-play video when loaded
)
```

## What Happens Automatically

### When `portrait: true`:
- ✅ Fullscreen uses portrait-optimized dimensions
- ✅ Video width: 90% of screen width  
- ✅ Video height: 60% of screen width (portrait aspect ratio)
- ✅ Forces portrait orientation in fullscreen
- ✅ Perfect for vertical videos (TikTok, Instagram Stories)

### When `portrait: false`:
- ✅ Fullscreen uses landscape-optimized dimensions
- ✅ Video width: 90% of screen width
- ✅ Video height: 56% of screen width (16:9 aspect ratio)
- ✅ Forces landscape orientation in fullscreen
- ✅ Perfect for horizontal videos (YouTube, movies)

## Example

Check out the complete example in the `/example` folder to see a full implementation with:
- Portrait/Landscape mode toggle
- Fullscreen functionality
- Custom controls
- Responsive design

## Platform Support

- ✅ iOS
- ✅ Android
- ✅ Web (with limitations)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions, please file an issue on the GitHub repository.

---

**Made with ❤️ for Flutter developers**