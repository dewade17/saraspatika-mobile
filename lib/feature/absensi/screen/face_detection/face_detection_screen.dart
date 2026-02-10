import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum _LivenessAction { blink, turnLeft, turnRight, lookCenter }

class FaceDetectionScreen extends StatefulWidget {
  const FaceDetectionScreen({super.key});

  @override
  State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  final FlutterTts _tts = FlutterTts();

  bool _isBusy = false;
  bool _isFaceInside = false;
  bool _verificationCompleted = false;
  bool _hasGameStarted = false;

  int _currentStep = 0;
  String _instructionText = "Posisikan wajah di dalam oval";

  List<_LivenessAction> _plan = const [];
  DateTime? _stepStartedAt;
  bool _eyesWereClosed = false;
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _initializeDetector();
    _initializeCamera();
    _setupTts();
  }

  void _initializeDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        enableLandmarks: true,
      ),
    );
  }

  void _setupTts() async {
    await _tts.setLanguage("id-ID");
    await _tts.setPitch(1.0);
    _speak("Mohon posisikan wajah Anda di dalam area oval");
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(
      frontCam,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController?.initialize();
    await _cameraController?.startImageStream(_processCameraImage);
    if (mounted) setState(() {});
  }

  void _processCameraImage(CameraImage image) async {
    if (_isBusy || _verificationCompleted) return;
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;
        if (mounted) setState(() => _isFaceInside = true);

        if (!_hasGameStarted) {
          _startLivenessSession();
        }

        _checkLiveness(face);
      } else {
        if (mounted) setState(() => _isFaceInside = false);
      }
    } catch (e) {
      debugPrint("Error deteksi: $e");
    } finally {
      _isBusy = false;
    }
  }

  List<_LivenessAction> _generatePlan() {
    final core = <_LivenessAction>[
      _LivenessAction.blink,
      _LivenessAction.turnLeft,
      _LivenessAction.turnRight,
    ];

    final int len = 4 + _rnd.nextInt(2);
    final plan = <_LivenessAction>[];

    while (plan.length < len) {
      plan.add(core[_rnd.nextInt(core.length)]);
    }

    if (!plan.contains(_LivenessAction.turnLeft)) {
      plan[_rnd.nextInt(plan.length)] = _LivenessAction.turnLeft;
    }
    if (!plan.contains(_LivenessAction.turnRight)) {
      plan[_rnd.nextInt(plan.length)] = _LivenessAction.turnRight;
    }

    plan.add(_LivenessAction.lookCenter);
    return plan;
  }

  String _instructionFor(_LivenessAction action) {
    switch (action) {
      case _LivenessAction.blink:
        return "Silakan berkedip sekarang.";
      case _LivenessAction.turnLeft:
        return "Sekarang toleh ke KIRI.";
      case _LivenessAction.turnRight:
        return "Sekarang toleh ke KANAN.";
      case _LivenessAction.lookCenter:
        return "Bagus, sekarang hadap ke depan kembali.";
    }
  }

  void _startLivenessSession() {
    _hasGameStarted = true;
    _plan = _generatePlan();
    _currentStep = 0;
    _stepStartedAt = DateTime.now();
    _eyesWereClosed = false;
    _speak("Wajah terdeteksi. ${_instructionFor(_plan[_currentStep])}");
  }

  void _advanceStep() {
    if (_verificationCompleted) return;

    _currentStep++;
    _stepStartedAt = DateTime.now();
    _eyesWereClosed = false;

    if (_currentStep >= _plan.length) {
      _speak("Sempurna. Verifikasi berhasil.");
      _onSuccess();
      return;
    }

    _speak(_instructionFor(_plan[_currentStep]));
  }

  void _checkLiveness(Face face) {
    if (_plan.isEmpty || _verificationCompleted) return;

    final startedAt = _stepStartedAt;
    if (startedAt != null) {
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed > const Duration(seconds: 7)) {
        _restartVerificationFlow(
          instruction:
              "Waktu habis. Silakan ulangi verifikasi dari awal dan ikuti instruksi dengan cepat.",
        );
        return;
      }
    }

    final double leftEye = face.leftEyeOpenProbability ?? 1.0;
    final double rightEye = face.rightEyeOpenProbability ?? 1.0;
    final double headY = face.headEulerAngleY ?? 0;

    final action = _plan[_currentStep];

    switch (action) {
      case _LivenessAction.blink:
        final bothClosed = leftEye < 0.35 && rightEye < 0.35;
        final bothOpen = leftEye > 0.70 && rightEye > 0.70;

        if (!_eyesWereClosed && bothClosed) {
          _eyesWereClosed = true;
          return;
        }

        if (_eyesWereClosed && bothOpen) {
          _advanceStep();
        }
        return;

      case _LivenessAction.turnLeft:
        if (headY > 20) _advanceStep();
        return;

      case _LivenessAction.turnRight:
        if (headY < -20) _advanceStep();
        return;

      case _LivenessAction.lookCenter:
        if (headY > -5 && headY < 5) _advanceStep();
        return;
    }
  }

  Future<void> _speak(String text) async {
    if (!mounted) return;
    setState(() => _instructionText = text);
    try {
      await _tts.stop();
    } catch (_) {}
    await _tts.speak(text);
  }

  void _onSuccess() async {
    if (_verificationCompleted) return;
    _verificationCompleted = true;

    try {
      await _cameraController?.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 300));

      final XFile photo = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Wajah tidak terdeteksi pada foto. Silakan ulangi verifikasi.',
            ),
          ),
        );

        await _restartVerificationFlow(
          instruction:
              'Wajah tidak terdeteksi pada foto. Silakan ulangi verifikasi dari awal.',
        );
        return;
      }

      if (!mounted) return;
      Navigator.pop(context, File(photo.path));
    } catch (e) {
      _verificationCompleted = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto verifikasi: $e')),
      );
    }
  }

  Future<void> _restartVerificationFlow({required String instruction}) async {
    _verificationCompleted = false;
    _hasGameStarted = false;
    _isFaceInside = false;
    _currentStep = 0;
    _plan = const [];
    _stepStartedAt = null;
    _eyesWereClosed = false;

    if (!mounted) return;
    setState(() => _instructionText = instruction);
    await _speak(instruction);

    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_cameraController!.value.isStreamingImages) {
      await _cameraController!.startImageStream(_processCameraImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          _buildOverlay(),
          _buildHeader(),
          _buildProgressBar(),
          _buildInstructionUI(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.6),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 380,
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: _isFaceInside ? Colors.greenAccent : Colors.white24,
                  width: 5,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.elliptical(300, 380),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 60,
      left: 20,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.black38),
          ),
          const SizedBox(width: 10),
          const Text(
            "Verifikasi Wajah",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final int steps = _plan.isEmpty ? 4 : _plan.length;
    final int current = _currentStep.clamp(0, steps);

    return Positioned(
      top: 130,
      left: 50,
      right: 50,
      child: Row(
        children: List.generate(steps, (index) {
          final bool isCompleted = index < current;
          final bool isCurrent = index == current;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.greenAccent
                    : (isCurrent ? Colors.white : Colors.white24),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInstructionUI() {
    return Positioned(
      bottom: 60,
      left: 30,
      right: 30,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStepIcon(),
                const SizedBox(height: 15),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _instructionText,
                    key: ValueKey(_instructionText),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIcon() {
    IconData iconData;

    if (_plan.isNotEmpty && _currentStep < _plan.length) {
      switch (_plan[_currentStep]) {
        case _LivenessAction.blink:
          iconData = Icons.remove_red_eye_outlined;
          break;
        case _LivenessAction.turnLeft:
          iconData = Icons.arrow_back_rounded;
          break;
        case _LivenessAction.turnRight:
          iconData = Icons.arrow_forward_rounded;
          break;
        case _LivenessAction.lookCenter:
          iconData = Icons.face_retouching_natural_rounded;
          break;
      }
    } else {
      switch (_currentStep) {
        case 0:
          iconData = Icons.remove_red_eye_outlined;
          break;
        case 1:
          iconData = Icons.arrow_back_rounded;
          break;
        case 2:
          iconData = Icons.arrow_forward_rounded;
          break;
        case 3:
          iconData = Icons.face_retouching_natural_rounded;
          break;
        default:
          iconData = Icons.check_circle_outline_rounded;
      }
    }

    return Icon(iconData, color: Colors.greenAccent, size: 40);
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final format = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _tts.stop();
    super.dispose();
  }
}
