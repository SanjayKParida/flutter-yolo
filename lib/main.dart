import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'package:ultralytics_yolo/yolo_task.dart';
import 'package:camera/camera.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOLO Object Detection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const YoloDemo(),
    );
  }
}

class YoloDemo extends StatefulWidget {
  const YoloDemo({super.key});

  @override
  State<YoloDemo> createState() => _YoloDemoState();
}

class _YoloDemoState extends State<YoloDemo> {
  final objectController = YoloViewController();
  final poseController = YoloViewController();
  List<String> detectedObjects = [];
  List<String> detectedPoses = [];
  CameraController? _cameraController;
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();
    objectController.setThresholds(
      confidenceThreshold: 0.5,
      iouThreshold: 0.45,
    );
    poseController.setThresholds(confidenceThreshold: 0.5, iouThreshold: 0.45);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _cameraController = CameraController(
        cameras![0],
        ResolutionPreset.medium,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void handleObjectDetection(List<dynamic> results) {
    print('Object detection results: ${results.length} objects');
    setState(() {
      detectedObjects =
          results
              .map(
                (result) =>
                    '${result.className ?? 'Unknown'} (${((result.confidence ?? 0) * 100).toStringAsFixed(1)}%)',
              )
              .toList();
    });
  }

  void handlePoseDetection(List<dynamic> results) {
    print('Pose detection results: ${results.length} poses');
    setState(() {
      detectedPoses =
          results
              .map(
                (result) =>
                    'Pose ${result.className ?? 'Unknown'} (${((result.confidence ?? 0) * 100).toStringAsFixed(1)}%)',
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('YOLO Object & Pose Detection')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Confidence: '),
                Slider(
                  value: 0.5,
                  min: 0.1,
                  max: 0.9,
                  onChanged: (value) {
                    objectController.setConfidenceThreshold(value);
                    poseController.setConfidenceThreshold(value);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                CameraPreview(_cameraController!),
                YoloView(
                  key: const ValueKey('pose'),
                  controller: poseController,
                  task: YOLOTask.pose,
                  modelPath: 'yolo11n-pose',
                  onResult: handlePoseDetection,
                ),
                YoloView(
                  key: const ValueKey('object'),
                  controller: objectController,
                  task: YOLOTask.detect,
                  modelPath: 'yolo11n',
                  onResult: handleObjectDetection,
                ),
                
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.black87,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detected Objects:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...detectedObjects.map(
                  (obj) =>
                      Text(obj, style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Detected Poses:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...detectedPoses.map(
                  (pose) =>
                      Text(pose, style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
