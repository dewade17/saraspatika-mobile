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
  int _currentStep = 0;
  final List<String> _steps = [
    "blink",
    "look_left",
    "look_right",
    "face_forward",
    "success",
  ];
  String _instructionText = "Posisikan wajah di dalam oval";

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
    double headY = face.headEulerAngleY ?? 0; // Sudut horizontal kepala

    if (_currentStep == 0) {
      if (leftEye < 0.4 && rightEye < 0.4) {
        _currentStep = 1;
        _speak("Bagus! Sekarang toleh ke KIRI.");
      }
    } else if (_currentStep == 1) {
      if (headY > 20) {
        _currentStep = 2;
        _speak("Oke, sekarang toleh ke KANAN.");
      }
    } else if (_currentStep == 2) {
      if (headY < -20) {
        _currentStep = 3; // Pindah ke step menunggu posisi tengah
        _speak("Bagus, sekarang hadap ke depan kembali.");
      }
    } else if (_currentStep == 3) {
      // Menunggu wajah kembali ke posisi depan (toleransi -5 sampai 5 derajat)
      if (headY > -5 && headY < 5) {
        _currentStep = 4; // Step sukses
        _speak("Sempurna. Verifikasi berhasil.");
        _onSuccess(); // Foto diambil saat wajah sudah lurus ke depan
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
        children: List.generate(4, (index) {
          bool isCompleted = index < _currentStep;
          bool isCurrent = index == _currentStep;
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
    IconData iconData;
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
        break; // Icon hadap depan
      default:
        iconData = Icons.check_circle_outline_rounded;
    }
    return Icon(iconData, color: Colors.greenAccent, size: 40);
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
