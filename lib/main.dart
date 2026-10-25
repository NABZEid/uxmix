import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'host_screen.dart';
import 'remote_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isHost = Platform.isWindows;
  if (!isHost) {
    // Android: remote selalu landscape, layar penuh
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  runApp(UxMixApp(isHost: isHost));
}

class UxMixApp extends StatelessWidget {
  final bool isHost;
  const UxMixApp({super.key, required this.isHost});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UxMix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF29D3FF),
      ),
      home: isHost ? const HostScreen() : const RemoteScreen(),
    );
  }
}
