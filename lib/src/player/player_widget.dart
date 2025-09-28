import 'dart:async';
import 'dart:ui';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vimeo_player_package/src/controllers/vimeo_controller.dart';
import 'package:vimeo_player_package/src/models/vimeo_metadata.dart';
import 'package:vimeo_player_package/src/player/webview_player.dart';

class VimeoPlayer extends StatefulWidget {
  @override
  final Key? key;
  final VimeoPlayerController? controller;
  final double aspectRatio;
  final int skipDuration;
  final VoidCallback? onReady;
  final VoidCallback? onScreenToggled;
  final bool portrait;
  final Widget? placeholder;

  const VimeoPlayer({
    this.key,
    this.controller,
    this.aspectRatio = 16 / 9,
    this.skipDuration = 5,
    this.onReady,
    this.onScreenToggled,
    this.portrait = false,
    this.placeholder,
  }) : super(key: key);

  @override
  _VimeoPlayerState createState() => _VimeoPlayerState();
}

class _VimeoPlayerState extends State<VimeoPlayer>
    with SingleTickerProviderStateMixin {
  VimeoPlayerController? _controller;
  late AnimationController _animationController;
  bool _initialLoad = true;
  double _position = 0.0;
  double _aspectRatio = 16 / 9;
  bool _seekingF = false;
  bool _seekingB = false;
  bool _isPlayerReady = false;
  bool _centerUiVisible = true;
  bool _bottomUiVisible = false;
  double _uiOpacity = 1.0;
  bool _isPlaying = false;
  int _seekDuration = 0;
  bool _showSettings = false;
  String _showSubmenu = ''; // 'quality' or 'speed'
  String _selectedQuality = 'Auto';
  double _playbackSpeed = 1.0;
  double _volume = 0.7;
  bool _isMuted = false;
  CancelableCompleter? completer;
  Timer? t;
  Timer? t2;
  Timer? _seekingTimer; // Timer to manage seeking state
  double? _seekingPosition; // Track position during seeking
  bool _isSeeking = false; // Flag to prevent position updates during seek
  double _displayPosition = 0.0; // Stable position for display
  bool _isFullScreen = false; // Internal fullscreen state
  Timer? _fullscreenDebounceTimer; // Timer to debounce fullscreen state changes
  bool _isDisposed = false;
  VoidCallback? _disposeCallback; // Store dispose callback for proper removal

  void listener() async {
    if (_isDisposed || _controller == null) return;

    final controller = _controller!;

    // Handle onReady callback first, outside of setState
    if (_controller?.value.isReady == true && !_isPlayerReady) {
      print('VimeoPlayer: Controller is ready, calling onReady callback');
      widget.onReady?.call();
      if (mounted) {
        setState(() {
          _centerUiVisible = true;
          _isPlayerReady = true;
        });
      }
    }

    // Always update state to ensure UI reflects current values
    if (mounted) {
      setState(() {
        _isPlaying = controller.value.isPlaying;

        // Only update position if we're not currently seeking
        if (controller.value.videoPosition != null && !_isSeeking) {
          _position = controller.value.videoPosition!;
          _displayPosition = _position; // Update display position
        }
      });
    }

    // Debounce fullscreen state changes to prevent blinking
    if (controller.value.isFullscreen != _isFullScreen) {
      _fullscreenDebounceTimer?.cancel();
      _fullscreenDebounceTimer = Timer(Duration(milliseconds: 50), () {
        if (mounted && !_isDisposed) {
          setState(() {
            _isFullScreen = controller.value.isFullscreen;
          });
        }
      });
    }

    if (controller.value.videoWidth != null &&
        controller.value.videoHeight != null) {
      if (mounted) {
        setState(() {
          if (widget.portrait) {
            // For portrait videos, use a portrait aspect ratio (9:16)
            _aspectRatio = 9.0 / 16.0;
          } else {
            // For landscape videos, use the actual video aspect ratio
            _aspectRatio =
                (controller.value.videoWidth! / controller.value.videoHeight!);
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Set initial aspect ratio based on portrait parameter
    _aspectRatio = widget.portrait ? (9.0 / 16.0) : widget.aspectRatio;

    // Initialize controller if provided
    if (widget.controller != null) {
      _controller = widget.controller;
      _controller!.addListener(listener);

      // Add dispose callback to controller
      _disposeCallback = () {
        _isDisposed = true;
      };
      _controller!.addDisposeCallback(_disposeCallback!);
    }

    // Always create completer - it will be disposed regardless of controller state
    completer = CancelableCompleter(
      onCancel: () {
        if (mounted && !_isDisposed) {
          setState(() {
            _bottomUiVisible = true;
            _uiOpacity = 1.0;
          });
        }
      },
    );

    // Always create animation controller - it will be disposed regardless of controller state
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(VimeoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller changes
    if (oldWidget.controller != widget.controller) {
      // Remove listener from old controller
      if (oldWidget.controller != null && !oldWidget.controller!.isDisposed) {
        oldWidget.controller!.removeListener(listener);
        // Remove old dispose callback if it exists
        if (_disposeCallback != null) {
          oldWidget.controller!.removeDisposeCallback(_disposeCallback!);
        }
      }

      // Add listener to new controller
      if (widget.controller != null && !widget.controller!.isDisposed) {
        _controller = widget.controller;
        _controller!.addListener(listener);

        // Add dispose callback to new controller
        _disposeCallback = () {
          _isDisposed = true;
        };
        _controller!.addDisposeCallback(_disposeCallback!);
      } else {
        _controller = null;
        _disposeCallback = null;
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Cancel all timers
    _seekingTimer?.cancel();
    _fullscreenDebounceTimer?.cancel();
    t?.cancel();
    t2?.cancel();

    // Cancel completer
    completer?.complete();

    // Remove listener and dispose callbacks
    if (_controller != null && !_controller!.isDisposed) {
      _controller!.removeListener(listener);
      // Remove dispose callback to prevent memory leaks
      if (_disposeCallback != null) {
        _controller!.removeDisposeCallback(_disposeCallback!);
        _disposeCallback = null;
      }
      // Don't dispose controller here as it might be used elsewhere
      // The controller should be disposed by its owner
    }

    // Dispose animation controller
    _animationController.dispose();

    super.dispose();
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  color: Colors.white.withOpacity(0.5),
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Video player ready',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Waiting for video to load...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      if (widget.portrait) {
        // Force portrait orientation for portrait videos
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      } else {
        // Force landscape orientation for landscape videos
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }

      // Hide system UI for immersive experience
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      // Update controller state
      _controller?.updateValue(_controller!.value.copyWith(isFullscreen: true));
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
    // Update controller state
    _controller?.updateValue(_controller!.value.copyWith(isFullscreen: false));
  }

  _hideUi() {
    setState(() {
      _bottomUiVisible = false;
      _centerUiVisible = false;
      _uiOpacity = 0.0;
    });
  }

  _onPlay() {
    if (_controller == null || _isDisposed) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
      _animationController.forward();
    } else {
      _controller!.play();
      _animationController.reverse();
    }

    if (_initialLoad) {
      if (mounted) {
        setState(() {
          _initialLoad = false;
          _centerUiVisible = false;
          _bottomUiVisible = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _centerUiVisible = false;
          _bottomUiVisible = true;
        });
      }

      t = Timer(Duration(seconds: 3), () {
        if (mounted && !_isDisposed) {
          _hideUi();
        }
      });
    }
  }

  _onBottomPlayButton() {
    if (_controller == null || _isDisposed) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
      if (mounted) {
        setState(() {
          _centerUiVisible = true;
          _bottomUiVisible = false;
          _uiOpacity = 1.0;
        });
      }
      if (t != null && t!.isActive) {
        t!.cancel();
      }
    } else {
      _controller!.play();
    }
  }

  _onUiTouched() {
    if (_isDisposed) return;

    // Close settings overlay if it's open
    if (_showSettings) {
      if (mounted) {
        setState(() {
          _showSettings = false;
          _showSubmenu = '';
        });
      }
      return; // Don't handle video controls when closing settings
    }

    if (t != null && t!.isActive) {
      t!.cancel();
    }
    if (_isPlaying) {
      if (_bottomUiVisible) {
        // Only pause the video when seekbar is showing
        _controller?.pause();
        if (mounted) {
          setState(() {
            _bottomUiVisible = false;
            _centerUiVisible = true;
            _uiOpacity = 1.0;
          });
        }
      } else {
        // Show bottom controls when seekbar is not visible
        if (mounted) {
          setState(() {
            _bottomUiVisible = true;
            _centerUiVisible = false;
            _uiOpacity = 1.0;
          });
        }
        /* delayed animation */
        t = Timer(Duration(seconds: 2), () {
          if (mounted && !_isDisposed) {
            _hideUi();
          }
        });
      }
    } else {
      // Show center play button when video is paused
      if (mounted) {
        setState(() {
          _bottomUiVisible = false;
          _centerUiVisible = true;
          _uiOpacity = 1.0;
        });
      }
    }
  }

  _handleDoublTap(TapDownDetails details) {
    // Close settings overlay if it's open
    if (_showSettings) {
      setState(() {
        _showSettings = false;
        _showSubmenu = '';
      });
      return; // Don't handle seek when closing settings
    }

    if (t != null && t!.isActive) {
      t!.cancel();
    }
    if (t2 != null && t2!.isActive) {
      t2!.cancel();
    }

    setState(() {
      _bottomUiVisible = true;
      _centerUiVisible = false;
      _uiOpacity = 1.0;
    });
    if (details.globalPosition.dx > MediaQuery.of(context).size.width / 2) {
      setState(() {
        _seekingF = true;
        _seekDuration = _seekDuration + widget.skipDuration;
      });
      /* seek fwd */
      _controller?.seekTo(_position + widget.skipDuration);
    } else {
      setState(() {
        _seekingB = true;
        _seekDuration = _seekDuration - widget.skipDuration;
      });
      /* seek Backward */
      _controller?.seekTo(_position - widget.skipDuration);
    }
    /* delayed animation */
    t = Timer(Duration(seconds: 3), () {
      _hideUi();
    });
    t2 = Timer(Duration(seconds: 1), () {
      setState(() {
        _seekingF = false;
        _seekingB = false;
        _seekDuration = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // If no controller is provided, show placeholder
    // This handles both cases: controller not provided or controller not yet initialized
    if (_controller == null) {
      return _buildPlaceholder();
    }

    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Material(
      elevation: 0,
      color: Colors.black,
      child: InheritedVimeoPlayer(
        controller: _controller!,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width,
            maxHeight: MediaQuery.of(context).size.height * 0.8, // Prevent excessive height on mobile
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: AspectRatio(
              aspectRatio: _aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: <Widget>[
                WebViewPlayer(
                  key: widget.key,
                  onEnded: (VimeoMetadata metadata) {
                    if (mounted && !_isDisposed) {
                      setState(() {
                        _uiOpacity = 1.0;
                        _bottomUiVisible = false;
                        _centerUiVisible = true;
                        _initialLoad = true;
                      });
                      _controller?.reload();
                    }
                  },
                  isFullscreen: _isFullScreen,
                  portrait: widget.portrait,
                ),
                GestureDetector(
                  onTap: () {
                    _onUiTouched();
                  },
                  onDoubleTapDown: _handleDoublTap,
                  child: AnimatedOpacity(
                    opacity: _uiOpacity,
                    curve: Curves.easeInOutCubic,
                    duration: const Duration(milliseconds: 400),
                    child: _controller?.value.isReady == true
                        ? Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.1),
                                  Colors.black.withOpacity(0.7),
                                ],
                                stops: const [0.0, 0.6, 1.0],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: _controller?.value.isReady == true
                                ? Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                left: 40,
                                              ),
                                              child: _seekingB
                                                  ? _buildModernSeekIndicator(
                                                      duration: _seekDuration,
                                                      isForward: false,
                                                    )
                                                  : const SizedBox(),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Center(
                                            child: _centerUiVisible
                                                ? _buildModernPlayButton()
                                                : const SizedBox(),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                right: 40,
                                              ),
                                              child: _seekingF
                                                  ? _buildModernSeekIndicator(
                                                      duration: _seekDuration,
                                                      isForward: true,
                                                    )
                                                  : const SizedBox(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(width: 1),
                          )
                        : const SizedBox(),
                  ),
                ),
                _controller?.value.isReady == true &&
                        _bottomUiVisible &&
                        !_initialLoad
                    ? _buildModernBottomControls(height, width)
                    : const SizedBox(height: 1),

                // Settings backdrop for tap detection
                if (_showSettings)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showSettings = false;
                          _showSubmenu = '';
                        });
                      },
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),

                // Settings overlay
                if (_showSettings)
                  _buildSettingsOverlay(BoxConstraints.tight(Size(width, height))),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    var ret = '';

    String twoDigitHours = twoDigits(duration.inHours.remainder(60));
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (twoDigitHours != '00') {
      ret += '$twoDigitHours:';
    }
    ret += '$twoDigitMinutes:';
    ret += twoDigitSeconds;

    return ret == '' ? '0:00' : ret;
  }

  _getTimestamp() {
    if (_controller == null) return '0:00 / 0:00';

    // Use stable display position to prevent jumping
    final currentPos = _isSeeking
        ? (_seekingPosition ?? _displayPosition)
        : _displayPosition;
    final totalDuration = _controller!.value.videoDuration ?? 0.0;

    var position = _printDuration(Duration(seconds: currentPos.round()));
    var duration = _printDuration(Duration(seconds: totalDuration.round()));

    // Ensure we always show duration even if position is 0
    if (totalDuration > 0) {
      return '$position / $duration';
    } else {
      return '0:00 / 0:00';
    }
  }

  // Modern UI Components
  Widget _buildModernPlayButton() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.8, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF01A4EA),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF01A4EA).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                splashColor: Colors.white.withOpacity(0.2),
                onTap: _onPlay,
                child: Icon(
                  _controller?.value.isPlaying == true
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernSeekIndicator({
    required int duration,
    required bool isForward,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF01A4EA).withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isForward) ...[
                  const Icon(
                    Icons.fast_rewind_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '${duration.abs()}s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isForward) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.fast_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernBottomControls(double height, double width) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _uiOpacity,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.9),
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar on top
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildVimeoStyleProgressBar(),
              ),
              // Controls below
              Padding(
                padding: EdgeInsets.fromLTRB(
                  width > 600 ? 24 : (width <= 380 ? 8 : 12),
                  8,
                  width > 600 ? 24 : (width <= 380 ? 8 : 12),
                  width > 600 ? 20 : 16,
                ),
                child: width <= 380
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildAdaptiveControlsRow(width),
                      )
                    : _buildAdaptiveControlsRow(width),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVimeoControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildVimeoStyleProgressBar() {
    return SizedBox(
      height: 24,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          activeTrackColor: const Color(0xFF01A4EA), // Custom blue
          inactiveTrackColor: Colors.white.withOpacity(0.3),
          thumbColor: Colors.white,
          overlayColor: const Color(0xFF01A4EA).withOpacity(0.2),
        ),
        child: Slider(
          onChangeStart: (val) {
            setState(() {
              _isSeeking = true;
              _seekingPosition = val;
            });
          },
          onChangeEnd: (end) {
            setState(() {
              _position = end; // Immediately update position
              _seekingPosition = end;
              _displayPosition = end; // Update display position
            });
            _controller?.seekTo(end.roundToDouble());
            // Clear seeking state after a delay
            _seekingTimer?.cancel();
            _seekingTimer = Timer(Duration(milliseconds: 1500), () {
              setState(() {
                _isSeeking = false;
                _seekingPosition = null;
              });
            });
          },
          min: 0,
          max: _controller?.value.videoDuration != null
              ? _controller!.value.videoDuration! + 1.0
              : 0.0,
          value: _isSeeking
              ? (_seekingPosition ?? _position).clamp(
                  0.0,
                  _controller?.value.videoDuration ?? 0.0,
                )
              : _position.clamp(0.0, _controller?.value.videoDuration ?? 0.0),
          onChanged: (value) {
            setState(() {
              _seekingPosition = value;
              _displayPosition = value; // Update display position in real-time
            });
          },
        ),
      ),
    );
  }

  Widget _buildVimeoTimeDisplay() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth <= 380;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF01A4EA).withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        _getTimestamp(),
        style: TextStyle(
          color: Colors.white,
          fontSize: isVerySmall ? 11 : 13,
          fontWeight: FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
          shadows: [
            Shadow(
              offset: const Offset(0, 1),
              blurRadius: 2,
              color: Colors.black.withOpacity(0.8),
            ),
          ],
        ),
        overflow: TextOverflow.visible,
        maxLines: 1,
      ),
    );
  }

  Widget _buildVolumeSlider() {
    return SizedBox(
      width: 50,
      height: 24,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 3),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 6),
          activeTrackColor: const Color(0xFF01A4EA),
          inactiveTrackColor: Colors.white.withOpacity(0.3),
          thumbColor: const Color(0xFF01A4EA),
          overlayColor: const Color(0xFF01A4EA).withOpacity(0.2),
        ),
        child: Slider(
          value: _volume,
          min: 0,
          max: 1,
          onChanged: (value) {
            setState(() {
              _volume = value;
              _isMuted = value == 0;
            });
            // Call the controller to set volume in the player
            _controller?.setVolume(value);
          },
        ),
      ),
    );
  }

  Widget _buildAdaptiveControlsRow(double width) {
    final isTablet = width > 600;
    final isMobile = width <= 400;
    final isVerySmall = width <= 380; // For very small screens

    return Row(
      children: [
        _buildVimeoControlButton(
          icon: _controller?.value.isPlaying == true
              ? Icons.pause
              : Icons.play_arrow,
          onTap: _onBottomPlayButton,
        ),
        SizedBox(width: isVerySmall ? 6 : (isTablet ? 16 : 12)),

        // Time display - always visible and prominent
        _buildVimeoTimeDisplay(),

        const Spacer(),

        // Volume controls - hide on mobile and very small screens
        if (!isMobile && !isVerySmall) ...[
          _buildVimeoControlButton(
            icon: _isMuted
                ? Icons.volume_off
                : (_volume > 0.5 ? Icons.volume_up : Icons.volume_down),
            onTap: () {
              setState(() {
                if (_isMuted) {
                  _isMuted = false;
                  _volume = 0.7;
                  _controller?.unmute();
                } else {
                  _isMuted = true;
                  _volume = 0.0;
                  _controller?.mute();
                }
              });
            },
          ),
          const SizedBox(width: 4),
          _buildVolumeSlider(),
          const SizedBox(width: 6),
        ],

        // Settings - always show with minimal spacing
        _buildVimeoControlButton(
          icon: Icons.settings,
          onTap: () {
            setState(() {
              _showSettings = !_showSettings;
              _showSubmenu = ''; // Reset submenu when opening/closing settings
            });
          },
        ),

        // PiP - only show on tablets
        if (isTablet) ...[
          const SizedBox(width: 4),
          _buildVimeoControlButton(
            icon: Icons.picture_in_picture_alt,
            onTap: () {
              // PiP functionality
            },
          ),
        ],

        // Minimal spacing before fullscreen
        const SizedBox(width: 4),
        _buildVimeoControlButton(
          icon: Icons.fullscreen,
          onTap: () {
            // Internal fullscreen toggle
            _toggleFullscreen();
            // Also call external callback if provided
            widget.onScreenToggled?.call();
          },
        ),
      ],
    );
  }


  Widget _buildSettingsOverlay(BoxConstraints constraints) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth <= 380;

    // Calculate responsive positioning
    final rightPosition = isSmallScreen ? 8.0 : (isTablet ? 24.0 : 16.0);
    final overlayWidth = isSmallScreen ? 140.0 : (isTablet ? 180.0 : 160.0);

    // Use actual player dimensions from constraints
    final playerHeight = constraints.maxHeight;

    // Calculate bottom position based on actual player height
    double bottomPosition;
    if (playerHeight < 250) {
      // For very small players (like 244px), use minimal bottom position
      bottomPosition = 20.0;
    } else if (playerHeight < 300) {
      // For small players, use small bottom position
      bottomPosition = 40.0;
    } else if (isSmallScreen) {
      bottomPosition = 50.0;
    } else if (isTablet) {
      bottomPosition = 100.0;
    } else {
      // For medium screens, use a moderate position
      bottomPosition = 70.0;
    }

    if (_showSubmenu == 'quality') {
      return _buildQualitySubmenu(rightPosition, bottomPosition, overlayWidth);
    } else if (_showSubmenu == 'speed') {
      return _buildSpeedSubmenu(rightPosition, bottomPosition, overlayWidth);
    }

    return Positioned(
      right: rightPosition,
      bottom: bottomPosition,
      child: GestureDetector(
        onTap: () {
          // Prevent backdrop tap when clicking on settings overlay
          // This prevents the backdrop tap from closing the settings
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: overlayWidth,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF01A4EA).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quality Option
              _buildEnhancedSettingsOption(
                'Quality',
                _selectedQuality,
                Icons.hd,
                () {
                  setState(() {
                    _showSubmenu = 'quality';
                  });
                },
                isSmallScreen,
              ),

              // Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.white.withOpacity(0.15),
              ),

              // Speed Option
              _buildEnhancedSettingsOption(
                'Speed',
                _playbackSpeed == 1.0 ? 'Normal' : '${_playbackSpeed}x',
                Icons.speed,
                () {
                  setState(() {
                    _showSubmenu = 'speed';
                  });
                },
                isSmallScreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSettingsOption(
    String title,
    String currentValue,
    IconData icon,
    VoidCallback onTap,
    bool isSmallScreen,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 8 : 10,
          ),
          child: Row(
            children: [
              // Icon - smaller and more compact
              Container(
                width: isSmallScreen ? 24 : 28,
                height: isSmallScreen ? 24 : 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF01A4EA).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF01A4EA),
                  size: isSmallScreen ? 12 : 14,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 10),

              // Title and Value - more compact
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      currentValue,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: isSmallScreen ? 10 : 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron - smaller
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.5),
                size: isSmallScreen ? 14 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualitySubmenu(
    double rightPosition,
    double bottomPosition,
    double overlayWidth,
  ) {
    final qualities = ['Auto', '1080p', '720p', '480p', '360p'];
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 380;

    return Positioned(
      right: rightPosition,
      bottom: bottomPosition,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: overlayWidth,
          maxHeight: 200, // Prevent overflow
        ),
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: overlayWidth,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF01A4EA).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showSubmenu = '';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 10),
                    Icon(
                      Icons.hd,
                      color: const Color(0xFF01A4EA),
                      size: isSmallScreen ? 14 : 16,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Text(
                      'Quality',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Quality options - scrollable
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: isSmallScreen ? 120 : 150,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: qualities
                        .map(
                          (quality) =>
                              _buildQualityOption(quality, isSmallScreen),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),    );
  }

  Widget _buildQualityOption(String quality, bool isSmallScreen) {
    final isSelected = _selectedQuality == quality;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          setState(() {
            _selectedQuality = quality;
            _showSubmenu = '';
            _showSettings = false;
          });
          _controller?.setQuality(quality);
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 6 : 8,
          ),
          child: Row(
            children: [
              Container(
                width: isSmallScreen ? 18 : 20,
                height: isSmallScreen ? 18 : 20,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF01A4EA).withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF01A4EA)
                        : Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: const Color(0xFF01A4EA),
                        size: isSmallScreen ? 10 : 12,
                      )
                    : null,
              ),
              SizedBox(width: isSmallScreen ? 8 : 10),
              Text(
                quality,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF01A4EA) : Colors.white,
                  fontSize: isSmallScreen ? 11 : 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedSubmenu(
    double rightPosition,
    double bottomPosition,
    double overlayWidth,
  ) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth <= 380;

    return Positioned(
      right: rightPosition,
      bottom: bottomPosition,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: overlayWidth,
          maxHeight: 200, // Prevent overflow
        ),
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: overlayWidth,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF01A4EA).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showSubmenu = '';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 10),
                    Icon(
                      Icons.speed,
                      color: const Color(0xFF01A4EA),
                      size: isSmallScreen ? 14 : 16,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Text(
                      'Speed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Speed options - scrollable
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: isSmallScreen ? 120 : 150,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: speeds
                        .map((speed) => _buildSpeedOption(speed, isSmallScreen))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),    );
  }

  Widget _buildSpeedOption(double speed, bool isSmallScreen) {
    final isSelected = _playbackSpeed == speed;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          setState(() {
            _playbackSpeed = speed;
            _showSubmenu = '';
            _showSettings = false;
          });
          _controller?.setPlaybackRate(speed);
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 6 : 8,
          ),
          child: Row(
            children: [
              Container(
                width: isSmallScreen ? 18 : 20,
                height: isSmallScreen ? 18 : 20,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF01A4EA).withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF01A4EA)
                        : Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: const Color(0xFF01A4EA),
                        size: isSmallScreen ? 10 : 12,
                      )
                    : null,
              ),
              SizedBox(width: isSmallScreen ? 8 : 10),
              Text(
                speed == 1.0 ? 'Normal' : '${speed}x',
                style: TextStyle(
                  color: isSelected ? const Color(0xFF01A4EA) : Colors.white,
                  fontSize: isSmallScreen ? 11 : 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
