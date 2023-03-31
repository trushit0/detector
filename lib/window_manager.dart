import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CustomWindowManager extends StatefulWidget {
  const CustomWindowManager({Key? key}) : super(key: key);

  @override
  State<CustomWindowManager> createState() => _CustomWindowManagerState();
}

class _CustomWindowManagerState extends State<CustomWindowManager> with WindowListener {

  @override
  void initState() {
    windowManager.addListener(this);
    _init();
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _init() async {
    await windowManager.setPreventClose(false);
    await windowManager.setClosable(true);
    await windowManager.setSkipTaskbar(false);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text("Hide App"),
                onTap: () async {
                  await windowManager.setSkipTaskbar(true);
                  await windowManager.hide();
                  setState(() {});
                  Future.delayed(const Duration(seconds: 20),() async {
                    await windowManager.setSkipTaskbar(false);
                    await windowManager.show();
                    setState(() {});
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onWindowEvent(String eventName) {
    if (kDebugMode) {
      print('[WindowManager] onWindowEvent: $eventName');
    }
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Are you sure you want to close this window?'),
            actions: [
              TextButton(
                child: const Text('No'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () async {
                  // Navigator.of(context).pop();
                  // await windowManager.destroy();
                },
              ),
            ],
          );
        },
      );
    }
  }
}
