import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'package:ultralytics_yolo/yolo_task.dart';

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
  final controller = YoloViewController();
  List<Map<String, dynamic>> objectResults = [];
  List<Map<String, dynamic>> poseResults = [];
  double confidenceThreshold = 0.5;
  double iouThreshold = 0.45;
  int _frameCounter = 0;
  bool _processingFrame = false;

  @override
  void initState() {
    super.initState();
    controller.setThresholds(
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold,
    );
  }

  void handleDetection(List<dynamic> results) async {
    if (_processingFrame || results.isEmpty) return;
    _processingFrame = true;
    _frameCounter++;

    // Store object detection results
    setState(() {
      objectResults = List<Map<String, dynamic>>.from(results);
    });

    // Process every 2nd frame with pose model for better performance
    if (_frameCounter % 2 == 0) {
      try {
        final yoloPose = YOLO(
          modelPath: 'yolo11n-pose',
          task: YOLOTask.pose,
        );

        // Set thresholds through controller
        final poseController = YoloViewController();
        poseController.setThresholds(
          confidenceThreshold: confidenceThreshold,
          iouThreshold: iouThreshold,
        );

        // Process with pose model
        final poseResult = await yoloPose.predict(results.first['annotatedImage']);
        setState(() {
          poseResults = [poseResult];
        });
      } catch (e) {
        print("Error processing pose detection: $e");
      }
    }

    _processingFrame = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOLO Object & Pose Detection'),
        backgroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // Settings Panel
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.black87,
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Confidence: ',
                        style: TextStyle(color: Colors.white)),
                    Expanded(
                      child: Slider(
                        value: confidenceThreshold,
                        min: 0.1,
                        max: 0.9,
                        onChanged: (value) {
                          setState(() {
                            confidenceThreshold = value;
                            controller.setConfidenceThreshold(value);
                          });
                        },
                      ),
                    ),
                    Text('${(confidenceThreshold * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),

          // Camera and Detection View
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Base YOLO View
                YoloView(
                  controller: controller,
                  task: YOLOTask.detect,
                  modelPath: 'yolo11n',
                  onResult: handleDetection,
                  showNativeUI: false,
                ),

                // Custom Paint for both models
                CustomPaint(
                  painter: DetectionPainter(
                    objectResults: objectResults,
                    poseResults: poseResults,
                  ),
                ),

                // Results Panel
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.black87.withOpacity(0.7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Objects:',
                                    style: TextStyle(
                                      color: Colors.yellow,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ...objectResults.map((result) {
                                    final detections = (result['detections'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                    return Column(
                                      children: detections.map((detection) {
                                        return Text(
                                          '${detection['className']}: ${(detection['confidence'] * 100).toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            color: Colors.yellow,
                                            fontSize: 12,
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Poses:',
                                    style: TextStyle(
                                      color: Colors.cyan,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ...poseResults.map((result) {
                                    final detections = (result['detections'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                                    return Column(
                                      children: detections.map((detection) {
                                        return Text(
                                          'Person: ${(detection['confidence'] * 100).toStringAsFixed(1)}%',
                                          style: const TextStyle(
                                            color: Colors.cyan,
                                            fontSize: 12,
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<Map<String, dynamic>> objectResults;
  final List<Map<String, dynamic>> poseResults;

  DetectionPainter({
    required this.objectResults,
    required this.poseResults,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final objectPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    // Draw object detection results
    for (final result in objectResults) {
      final detections = (result['detections'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final detection in detections) {
        final box = detection['boundingBox'] as Map<String, dynamic>;
        final rect = Rect.fromLTWH(
          (box['left'] as num).toDouble() * size.width,
          (box['top'] as num).toDouble() * size.height,
          ((box['right'] as num).toDouble() - (box['left'] as num).toDouble()) * size.width,
          ((box['bottom'] as num).toDouble() - (box['top'] as num).toDouble()) * size.height,
        );

        // Draw box
        canvas.drawRect(rect, objectPaint);

        // Draw label
        textPainter.text = TextSpan(
          text: ' ${detection['className']} ${(detection['confidence'] * 100).toStringAsFixed(0)}% ',
          style: const TextStyle(
            color: Colors.yellow,
            backgroundColor: Colors.black87,
            fontSize: 12,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(rect.left, rect.top - 15));
      }
    }

    // Draw pose detection results
    final posePaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final result in poseResults) {
      final detections = (result['detections'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final detection in detections) {
        final box = detection['boundingBox'] as Map<String, dynamic>;
        final rect = Rect.fromLTWH(
          (box['left'] as num).toDouble() * size.width,
          (box['top'] as num).toDouble() * size.height,
          ((box['right'] as num).toDouble() - (box['left'] as num).toDouble()) * size.width,
          ((box['bottom'] as num).toDouble() - (box['top'] as num).toDouble()) * size.height,
        );

        // Draw box
        canvas.drawRect(rect, posePaint);

        // Draw keypoints if available
        final keypoints = detection['keypoints'] as List?;
        if (keypoints != null) {
          for (final keypoint in keypoints) {
            final x = (keypoint['x'] as num).toDouble() * size.width;
            final y = (keypoint['y'] as num).toDouble() * size.height;

            canvas.drawCircle(
              Offset(x, y),
              3.0,
              Paint()..color = Colors.cyan,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(DetectionPainter oldDelegate) {
    return objectResults != oldDelegate.objectResults ||
        poseResults != oldDelegate.poseResults;
  }
}