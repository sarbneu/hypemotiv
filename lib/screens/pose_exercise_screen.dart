/// Camera + ML Kit pose based jumping jack counter.
///
/// Frames come from the `camera` plugin, are converted to an
/// [InputImage] for Google ML Kit Pose Detection, and are sampled at roughly
/// 10 fps. A rep is counted on an arms-down -> arms-up transition while the
/// ankles are spread wider than the hips.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:hypemotiv/widgets/cyber_theme.dart';

/// Result sent back to the caller when the camera cannot be used
/// (missing permission or no camera). The caller falls back to the existing
/// accelerometer/manual `_ExerciseDialog`.
const int kPoseCameraUnavailable = -1;

/// Angle of the upper arm measured from straight down, using the shoulder and
/// elbow landmarks. In image coordinates (y grows downwards) a hanging arm is
/// close to 0 degrees and an arm raised overhead is close to 180 degrees.
double elbowArmAngle(PoseLandmark shoulder, PoseLandmark elbow) {
  final double dx = elbow.x - shoulder.x;
  final double dy = elbow.y - shoulder.y;
  final double length = math.sqrt(dx * dx + dy * dy);
  if (length < 1e-6) return 0;
  return math.acos((dy / length).clamp(-1.0, 1.0)) * 180 / math.pi;
}

/// 2D distance between two pose landmarks (z is noisy for this use case).
double landmarkDistance(PoseLandmark a, PoseLandmark b) {
  final double dx = a.x - b.x;
  final double dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}

/// Small pure state machine used by [PoseExerciseScreen].
///
/// A rep is only counted after an arms-down pose has been seen, so starting
/// the exercise with the arms already up does not award a free rep.
class JumpingJackCounter {
  JumpingJackCounter({
    this.downAngle = 50,
    this.upAngle = 100,
    this.spreadRatio = 1.4,
  });

  final double downAngle;
  final double upAngle;
  final double spreadRatio;

  int reps = 0;
  bool _sawDown = false;
  bool _armsUp = false;
  bool _legsSpread = false;

  bool get isArmsUp => _armsUp;
  bool get isArmsDown => _sawDown && !_armsUp;
  bool get isLegsSpread => _legsSpread;

  /// Feeds one frame of measurements. Returns true exactly when a rep was
  /// counted on this frame.
  bool update({
    required double leftElbowAngle,
    required double rightElbowAngle,
    required double legSpreadRatio,
  }) {
    _legsSpread = legSpreadRatio > spreadRatio;
    final bool bothDown =
        leftElbowAngle < downAngle && rightElbowAngle < downAngle;
    final bool bothUp = leftElbowAngle > upAngle && rightElbowAngle > upAngle;

    if (bothDown) {
      _sawDown = true;
      _armsUp = false;
      return false;
    }
    if (!bothUp) return false;

    final bool counted = !_armsUp && _sawDown && _legsSpread;
    _armsUp = true;
    if (counted) reps++;
    return counted;
  }

  void reset() {
    reps = 0;
    _sawDown = false;
    _armsUp = false;
    _legsSpread = false;
  }
}

class PoseExerciseScreen extends StatefulWidget {
  const PoseExerciseScreen({
    super.key,
    this.label = 'jumping jacks',
    this.targetReps = 20,
  });

  final String label;
  final int targetReps;

  @override
  State<PoseExerciseScreen> createState() => _PoseExerciseScreenState();
}

class _PoseExerciseScreenState extends State<PoseExerciseScreen> {
  static const int _frameIntervalMs = 100; // ~10 fps
  static const int _androidNv21 = 17;

  final JumpingJackCounter _counter = JumpingJackCounter();
  PoseDetector? _detector;
  CameraController? _controller;
  DateTime _lastProcessed = DateTime.fromMillisecondsSinceEpoch(0);
  bool _processing = false;
  bool _popped = false;
  bool _hasPose = false;
  double _leftAngle = 0;
  double _rightAngle = 0;
  double _spread = 0;
  String _status = 'Starting the camera...';

