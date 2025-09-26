import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:vimeo_player_package/vimeo_player_package.dart';

class VimeoPlayerValue {
  final bool isReady;
  final bool isPlaying;
  final bool isFullscreen;
  final bool isBuffering;
  final bool hasEnded;
  final String? videoTitle;
  final double? videoPosition;
  final double? videoDuration;
  final double? videoWidth;
  final double? videoHeight;
  final InAppWebViewController? webViewController;

  VimeoPlayerValue({
    this.isReady = false,
    this.isPlaying = false,
    this.isFullscreen = false,
    this.isBuffering = false,
    this.hasEnded = false,
    this.videoTitle,
    this.videoPosition,
    this.videoDuration,
    this.videoWidth,
    this.videoHeight,
    this.webViewController,
  });

  VimeoPlayerValue copyWith({
    bool? isReady,
    bool? isPlaying,
    bool? isFullscreen,
    bool? isBuffering,
    bool? hasEnded,
    String? videoTitle,
    double? videoPosition,
    double? videoDuration,
    double? videoWidth,
    double? videoHeight,
    InAppWebViewController? webViewController,
  }) {
    return VimeoPlayerValue(
      isReady: isReady ?? this.isReady,
      isPlaying: isPlaying ?? this.isPlaying,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isBuffering: isBuffering ?? this.isBuffering,
      hasEnded: hasEnded ?? this.hasEnded,
      videoTitle: videoTitle ?? this.videoTitle,
      videoDuration: videoDuration ?? this.videoDuration,
      videoWidth: videoWidth ?? this.videoWidth,
      videoHeight: videoHeight ?? this.videoHeight,
      videoPosition: videoPosition ?? this.videoPosition,
      webViewController: webViewController ?? this.webViewController,
    );
  }
}

class VimeoPlayerController extends ValueNotifier<VimeoPlayerValue> {
  final String? initialVideoId;
  final VimeoPlayerFlags flags;
  bool _isDisposed = false;
  final List<VoidCallback> _disposeCallbacks = [];

  VimeoPlayerController({
    this.initialVideoId,
    this.flags = const VimeoPlayerFlags(),
  }) : super(VimeoPlayerValue()) {
    // Validate video ID if provided
    if (initialVideoId != null && initialVideoId!.isEmpty) {
      throw ArgumentError('Video ID cannot be empty if provided');
    }
  }

  static VimeoPlayerController? of(BuildContext context) {
    final InheritedVimeoPlayer? inherited = context
        .dependOnInheritedWidgetOfExactType<InheritedVimeoPlayer>();
    return inherited?.controller;
  }

  static VimeoPlayerController ofRequired(BuildContext context) {
    final controller = of(context);
    if (controller == null) {
      throw FlutterError(
        'VimeoPlayerController not found in context. Make sure VimeoPlayer is properly initialized.',
      );
    }
    return controller;
  }

  void updateValue(VimeoPlayerValue newValue) {
    if (!_isDisposed) {
      value = newValue;
    }
  }

  void toggleFullscreenMode() {
    if (!_isDisposed) {
      updateValue(value.copyWith(isFullscreen: true));
    }
  }

  void reload() {
    if (!_isDisposed && value.webViewController != null) {
      value.webViewController!.reload();
    }
  }

  void play() => _callMethod('play()');
  void pause() => _callMethod('pause()');
  void seekTo(double delta) => _callMethod('seekTo($delta)');
  void reset() => _callMethod('reset()');
  void setVolume(double volume) => _callMethod('setVolume($volume)');
  void mute() => _callMethod('setVolume(0)');
  void unmute() => _callMethod('setVolume(1)');
  void setQuality(String quality) => _callMethod('setQuality("$quality")');
  void setPlaybackRate(double rate) => _callMethod('setPlaybackRate($rate)');

  void _callMethod(String methodString) {
    if (_isDisposed) return;

    if (value.isReady && value.webViewController != null) {
      try {
        value.webViewController!.evaluateJavascript(source: methodString);
      } catch (e) {
        print('Error calling method $methodString: $e');
      }
    } else {
      print('The controller is not ready for method calls.');
    }
  }

  /// Add a callback to be called when the controller is disposed
  void addDisposeCallback(VoidCallback callback) {
    if (!_isDisposed) {
      _disposeCallbacks.add(callback);
    }
  }

  /// Remove a dispose callback
  void removeDisposeCallback(VoidCallback callback) {
    _disposeCallbacks.remove(callback);
  }

  /// Check if the controller is disposed
  bool get isDisposed => _isDisposed;

  /// Check if the controller has a valid video ID
  bool get hasValidVideoId =>
      initialVideoId != null && initialVideoId!.isNotEmpty;

  /// Check if the controller is properly initialized and ready for use
  bool get isInitialized => hasValidVideoId && !_isDisposed;

  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;

    // Call all dispose callbacks
    for (final callback in _disposeCallbacks) {
      try {
        callback();
      } catch (e) {
        print('Error in dispose callback: $e');
      }
    }
    _disposeCallbacks.clear();

    // Clear web view controller reference
    if (value.webViewController != null) {
      value = value.copyWith(webViewController: null);
    }

    super.dispose();
  }
}

class InheritedVimeoPlayer extends InheritedWidget {
  final VimeoPlayerController controller;
  const InheritedVimeoPlayer({
    super.key,
    required this.controller,
    required super.child,
  });

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return oldWidget.hashCode != controller.hashCode;
  }
}
