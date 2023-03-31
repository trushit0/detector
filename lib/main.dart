import 'package:detector/screen_retriever.dart';
import 'package:detector/window_manager.dart';
import 'package:detector/device_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:preference_list/preference_list.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await enableAutoStartup();
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  launchAtStartup.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
  );


  await launchAtStartup.enable();
  bool isEnabled = await launchAtStartup.isEnabled();
  print("isEnabled => ${isEnabled}");
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
  });
  runApp(const MyApp());
}

Future<bool> enableAutoStartup() async {
  if (!Platform.isMacOS || kIsWeb) {
    return false;
  }

  final result = await Process.run(
    'osascript',
    [
      '-e',
      'tell application "System Events" to make new login item at end with properties {path:"/Applications/detector.app", hidden:false}'
    ],
    runInShell: true,
  );

  if (result.exitCode != 0) {
    return false;
  }

  return true;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PS DETECTOR',
      theme: ThemeData(
        primaryColor: const Color(0xff416ff4),
        canvasColor: Colors.white,
        scaffoldBackgroundColor: const Color(0xffF7F9FB),
        dividerColor: Colors.grey.withOpacity(0.3),
      ),
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isAccessAllowed = false;

  CapturedData? _lastCapturedData;
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    _isAccessAllowed = await ScreenCapturer.instance.isAccessAllowed();
    setState(() {});
  }

  void _handleClickCapture(CaptureMode mode) async {
    Directory directory = await getApplicationDocumentsDirectory();
    String imageName =
        'Screenshot-${DateTime.now().millisecondsSinceEpoch}.png';
    String imagePath =
        '${directory.path}/detector/screenshots/$imageName';
    _lastCapturedData = await ScreenCapturer.instance.capture(
      mode: mode,
      imagePath: imagePath,
      silent: true,
    );
    if (_lastCapturedData != null) {
    } else {
      if (kDebugMode) {
        print('User canceled capture');
      }
    }
    setState(() {});
  }

  Widget _buildBody(BuildContext context) {
    return PreferenceList(
      children: <Widget>[
        if (Platform.isMacOS)
          PreferenceListSection(
            children: [
              PreferenceListItem(
                title: const Text('isAccessAllowed'),
                accessoryView: Text('$_isAccessAllowed'),
                onTap: () async {
                  bool allowed =
                  await ScreenCapturer.instance.isAccessAllowed();
                  BotToast.showText(text: 'allowed: $allowed');
                  setState(() {
                    _isAccessAllowed = allowed;
                  });
                },
              ),
              PreferenceListItem(
                title: const Text('requestAccess'),
                onTap: () async {
                  await ScreenCapturer.instance.requestAccess();
                },
              ),
            ],
          ),
        PreferenceListSection(
          title: const Text('METHODS'),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: textEditingController,
                decoration: const InputDecoration(
                    labelText: "Enter Second"
                ),
              ),
            ),
            PreferenceListItem(
              title: const Text('capture'),
              accessoryView: Row(children: [
                CupertinoButton(
                  child: const Text('screen'),
                  onPressed: () {
                    Future.delayed(Duration(seconds: textEditingController.text.isNotEmpty ? int.parse(textEditingController.text) : 1) , () { _handleClickCapture(CaptureMode.screen);});
                  },
                ),
              ]),
            ),
          ],
        ),
        if (_lastCapturedData != null && _lastCapturedData?.imagePath != null)
          Container(
            margin: const EdgeInsets.only(top: 20),
            width: 400,
            height: 400,
            child: Image.file(
              File(_lastCapturedData!.imagePath!),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PS Detector'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "ScreenShot"),
              Tab(text: "Device Info"),
              Tab(text: "Window Manager"),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildBody(context),
            const DeviceInfo(),
            const CustomWindowManager(),
          ],
        ),
      ),
    );
  }


}
