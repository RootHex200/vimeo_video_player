# Vimeo Player Package

A Flutter package for playing Vimeo videos with advanced fullscreen support for both portrait and landscape orientations.

## Features

- **Vimeo Video Playback** - Play any Vimeo video using video ID
- **Portrait & Landscape Support** - Automatic orientation handling for different video types
- **Smart Fullscreen** - Intelligent fullscreen mode with proper aspect ratios


### Install

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  vimeo_player_package: ^1.0.0
```

### Installation

```bash
flutter pub get
```

## Usage

### basic usages

The package automatically handles different video orientations with a simple `portrait` parameter:

#### For Portrait/Landscape Videos
```dart
VimeoBuilder(
      player: VimeoPlayer(
        controller: controller,
        skipDuration: 10,
        portrait: false, // Set to true for portrait video, false for landscape
        onReady: () {
        },
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: Center(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                SizedBox(height: 300, child: player),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
```
### VimeoPlayer

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `controller` | `VimeoPlayerController` | Required | The video controller |
| `portrait` | `bool` | `false` | Set to `true` for portrait videos, `false` for landscape |
| `onScreenToggled` | `VoidCallback?` | `null` | Called when fullscreen is toggled |
| `skipDuration` | `int` | `5` | Skip duration in seconds for double-tap |
| `onReady` | `VoidCallback?` | `null` | Called when player is ready |
| `aspectRatio` | `double` | `16/9` | Video aspect ratio |



## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Made with ❤️ for Flutter developers**