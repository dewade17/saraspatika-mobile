import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionScreen extends StatefulWidget {
  const FaceDetectionScreen({super.key});

  @override
  State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  // Kamera & Detektor
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  final FlutterTts _tts = FlutterTts();

  // State Kendali
  bool _isBusy = false;
  bool _isFaceInside = false;
  bool _verificationCompleted = false;
  int _currentStep = 0; // 0: Kedip, 1: Toleh Kiri, 2: Toleh Kanan, 3: Selesai
  String _instructionText = "Posisikan wajah Anda di dalam oval";

  @override
  void initState() {
    super.initState();
    _initializeDetector();
    _initializeCamera();
    _setupTts();
  }

  // --- 1. INISIALISASI ---

  void _initializeDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true, // Untuk deteksi mata
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
    _cameraController?.startImageStream(_processCameraImage);
    if (mounted) setState(() {});
  }

  // --- 2. LOGIKA DETEKSI (LIVENESS) ---

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

        // Jalankan logika pengecekan gerakan
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

  void _checkLiveness(Face face) {
    double leftEye = face.leftEyeOpenProbability ?? 1.0;
    double rightEye = face.rightEyeOpenProbability ?? 1.0;
    double headY = face.headEulerAngleY ?? 0; // Toleh Kiri/Kanan

    if (_currentStep == 0) {
      // Step: Kedipkan Mata
      if (_instructionText != "Silakan kedipkan mata Anda") {
        _speak("Silakan kedipkan mata Anda");
      }
      if (leftEye < 0.3 && rightEye < 0.3) {
        _nextStep("Bagus! Sekarang toleh ke KIRI");
      }
    } else if (_currentStep == 1) {
      // Step: Toleh Kiri
      if (headY > 25) {
        _nextStep("Oke, sekarang toleh ke KANAN");
      }
    } else if (_currentStep == 2) {
      // Step: Toleh Kanan
      if (headY < -25) {
        _verificationCompleted = true;
        _nextStep("Sempurna. Verifikasi berhasil");
        _onSuccess();
      }
    }
  }

  void _nextStep(String message) {
    setState(() => _currentStep++);
    _speak(message);
  }

  Future<void> _speak(String text) async {
    setState(() => _instructionText = text);
    await _tts.speak(text);
  }

  void _onSuccess() async {
    _cameraController?.stopImageStream();
    // Simulasi pengambilan gambar untuk matching biometrik
    final XFile file = await _cameraController!.takePicture();
    debugPrint("Gambar tersimpan di: ${file.path}");

    // Tampilkan dialog sukses atau pindah halaman
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Berhasil"),
          content: const Text("Data biometrik Anda telah terverifikasi."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  // --- 3. UI COMPONENTS ---

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
            child: Container(
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
    return Positioned(
      top: 130,
      left: 50,
      right: 50,
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? Colors.greenAccent
                    : Colors.white24,
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
                Text(
                  _instructionText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
    IconData icon = Icons.face;
    if (_currentStep == 0) icon = Icons.remove_red_eye;
    if (_currentStep == 1) icon = Icons.arrow_back;
    if (_currentStep == 2) icon = Icons.arrow_forward;
    if (_currentStep >= 3) icon = Icons.check_circle;
    return Icon(icon, color: Colors.greenAccent, size: 40);
  }

  // --- 4. HELPER CONVERSION ---

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation = InputImageRotationValue.fromRawValue(
      sensorOrientation,
    );
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
