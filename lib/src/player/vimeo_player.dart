import 'dart:async';
import 'dart:ui';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:vimeo_player_package/src/controllers/vimeo_player_controller.dart';
import 'package:vimeo_player_package/src/models/vimeo_meta_data.dart';
import 'package:vimeo_player_package/src/player/raw_vimeo_player.dart';

class VimeoPlayer extends StatefulWidget {
  @override
  final Key? key;
  final VimeoPlayerController controller;
  final double? height;
  final double? width;
  final double aspectRatio;
  final int skipDuration;
  final VoidCallback? onReady;

  const VimeoPlayer({
    this.key,
    required this.controller,
    this.width,
    this.height,
    this.aspectRatio = 16/9,
    this.skipDuration = 5,
    this.onReady
  }) : super(key: key);

  @override
  _VimeoPlayerState createState() => _VimeoPlayerState();
}

class _VimeoPlayerState extends State<VimeoPlayer> with SingleTickerProviderStateMixin {
  late VimeoPlayerController controller;
  late AnimationController _animationController;
  bool _initialLoad = true;
  double _position = 0.0;
  double _aspectRatio = 16/9;
  bool _seekingF = false;
  bool _seekingB = false;
  bool _isPlayerReady = false;
  bool _centerUiVisible = true;
  bool _bottomUiVisible = false;
  double _uiOpacity = 1.0;
  bool _isBuffering = false;
  bool _isPlaying = false;
  int _seekDuration = 0;
  bool _showSettings = false;
  String _showSubmenu = ''; // 'quality' or 'speed'
  String _selectedQuality = 'Auto';
  double _playbackSpeed = 1.0;
  double _volume = 0.7;
  bool _isMuted = false;
  late CancelableCompleter completer;
  Timer? t;
  Timer? t2;

  void listener() async {
    if (controller.value.isReady) {
      if (!_isPlayerReady) {
        widget.onReady?.call();
        setState(() {
          _centerUiVisible = true;
          _isPlayerReady = true;
        });
      }
    }
    
    // Always update state to ensure UI reflects current values
    setState(() {
      _isPlaying = controller.value.isPlaying;
      _isBuffering = controller.value.isBuffering;
      
      // Ensure position is always updated
      if (controller.value.videoPosition != null) {
        _position = controller.value.videoPosition!;
      }
    });
    
    if (controller.value.videoWidth != null && controller.value.videoHeight != null) {
      setState(() {
        _aspectRatio = (controller.value.videoWidth! / controller.value.videoHeight!);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    controller = widget.controller..addListener(listener);
    _aspectRatio = widget.aspectRatio;

    completer = CancelableCompleter(onCancel: () {
      print('onCancel');
      setState(() {
        _bottomUiVisible = true;
        _uiOpacity = 1.0;
      });
    });

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600)
    );
  }

  @override
  void didUpdateWidget(VimeoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller.removeListener(listener);
    widget.controller.addListener(listener);
  }

  @override
  void dispose() {
    controller.removeListener(listener);
    controller.dispose();
    super.dispose();
  }

  _hideUi() {
    setState(() {
      _bottomUiVisible = false;
      _centerUiVisible = false;
      _uiOpacity = 0.0;
    });
  }

  _onPlay() {
    if (controller.value.isPlaying) {
      controller.pause();
      _animationController.forward();
    } else {
      controller.play();
      _animationController.reverse();
    }

    if (_initialLoad) {
      setState(() {
        _initialLoad = false;
        _centerUiVisible = false;
        _bottomUiVisible = true;
      });
    } else {
      setState(() {
        _centerUiVisible = false;
        _bottomUiVisible = true;
      });

      t = Timer(Duration(seconds: 3), () {
        _hideUi();
      });
    }
  }

  _onBottomPlayButton() {
    if (controller.value.isPlaying) {
      controller.pause();
      setState(() {
        _centerUiVisible = true;
        _bottomUiVisible = false;
        _uiOpacity = 1.0;
      });
      if (t != null && t!.isActive) {
        t!.cancel();
      }
    } else {
      controller.play();
    }
  }

  _onUiTouched() {
    if (t != null && t!.isActive) {
      t!.cancel();
    }
    if (_isPlaying) {
      if (_bottomUiVisible) {
        // Only pause the video when seekbar is showing
        controller.pause();
        setState(() {
          _bottomUiVisible = false;
          _centerUiVisible = true;
          _uiOpacity = 1.0;
        });
      } else {
        // Show bottom controls when seekbar is not visible
      setState(() {
        _bottomUiVisible = true;
        _centerUiVisible = false;
        _uiOpacity = 1.0;
      });
      /* delayed animation */
      t = Timer(Duration(seconds: 3), () {
        _hideUi();
        });
      }
    } else {
      // Show center play button when video is paused
      setState(() {
        _bottomUiVisible = false;
        _centerUiVisible = true;
        _uiOpacity = 1.0;
      });
    }    
  }

  _handleDoublTap(TapDownDetails details) {
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
      controller.seekTo(_position + widget.skipDuration);
    } else {
      setState(() {
        _seekingB = true;
        _seekDuration = _seekDuration - widget.skipDuration;
      });
      /* seek Backward */
      controller.seekTo(_position - widget.skipDuration);
    }
    /* delayed animation */
    t = Timer(Duration(seconds: 3), () {
      _hideUi();
    });
    t2 = Timer(Duration(seconds: 1),() {
      setState(() {
        _seekingF = false;
        _seekingB = false;
        _seekDuration = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Material(
      elevation: 0,
      color: Colors.black,
      child: InheritedVimeoPlayer(
        controller: controller,
        child: SizedBox(
          width: widget.width ?? MediaQuery.of(context).size.width,
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: <Widget>[
                RawVimeoPlayer(
                  key: widget.key,
                  onEnded: (VimeoMetaData metadata) {
                    print('ended!');
                    setState(() {
                      _uiOpacity = 1.0;
                      _bottomUiVisible = false;
                      _centerUiVisible = true;
                      _initialLoad = true;
                    });
                    controller.reload();
                  },
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
                    child: controller.value.isReady ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.7)
                          ],
                          stops: const [0.0, 0.6, 1.0],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter
                        )
                      ),
                      child: controller.value.isReady ?
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 40),
                                  child: _seekingB ? _buildModernSeekIndicator(
                                    duration: _seekDuration,
                                    isForward: false,
                                  ) : const SizedBox(),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: _isBuffering ?
                                _buildModernLoadingIndicator()
                                :
                                _centerUiVisible ? _buildModernPlayButton() : const SizedBox(),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 40),
                                  child: _seekingF ? _buildModernSeekIndicator(
                                    duration: _seekDuration,
                                    isForward: true,
                                  ) : const SizedBox(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ) : const SizedBox(width: 1),
                    ) : const SizedBox(),
                  ),
                ),
                controller.value.isReady && _bottomUiVisible && !_initialLoad ?
                _buildModernBottomControls(height, width) :
                const SizedBox(height: 1),
                
                // Settings overlay
                if (_showSettings)
                  _buildSettingsOverlay(),
              ],
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
    final currentPos = controller.value.videoPosition ?? 0.0;
    final totalDuration = controller.value.videoDuration ?? 0.0;
    
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
                  controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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

