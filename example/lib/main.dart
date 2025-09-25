import 'package:flutter/material.dart';
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
  final double _height=300;
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
            // Video title is available via controller.value.videoTitle if needed
          });
        }
      });
    }
  }

  // Fullscreen logic is now handled internally by the package

  @override
  void dispose() {
    controller.removeListener(listener);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VimeoBuilder(
      player: VimeoPlayer(
        controller: controller,
        skipDuration: 10,
        portrait: false, // Set to true for portrait video, false for landscape
        onReady: () {
          setState(() {
            _playerReady = true;
          });
        },
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: Center(
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),
                SizedBox(height: _height, child: player),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
