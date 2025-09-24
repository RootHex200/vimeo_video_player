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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final physicalSize = PlatformDispatcher.instance.views.first.physicalSize;
    final controller = widget.player.controller;

    if (physicalSize.width > physicalSize.height) {
      // Landscape orientation
      if (!_isFullScreen) {
        setState(() {
          _isFullScreen = true;
        });
        controller.updateValue(controller.value.copyWith(isFullscreen: true));
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        
      }
    } else {
      // Portrait orientation
      if (_isFullScreen) {
        setState(() {
          _isFullScreen = false;
        });
        controller.updateValue(controller.value.copyWith(isFullscreen: false));
        SystemChrome.restoreSystemUIOverlays();
        
      }
    }
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
      controller.updateValue(controller.value.copyWith(isFullscreen: false));
      SystemChrome.restoreSystemUIOverlays();

    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, constraints) {
        final orientation = MediaQuery.orientationOf(context);
        final height = MediaQuery.sizeOf(context).height;
        final width = MediaQuery.sizeOf(context).width;

        final player = SizedBox(
          key: playerKey,
          height: orientation == Orientation.landscape ? height : null,
          width: orientation == Orientation.landscape ? width : null,
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

        // Use LayoutBuilder to determine orientation and show appropriate content
        if (orientation == Orientation.landscape) {
          // In landscape, show only the player in fullscreen
          return player;
        } else {
          // In portrait, show the child widget with the player
          return child;
        }
      },
    );
  }
}
