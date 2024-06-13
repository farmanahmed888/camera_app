import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class VideoCaptureScreen extends StatefulWidget {
  const VideoCaptureScreen({super.key});

  @override
  _VideoCaptureScreenState createState() => _VideoCaptureScreenState();
}

class _VideoCaptureScreenState extends State<VideoCaptureScreen> {
  static const platform = MethodChannel('com.example.camera/shutterSpeed');
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _shutterSpeed = 500;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (await Permission.camera.request().isGranted &&
        await Permission.microphone.request().isGranted &&
        await Permission.storage.request().isGranted) {
      _cameras = await availableCameras();
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _controller!.initialize();
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions not granted')));
    }
  }

  Future<void> _setShutterSpeed(int speed) async {
    try {
      await platform.invokeMethod('setShutterSpeed', {'speed': speed});
    } on PlatformException catch (e) {
      print("Failed to set shutter speed: '${e.message}'.");
    }
  }

  Future<void> _startVideoRecording() async {
    if (!_controller!.value.isInitialized || _controller!.value.isRecordingVideo) {
      return;
    }

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } on CameraException catch (e) {
      print(e);
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_controller!.value.isRecordingVideo) {
      return;
    }

    try {
      final videoFile = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      _saveVideo(videoFile);
    } on CameraException catch (e) {
      print(e);
    }
  }

  Future<void> _saveVideo(XFile videoFile) async {
    final Directory? extDir = await getExternalStorageDirectory();
    final String dirPath = '${extDir!.path}/DCIM';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${DateTime.now().millisecondsSinceEpoch}.mp4';
    await videoFile.saveTo(filePath);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video saved to $filePath')));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Video Capture')),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                child: Icon(_isRecording ? Icons.stop : Icons.videocam),
                onPressed: () {
                  if (_isRecording) {
                    _stopVideoRecording();
                  } else {
                    _startVideoRecording();
                  }
                },
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 30,
            right: 30,
            child: Slider(
              value: _shutterSpeed.toDouble(),
              min: 1,
              max: 1000,
              divisions: 100,
              label: _shutterSpeed.toString(),
              onChanged: (value) {
                setState(() {
                  _shutterSpeed = value.toInt();
                });
                _setShutterSpeed(_shutterSpeed);
              },
            ),
          ),
        ],
      ),
    );
  }
}
