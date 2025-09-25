import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vimeo_player_package/src/player/player_widget.dart';

/// A wrapper for [VimeoPlayer] that supports switching between fullscreen and normal mode.
///
/// This widget automatically handles orientation changes and provides a seamless
/// fullscreen experience. When the device is rotated to landscape, the player
/// automatically enters fullscreen mode. When rotated back to portrait, it exits
/// fullscreen mode.
///
/// The [builder] function is called with the current [BuildContext] and the [VimeoPlayer]
/// widget, allowing you to customize the layout around the player.
///
/// Example usage:
/// ```dart
/// VimeoBuilder(
///   player: VimeoPlayer(
///     controller: controller,
///     onReady: () => print('Player ready'),
///   ),
///   builder: (context, player) {
///     return Column(
///       children: [
///         Text('Video Title'),
///         player,
///         Text('Video Description'),
///       ],
///     );
///   },
/// )
/// ```
///
/// When popping, if the player is in fullscreen, fullscreen will be toggled,
/// otherwise the route will pop.
class VimeoBuilder extends StatefulWidget {
  /// Builder for [VimeoPlayer] that supports switching between fullscreen and normal mode.
  /// When popping, if the player is in fullscreen, fullscreen will be toggled,
  /// otherwise the route will pop.
  const VimeoBuilder({
    super.key,
    required this.player,
    required this.builder,
  });

  /// The actual [VimeoPlayer].
  final VimeoPlayer player;

  /// Builds the widget below this [builder].
  final Widget Function(BuildContext, Widget) builder;

  @override
  State<VimeoBuilder> createState() => _VimeoBuilderState();
}

class _VimeoBuilderState extends State<VimeoBuilder>
    with WidgetsBindingObserver {
  final GlobalKey playerKey = GlobalKey();
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen to controller changes to sync fullscreen state
    widget.player.controller.addListener(_onControllerValueChanged);
  }

  void _onControllerValueChanged() {
    // Sync VimeoBuilder's fullscreen state with controller's fullscreen state
    if (widget.player.controller.value.isFullscreen != _isFullScreen) {
      setState(() {
        _isFullScreen = widget.player.controller.value.isFullscreen;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.player.controller.removeListener(_onControllerValueChanged);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final physicalSize = PlatformDispatcher.instance.views.first.physicalSize;
    final controller = widget.player.controller;

    // Only auto-switch to fullscreen for landscape videos when in landscape orientation
    // For portrait videos, let the VimeoPlayer handle its own fullscreen logic
    if (!widget.player.portrait) {
      if (physicalSize.width > physicalSize.height) {
        // Landscape orientation - auto fullscreen for landscape videos
        if (!_isFullScreen) {
          setState(() {
            _isFullScreen = true;
          });
          controller.updateValue(controller.value.copyWith(isFullscreen: true));
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        }
      } else {
        // Portrait orientation - exit fullscreen for landscape videos
        if (_isFullScreen) {
          setState(() {
            _isFullScreen = false;
          });
          controller.updateValue(controller.value.copyWith(isFullscreen: false));
          SystemChrome.restoreSystemUIOverlays();
        }
      }
    }
    // For portrait videos, don't interfere with orientation changes
    // Let VimeoPlayer handle its own fullscreen logic
    super.didChangeMetrics();
  }

  void _toggleFullScreen() {
    final controller = widget.player.controller;
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      controller.updateValue(controller.value.copyWith(isFullscreen: true));
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      
    } else {
      // When exiting fullscreen, restore all orientations and system UI
      controller.updateValue(controller.value.copyWith(isFullscreen: false));
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }


  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, constraints) {
        final height = MediaQuery.sizeOf(context).height;
        final width = MediaQuery.sizeOf(context).width;

        final player = SizedBox(
          key: playerKey,
          height: _isFullScreen ? height : null,
          width: _isFullScreen ? width : null,
          child: PopScope(
            canPop: !_isFullScreen,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              if (_isFullScreen) {
                _toggleFullScreen();
              }
            },
            child: widget.player,
          ),
        );

        final child = widget.builder(context, player);

        // Show fullscreen player when _isFullScreen is true (regardless of video type)
        // Otherwise show the child widget with the player
        if (_isFullScreen) {
          // Show only the player in fullscreen mode
          return player;
        } else {
          // Show the child widget with the player in normal mode
          return child;
        }
      },
    );
  }
}
