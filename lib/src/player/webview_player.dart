import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:vimeo_player_package/src/controllers/vimeo_controller.dart';
import 'package:vimeo_player_package/src/models/vimeo_metadata.dart';

class WebViewPlayer extends StatefulWidget {
  @override
  final Key? key;
  final void Function(VimeoMetadata metaData)? onEnded;
  final bool isFullscreen;
  final bool portrait;

  const WebViewPlayer({
    this.key, 
    this.onEnded,
    this.isFullscreen = false,
    this.portrait = false,
  }) : super(key: key);

  @override
  _WebViewPlayerState createState() => _WebViewPlayerState();
}

class _WebViewPlayerState extends State<WebViewPlayer>
    with WidgetsBindingObserver {
  late VimeoPlayerController controller;
  final bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _width = WidgetsBinding
        .instance
        .platformDispatcher
        .views
        .first
        .physicalSize
        .width;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  double _width = 0.0;

  @override
  void didChangeMetrics() {
    setState(() {
      _width = WidgetsBinding
          .instance
          .platformDispatcher
          .views
          .first
          .physicalSize
          .width;
    });
  }

  @override
  Widget build(BuildContext context) {
    controller = VimeoPlayerController.of(context);
    return IgnorePointer(
      ignoring: true,
      child: InAppWebView(
        key: widget.key,
        initialData: InAppWebViewInitialData(
          data: player(_width),
          baseUrl: WebUri('https://www.vimeo.com'),
          encoding: 'utf-8',
          mimeType: 'text/html',
        ),
        initialSettings: InAppWebViewSettings(
          allowsInlineMediaPlayback: false,
          userAgent: userAgent,
          mediaPlaybackRequiresUserGesture: false,
          transparentBackground: true,
        ),
        onWebViewCreated: (webController) {
          controller.updateValue(
            controller.value.copyWith(webViewController: webController),
          );
          /* add js handlers */
          webController
            ..addJavaScriptHandler(
              handlerName: 'Ready',
              callback: (_) {
                print('player ready');
                if (!controller.value.isReady) {
                  controller.updateValue(
                    controller.value.copyWith(isReady: true),
                  );
                }
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'VideoPosition',
              callback: (params) {
                controller.updateValue(
                  controller.value.copyWith(
                    videoPosition: double.parse(params.first.toString()),
                  ),
                );
              },
            )
            ..addJavaScriptHandler(
              handlerName: 'VideoData',
              callback: (params) {
                //print('VideoData: ' + json.decode(params.first));
                controller.updateValue(
                  controller.value.copyWith(
                    videoTitle: params.first['title'].toString(),
                    videoDuration: double.parse(
                      params.first['duration'].toString(),
                    ),
                    videoWidth: double.parse(params.first['width'].toString()),
                    videoHeight: double.parse(
                      params.first['height'].toString(),
                    ),
                  ),
                );
              },
            )
             ..addJavaScriptHandler(
               handlerName: 'StateChange',
               callback: (params) {
                 switch (params.first) {
                  case -2:
                    controller.updateValue(
                      controller.value.copyWith(isBuffering: true),
                    );
                    break;
                  case -1:
                    controller.updateValue(
                      controller.value.copyWith(
                        isPlaying: false,
                        hasEnded: true,
                      ),
                    );
                    widget.onEnded?.call(
                      VimeoMetadata(
                        videoDuration: Duration(
                          seconds: controller.value.videoDuration?.round() ?? 0,
                        ),
                        videoId: controller.initialVideoId,
                        videoTitle: controller.value.videoTitle ?? '',
                      ),
                    );
                    break;
                  case 0:
                    controller.updateValue(
                      controller.value.copyWith(
                        isReady: true,
                        isBuffering: false,
                      ),
                    );
                    break;
                  case 1:
                    controller.updateValue(
                      controller.value.copyWith(isPlaying: false),
                    );
                    break;
                  case 2:
                    controller.updateValue(
                      controller.value.copyWith(isPlaying: true),
                    );
                    break;
                  default:
                    print('default player state');
                }
               },
             );
        },
        onLoadStop: (_, __) {
          if (_isPlayerReady) {
            controller.updateValue(controller.value.copyWith(isReady: true));
          }
        },
      ),
    );
  }

  String player(double width) {
    // Calculate dimensions based on fullscreen and portrait mode
    double? effectiveWidth;
    double? effectiveHeight;
    
    if (widget.isFullscreen) {
      final screenWidth = width;
      
      if (widget.portrait) {
        // For portrait videos, use a portrait aspect ratio (9:16)
        effectiveWidth = screenWidth * 0.8; // 80% of screen width
        effectiveHeight = effectiveWidth * (16.0 / 9.0); // 9:16 aspect ratio
      } else {
        // For landscape videos, use landscape aspect ratio (16:9)
        effectiveWidth = screenWidth * 0.9; // 90% of screen width
        effectiveHeight = effectiveWidth * (9.0 / 16.0); // 16:9 aspect ratio
      }
    } else {
      effectiveWidth = width;
      effectiveHeight = null;
    }
    
    var player =
        '''<html>
      <head>
      <style>
        html,
        body {
            margin: 0;
            padding: 0;
            background-color: #000000;
            overflow: hidden;
            position: fixed;
            height: 100%;
            width: 100%;
            pointer-events: none;
        }
        #vimeo_frame {
          height: 100%;
          width: 100%;
          display: flex;
          justify-content: center;
          align-items: center;
        }
        #vimeo_frame iframe {
          max-height: 100%;
          max-width: 100%;
          object-fit: contain;
          ${effectiveHeight != null ? 'height: ${effectiveHeight.toInt()}px;' : 'height: 100%;'}
          ${'width: ${effectiveWidth.toInt()}px;'}
        }
      </style>
      <meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>
      </head>
      <body>
        <div id="vimeo_frame"></div>
        <script src="https://player.vimeo.com/api/player.js"></script>
        <script>
        var tag = document.createElement('script');
        var firstScriptTag = document.getElementsByTagName('script')[0];
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
        var options = {
          id: ${controller.initialVideoId},
          title: true,
          transparent: true,
          autoplay: ${controller.flags.autoPlay},
          speed: true,
          controls: false,
          dnt: true${',\n          width: ${effectiveWidth.toInt()}'}${effectiveHeight != null ? ',\n          height: ${effectiveHeight.toInt()}' : ''}
        };
        
        var videoData = {};

        var vimPlayer = new Vimeo.Player('vimeo_frame', options);
        
        vimPlayer.getVideoTitle().then(function(title) {
          videoData['title'] = title;
        });
        
        vimPlayer.getVideoId().then(function(id) {
          videoData['id'] = id;
        });
        
        vimPlayer.getDuration().then(function(duration) {
          videoData['duration'] = duration;
        });

        vimPlayer.on('play', function(data) {
          sendPlayerStateChange(2);
        });

        vimPlayer.on('pause', function(data) {
          sendPlayerStateChange(1);
        });

        vimPlayer.on('bufferstart', function() {
          window.flutter_inappwebview.callHandler('StateChange', -2);
        });
        vimPlayer.on('bufferend', function() {
          window.flutter_inappwebview.callHandler('StateChange', 0);
        });
        
        vimPlayer.on('loaded', function(id) {
          window.flutter_inappwebview.callHandler('Ready');
          Promise.all([vimPlayer.getVideoTitle(), vimPlayer.getDuration()]).then(function(values) {
            videoData['title'] = values[0];
            videoData['duration'] = values[1];
          });
          Promise.all([vimPlayer.getVideoWidth(), vimPlayer.getVideoHeight()]).then(function(values) {
            videoData['width'] = values[0];
            videoData['height'] = values[1];
            window.flutter_inappwebview.callHandler('VideoData', videoData);
            console.log('vidData: ' + JSON.stringify(videoData));
          });
        });

        vimPlayer.on('ended', function(data) {
          window.flutter_inappwebview.callHandler('StateChange', -1);
        });

        vimPlayer.on('timeupdate', function(seconds) {
          window.flutter_inappwebview.callHandler('VideoPosition', seconds['seconds']);
        });
        
        function sendPlayerStateChange(playerState) {
          window.flutter_inappwebview.callHandler('StateChange', playerState);
        }
        
        function sendVideoData(videoData) {
          window.flutter_inappwebview.callHandler('VideoData', videoData);
        }

        function play() {
          vimPlayer.play();
        }

        function pause() {
          vimPlayer.pause();
        }

        function seekTo(delta) {
          console.log('Seeking to:', delta);
          if (videoData['duration'] > delta) {
            vimPlayer.setCurrentTime(delta).then(function(t) {
              console.log('Seek completed to:', t);
            }).catch(function(error) {
              console.log('Seek error:', error);
            });
          }
        }

        function reset() {
          vimPlayer.unload().then(function(value) {
            vimPlayer.loadVideo(${controller.initialVideoId})
          });
        }

        function setVolume(volume) {
          vimPlayer.setVolume(volume).then(function(volume) {
            console.log('Volume set to: ' + volume);
          }).catch(function(error) {
            console.log('Error setting volume: ' + error);
          });
        }

        function setQuality(quality) {
          if (quality === 'Auto') {
            // For auto quality, we don't set a specific quality
            console.log('Quality set to Auto');
            return;
          }
          
          // Map quality strings to Vimeo quality values
          var qualityMap = {
            '1080p': '1080p',
            '720p': '720p', 
            '480p': '540p', // Vimeo uses 540p instead of 480p
            '360p': '360p'
          };
          
          var vimeoQuality = qualityMap[quality];
          if (vimeoQuality) {
            vimPlayer.setQuality(vimeoQuality).then(function(quality) {
              console.log('Quality set to: ' + quality);
            }).catch(function(error) {
              console.log('Error setting quality: ' + error);
            });
          } else {
            console.log('Invalid quality: ' + quality);
          }
        }

        function setPlaybackRate(rate) {
          vimPlayer.setPlaybackRate(rate).then(function(playbackRate) {
            console.log('Playback rate set to: ' + playbackRate);
          }).catch(function(error) {
            console.log('Error setting playback rate: ' + error);
          });
        }
        </script>
      </body>
    </html>''';

    return player;
  }

  String boolean({required bool value}) => value ? "'1'" : "'0'";

  String get userAgent =>
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36';
}
