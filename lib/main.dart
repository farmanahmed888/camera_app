import 'package:flutter/material.dart';
import 'video_capture_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Video Capture',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const VideoCaptureScreen(),
    );
  }
}
