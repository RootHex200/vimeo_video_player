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
    setState(() {
      _isPlaying = controller.value.isPlaying;
      _isBuffering = controller.value.isBuffering;
    });
    if (controller.value.videoWidth != null && controller.value.videoHeight != null) {
      setState(() {
        _aspectRatio = (controller.value.videoWidth! / controller.value.videoHeight!);
      });
    }
    if (controller.value.videoPosition != null) {
      setState(() {
        _position = controller.value.videoPosition!;
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
    var position = _printDuration(Duration(seconds: (controller.value.videoPosition??0).round()));
    var duration = _printDuration(Duration(seconds: (controller.value.videoDuration??0).round()));

    return '$position/$duration';
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: _onPlay,
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40,
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
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                color: Colors.white.withOpacity(0.2),
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
        duration: const Duration(milliseconds: 400),
        opacity: _uiOpacity,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildModernControlButton(
                  icon: controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  onTap: _onBottomPlayButton,
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 10,
                  child: _buildModernProgressBar(),
                ),
                const SizedBox(width: 8),
                _buildModernTimeDisplay(),
                const SizedBox(width: 8),
                _buildModernControlButton(
                  icon: Icons.settings_rounded,
                  onTap: () {
                    // Settings functionality
                  },
                ),
                const SizedBox(width: 4),
                _buildModernControlButton(
                  icon: Icons.fullscreen_rounded,
                  onTap: () {
                    // Fullscreen functionality
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernControlButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildModernProgressBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
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
      ],
    );
  }

  Widget _buildModernTimeDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getTimestamp(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}