  Widget _buildModernLoadingIndicator() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF01A4EA)),
          ),
        ),
      ),
    );
  }

  Widget _buildModernSeekIndicator({required int duration, required bool isForward}) {
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
                  width > 600 ? 20 : 16
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

  Widget _buildVimeoControlButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
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
              _seekingF = true;
            });
          },
          onChangeEnd: (end) {
            controller.seekTo(end.roundToDouble());
            setState(() {
              _seekingF = false;
            });
          },
          min: 0,
          max: controller.value.videoDuration != null ? controller.value.videoDuration! + 1.0 : 0.0,
          value: _position.clamp(0.0, controller.value.videoDuration ?? 0.0),
          onChanged: (value) {
            if (!_seekingF) {
              setState(() {
                _position = value;
              });
            }
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
          icon: controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          onTap: _onBottomPlayButton,
        ),
        SizedBox(width: isVerySmall ? 6 : (isTablet ? 16 : 12)),
        
        // Time display - always visible and prominent
        _buildVimeoTimeDisplay(),
        
        const Spacer(),
        
        // Volume controls - hide on mobile and very small screens
        if (!isMobile && !isVerySmall) ...[
          _buildVimeoControlButton(
            icon: _isMuted ? Icons.volume_off : (_volume > 0.5 ? Icons.volume_up : Icons.volume_down),
            onTap: () {
              setState(() {
                if (_isMuted) {
                  _isMuted = false;
                  _volume = 0.7;
                } else {
                  _isMuted = true;
                  _volume = 0.0;
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
            // Fullscreen functionality
          },
        ),
      ],
    );
  }

  Widget _buildSettingsOverlay() {
    if (_showSubmenu == 'quality') {
      return _buildQualitySubmenu();
    } else if (_showSubmenu == 'speed') {
      return _buildSpeedSubmenu();
    }
    
    return Positioned(
      right: 16,
      bottom: 80,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 180,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quality Option
              _buildSimpleSettingsOption(
                'Quality',
                _selectedQuality,
                () {
                  setState(() {
                    _showSubmenu = 'quality';
                  });
                },
              ),
              
              // Divider
              Container(
                height: 1,
                color: Colors.white.withOpacity(0.1),
              ),
              
              // Speed Option
              _buildSimpleSettingsOption(
                'Speed',
                _playbackSpeed == 1.0 ? 'Normal' : '${_playbackSpeed}x',
                () {
                  setState(() {
                    _showSubmenu = 'speed';
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleSettingsOption(String title, String currentValue, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Text(
              currentValue,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySubmenu() {
    final qualities = ['Auto', '1080p', '720p', '480p', '360p'];
    return Positioned(
      right: 16,
      bottom: 80,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
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
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Quality',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Quality options
              ...qualities.map((quality) => 
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedQuality = quality;
                      _showSubmenu = '';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          quality,
                          style: TextStyle(
                            color: _selectedQuality == quality ? const Color(0xFF01A4EA) : Colors.white,
                            fontSize: 13,
                            fontWeight: _selectedQuality == quality ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedQuality == quality)
                          const Icon(
                            Icons.check,
                            color: Color(0xFF01A4EA),
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedSubmenu() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    return Positioned(
      right: 16,
      bottom: 80,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.1),
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
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.white.withOpacity(0.8),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Speed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Speed options
              ...speeds.map((speed) => 
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _playbackSpeed = speed;
                      _showSubmenu = '';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          speed == 1.0 ? 'Normal' : '${speed}x',
                          style: TextStyle(
                            color: _playbackSpeed == speed ? const Color(0xFF01A4EA) : Colors.white,
                            fontSize: 13,
                            fontWeight: _playbackSpeed == speed ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        if (_playbackSpeed == speed)
                          const Icon(
                            Icons.check,
                            color: Color(0xFF01A4EA),
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}