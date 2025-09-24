import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vimeo_player_package/vimeo_player_package.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late VimeoPlayerController controller;
  bool _playerReady = false;
  String _videoTitle = 'Loading...';
  bool _isFullScreen = false;
  final double _height=300;
  double? _fullscreenWidth;
  double? _fullscreenHeight;
  final bool _isPortraitMode = false;
  @override
  void initState() {
    super.initState();

    controller = VimeoPlayerController(
      initialVideoId: '1003797907',
      flags: VimeoPlayerFlags(),
    )..addListener(listener);
  }

  void listener() async {
    if (_playerReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _videoTitle = controller.value.videoTitle ?? 'Unknown';
            _isFullScreen = controller.value.isFullscreen;
          });
        }
      });
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    
    if (_isFullScreen) {
      if(_isPortraitMode){
              // Set custom dimensions for portrait video in fullscreen
     // _setPortraitDimensions();
      
      // Force portrait orientation for fullscreen
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      // Hide system UI for immersive experience
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }else{
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
      // Update controller state
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
    // Update controller state
    controller.updateValue(controller.value.copyWith(isFullscreen: false));
  }

  @override
  void dispose() {
    controller.removeListener(listener);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isFullScreen) {
          _exitFullscreen();
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          if (_isFullScreen) {
            _exitFullscreen();
            return false; // Don't pop, just exit fullscreen
          }
          return true; // Allow normal pop
        },
        child: VimeoBuilder(
          player: VimeoPlayer(
            controller: controller,
            onScreenToggled: _toggleFullscreen,
            skipDuration: 10,
            portrait: _isPortraitMode, // Set to true for portrait video, false for landscape
            onReady: () {
              setState(() {
                _playerReady = true;
              });
            },
          ),
          builder: (context, player) {
            return Scaffold(
              appBar: _isFullScreen ? null : AppBar(title: Text(widget.title)),
              body: _isFullScreen 
                ? Container(
                    // Fullscreen container - takes entire screen
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                    child: player,
                  )
                : Center(
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                     
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(height: _height, child: player),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
            );
          },
        ),
      ),
    );
  }
}