  @override
  void initState() {
    super.initState();
    _detector = PoseDetector(
      options: PoseDetectorOptions(
        model: PoseDetectionModel.base,
        mode: PoseDetectionMode.stream,
      ),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final List<CameraDescription> cameras = await availableCameras();
      final CameraDescription camera = cameras.firstWhere(
        (CameraDescription c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final CameraController controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      await controller.startImageStream(_onCameraImage);
      if (!mounted) return;
      setState(() => _status = 'Stand back so your whole body is visible');
    } catch (_) {
      // Permission denied or no camera: hand control back to the caller so it
      // can open the existing accelerometer/manual exercise dialog.
      if (!mounted || _popped) return;
      _popped = true;
      Navigator.of(context).pop<int>(kPoseCameraUnavailable);
    }
  }

  void _onCameraImage(CameraImage image) {
    if (_popped || _processing || _controller == null) return;
    final DateTime now = DateTime.now();
    if (now.difference(_lastProcessed).inMilliseconds < _frameIntervalMs) {
      return;
    }
    _lastProcessed = now;
    _processing = true;
    _analyze(image).whenComplete(() => _processing = false);
  }

  Future<void> _analyze(CameraImage image) async {
    final PoseDetector? detector = _detector;
    if (detector == null) return;
    try {
      final List<Pose> poses = await detector.processImage(
        _inputImageFromCamera(image),
      );
      if (_popped || !mounted) return;
      if (poses.isEmpty) {
        setState(() {
          _hasPose = false;
          _status = 'No pose yet — step into view';
        });
        return;
      }

      final Map<PoseLandmarkType, PoseLandmark> points = poses.first.landmarks;
      final PoseLandmark? leftShoulder = points[PoseLandmarkType.leftShoulder];
      final PoseLandmark? rightShoulder =
          points[PoseLandmarkType.rightShoulder];
      final PoseLandmark? leftElbow = points[PoseLandmarkType.leftElbow];
      final PoseLandmark? rightElbow = points[PoseLandmarkType.rightElbow];
      final PoseLandmark? leftHip = points[PoseLandmarkType.leftHip];
      final PoseLandmark? rightHip = points[PoseLandmarkType.rightHip];
      final PoseLandmark? leftAnkle = points[PoseLandmarkType.leftAnkle];
      final PoseLandmark? rightAnkle = points[PoseLandmarkType.rightAnkle];

      if (leftShoulder == null ||
          rightShoulder == null ||
          leftElbow == null ||
          rightElbow == null ||
          leftHip == null ||
          rightHip == null ||
          leftAnkle == null ||
          rightAnkle == null) {
        setState(() {
          _hasPose = false;
          _status = 'Move back so your arms and legs are fully in frame';
        });
        return;
      }

      final double leftAngle = elbowArmAngle(leftShoulder, leftElbow);
      final double rightAngle = elbowArmAngle(rightShoulder, rightElbow);
      final double ankleDistance = landmarkDistance(leftAnkle, rightAnkle);
      final double hipDistance = landmarkDistance(leftHip, rightHip);
      final double spread = hipDistance < 1e-6
          ? 0
          : ankleDistance / hipDistance;

      final bool counted = _counter.update(
        leftElbowAngle: leftAngle,
        rightElbowAngle: rightAngle,
        legSpreadRatio: spread,
      );
      setState(() {
        _hasPose = true;
        _leftAngle = leftAngle;
        _rightAngle = rightAngle;
        _spread = spread;
        _status = counted
            ? 'Rep $_countLabel counted!'
            : 'Arms ${_counter.isArmsUp ? 'up' : 'down'} · legs '
                  '${_counter.isLegsSpread ? 'spread' : 'together'}';
      });
      if (_counter.reps >= widget.targetReps) _finish();
    } catch (_) {
      // A single bad frame must not kill the exercise.
    }
  }

  String get _countLabel => '${_counter.reps}/${widget.targetReps}';

  void _finish() {
    if (_popped || !mounted) return;
    _popped = true;
    Navigator.of(context).pop<int>(_counter.reps);
  }

  InputImage _inputImageFromCamera(CameraImage image) {
    final Size size = Size(image.width.toDouble(), image.height.toDouble());
    final InputImageRotation rotation = _rotationFromSensor(
      _controller!.description.sensorOrientation,
    );

    if (!Platform.isAndroid || image.planes.length == 1) {
      final Plane plane = image.planes.first;
      final bool nv21 = Platform.isAndroid && image.format.raw == _androidNv21;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: size,
          rotation: rotation,
          format: nv21 ? InputImageFormat.nv21 : InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }

    // Android YUV_420_888 -> tightly packed YV12 (Y + V + U).
    final Uint8List y = _packedPlane(
      image.planes[0],
      image.width,
      image.height,
    );
    final int chromaWidth = image.width ~/ 2;
    final int chromaHeight = image.height ~/ 2;
    final Uint8List v = _packedPlane(
      image.planes[2],
      chromaWidth,
      chromaHeight,
    );
    final Uint8List u = _packedPlane(
      image.planes[1],
      chromaWidth,
      chromaHeight,
    );
    final Uint8List yv12 = Uint8List(y.length + v.length + u.length)
      ..setAll(0, y)
      ..setAll(y.length, v)
      ..setAll(y.length + v.length, u);
    return InputImage.fromBytes(
      bytes: yv12,
      metadata: InputImageMetadata(
        size: size,
        rotation: rotation,
        format: InputImageFormat.yv12,
        bytesPerRow: image.width,
      ),
    );
  }

  /// Removes row stride padding so ML Kit receives width-sized rows.
  static Uint8List _packedPlane(Plane plane, int width, int height) {
    final int stride = plane.bytesPerRow;
    if (stride == width && plane.bytes.length >= width * height) {
      return Uint8List.sublistView(plane.bytes, 0, width * height);
    }
    final Uint8List packed = Uint8List(width * height);
    for (int row = 0; row < height; row++) {
      final int from = row * stride;
      if (from >= plane.bytes.length) break;
      final int to = row * width;
      final int count = math.min(width, plane.bytes.length - from);
      for (int column = 0; column < count; column++) {
        packed[to + column] = plane.bytes[from + column];
      }
    }
    return packed;
  }

  static InputImageRotation _rotationFromSensor(int sensorOrientation) {
    return switch (sensorOrientation % 360) {
      90 => InputImageRotation.rotation90deg,
      180 => InputImageRotation.rotation180deg,
      270 => InputImageRotation.rotation270deg,
      _ => InputImageRotation.rotation0deg,
    };
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    final Future<void>? closing = _detector?.close();
    if (closing != null) unawaited(closing);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CameraController? controller = _controller;
    final double progress = (_counter.reps / widget.targetReps).clamp(0.0, 1.0);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.label} · pose counter'),
        backgroundColor: CyberTheme.panel,
        foregroundColor: CyberTheme.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CyberCard(
                glow: true,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SectionLabel(
                            'Live rep counter',
                            trailing: 'ML Kit pose',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_counter.reps} / ${widget.targetReps}',
                            style: const TextStyle(
                              color: Color(0xFF3D5AFE),
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(
                      _hasPose
                          ? (_counter.isArmsUp ? 'Arms up' : 'Arms down')
                          : 'Searching',
                      color: _counter.isLegsSpread
                          ? CyberTheme.cyan
                          : CyberTheme.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: CyberCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: controller == null || !controller.value.isInitialized
                        ? const Center(child: CircularProgressIndicator())
                        : Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width:
                                      controller.value.previewSize?.height ?? 1,
                                  height:
                                      controller.value.previewSize?.width ?? 1,
                                  child: CameraPreview(controller),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: CyberTheme.panel.withValues(
                                      alpha: 0.9,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      MicroText(
                                        _status,
                                        color: CyberTheme.white,
                                        fontSize: 13,
                                      ),
                                      const SizedBox(height: 4),
                                      MicroText(
                                        'Elbow angles L ${_leftAngle.round()}° '
                                        'R ${_rightAngle.round()}° · ankle/hip '
                                        '${_spread.toStringAsFixed(2)}×',
                                        color: CyberTheme.muted,
                                        fontSize: 12,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: CyberTheme.lime,
                backgroundColor: CyberTheme.line,
              ),
              const SizedBox(height: 14),
              MicroText(
                'Spread your legs, swing both arms overhead, then lower them. '
                'A rep counts when your arms go from down to up with your '
                'feet apart.',
                color: CyberTheme.muted,
                fontSize: 13,
              ),
              const SizedBox(height: 10),
              NeonButton(
                label: 'Finish · ${_counter.reps} reps',
                icon: Icons.check,
                onPressed: _finish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
