import 'dart:async';
import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

class VideoCaptureScreen extends StatefulWidget {
  const VideoCaptureScreen({super.key});

  @override
  _VideoCaptureScreenState createState() => _VideoCaptureScreenState();
}

class _VideoCaptureScreenState extends State<VideoCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;

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
        fps: 30,
      );
      await _controller!.initialize();
      _controller?.getMinExposureOffset().then((value) {
        _minAvailableExposureOffset = value;
        setState(() {});
      });
      _controller?.getMaxExposureOffset().then((value) {
        _maxAvailableExposureOffset = value;
        setState(() {});
      });
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions not granted')));
    }
  }

  Future<void> _startVideoRecording() async {
    if (!_controller!.value.isInitialized) {
      return;
    }
    if (_controller!.value.isRecordingVideo) {
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
  final String outputPath = '$dirPath/converted_${DateTime.now().millisecondsSinceEpoch}.mp4';
  await videoFile.saveTo(filePath);

  var result = await FFmpegKit.executeAsync('-i $filePath -b:v 15M -filter:v fps=60 $outputPath');
  result.getAllLogs().then((logs) => print('FFmpeg process exited with rc ${result.getReturnCode()}. Logs: $logs'));
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
          Slider(
            value: _currentExposureOffset,
            min: _minAvailableExposureOffset,
            max: _maxAvailableExposureOffset,
            divisions: 100,
            onChanged: (value) async {
              setState(() {
                _currentExposureOffset = value;
              });
              await _controller!.setExposureOffset(value);
            },
          ),
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
        ],
      ),
    );
  }
}
