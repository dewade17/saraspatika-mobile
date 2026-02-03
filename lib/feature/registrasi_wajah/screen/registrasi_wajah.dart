import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:saraspatika/core/constants/colors.dart';

class RegistrasiWajah extends StatefulWidget {
  const RegistrasiWajah({super.key});

  @override
  State<RegistrasiWajah> createState() => _RegistrasiWajahState();
}

class _RegistrasiWajahState extends State<RegistrasiWajah> {
  CameraController? _cameraController;
  bool _isBusy = false;
  late FaceDetector _faceDetector;
  final FlutterTts _tts = FlutterTts();
  bool _isFaceInside = false;
  bool _hasGameStarted = false;
  String _debugInfo = "";

  // State Liveness
  int _currentStep = 0;
  final List<String> _steps = ["blink", "look_left", "look_right", "success"];
  String _instructionText = "Posisikan wajah di dalam oval";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeDetector();
    _setupTts();
  }

  // 1. Inisialisasi Detektor & Suara
  void _initializeDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true, // Untuk deteksi mata/senyum
        enableTracking: true,
      ),
    );
  }

  void _setupTts() async {
    await _tts.setLanguage("id-ID");
    await _tts.setPitch(1.0);
    _speak("Mohon posisikan wajah Anda");
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
    setState(() => _instructionText = text);
  }

  // 2. Inisialisasi Kamera
  void _initializeCamera() async {
    final cameras = await availableCameras();
    // Cari kamera depan
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
    setState(() {});
  }

  // 3. Logika Pemrosesan Frame (Liveness)
  // GANTI FUNGSI INI
  void _processCameraImage(CameraImage image) async {
    // 1. Cek apakah stream benar-benar jalan
    // debugPrint("Kamera mengirim frame: ${image.width}x${image.height}");
    // (Saya matikan dulu biar console gak penuh, nyalakan jika perlu)

    if (_isBusy) return;
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);

      if (inputImage == null) {
        // JIKA INI MUNCUL, BERARTI KONVERSI GAGAL
        debugPrint("!!! Gagal konversi gambar (InputImage is NULL) !!!");
      } else {
        final faces = await _faceDetector.processImage(inputImage);

        if (mounted) {
          setState(() {
            _isFaceInside = faces.isNotEmpty;
          });
        }

        if (faces.isNotEmpty) {
          final face = faces.first;

          if (!_hasGameStarted) {
            debugPrint(">>> WAJAH DITEMUKAN PERTAMA KALI! GAME MULAI <<<");
            _hasGameStarted = true;
            _speak("Wajah terdeteksi. Silakan berkedip sekarang.");
          }

          _checkLiveness(face);
        } else {
          debugPrint("--- Wajah tidak terlihat oleh AI ---");
        }
      }
    } catch (e) {
      debugPrint("Error FATAL di processImage: $e");
    } finally {
      _isBusy = false;
    }
  }

  // GANTI JUGA FUNGSI INI (VERSI DEBUG)
  void _checkLiveness(Face face) {
    // Ambil probabilitas mata (jika null, anggap 1.0 atau terbuka)
    double leftEye = face.leftEyeOpenProbability ?? 1.0;
    double rightEye = face.rightEyeOpenProbability ?? 1.0;
    double headY = face.headEulerAngleY ?? 0;

    // DEBUG: Pantau angka ini di VS Code/Android Studio
    debugPrint("Step: $_currentStep | Eye: $leftEye | HeadY: $headY");
    if (mounted) {
      setState(() {
        _debugInfo =
            "Mata: ${leftEye.toStringAsFixed(2)} | Kepala: ${headY.toStringAsFixed(0)}";
      });
    }
    if (_currentStep == 0) {
      // CEK KEDIP: Kita coba naikkan threshold ke 0.4 agar lebih mudah terdeteksi
      if (leftEye < 0.4 && rightEye < 0.4) {
        _currentStep = 1;
        _speak("Bagus! Sekarang toleh ke KIRI.");
      }
    } else if (_currentStep == 1) {
      // CEK TOLEH KIRI
      if (headY > 20) {
        _currentStep = 2;
        _speak("Oke, sekarang toleh ke KANAN.");
      }
    } else if (_currentStep == 2) {
      // CEK TOLEH KANAN
      if (headY < -20) {
        _currentStep = 3;
        _speak("Sempurna. Verifikasi berhasil.");
        _onSuccess();
      }
    }
  }

  void _onSuccess() {
    _cameraController?.stopImageStream();
    // Lanjutkan ke API Matching biometrik
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    // 1. Ambil Rotasi
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }

    if (rotation == null) return null;

    // 2. Tentukan Format (BAGIAN KRUSIAL)
    InputImageFormat? format;

    if (Platform.isAndroid) {
      // TRIK: Walaupun kamera ngasih Raw 35 (YUV420),
      // kita HARUS melabelinya sebagai NV21 agar ML Kit Native mau menerimanya.
      format = InputImageFormat.nv21;
    } else if (Platform.isIOS) {
      format = InputImageFormat.bgra8888;
    }

    if (format == null) return null;

    // 3. Pastikan Plane sesuai (Android 3 plane, iOS 1 plane)
    if (image.planes.length != 1 && image.planes.length != 3) return null;

    // 4. Bungkus ke InputImage
    // Perhatikan: bytesPerRow kita ambil dari plane Y (plane[0])
    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format, // Kita pakai NV21 di sini
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  // Fungsi pembantu untuk menggabungkan plane dengan benar
  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
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
          _buildHeader(), // Header baru
          _buildProgressBar(), // Progress bar baru
          _buildInstructionUI(), //
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      top: 110, // Di bawah header
      left: 40,
      right: 40,
      child: Row(
        children: List.generate(3, (index) {
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
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ]
                    : [],
              ),
            ),
          );
        }),
      ),
    );
  }

  // UI: Overlay Oval
  Widget _buildOverlay() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.5),
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
              height: 350,
              width: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                // Border akan berubah warna jika wajah terdeteksi
                border: Border.all(
                  color: _isFaceInside ? Colors.green : Colors.transparent,
                  width: 6,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.elliptical(280, 350),
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
      top: 50,
      left: 20,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              size: 28,
              color: AppColors.backgroundColor,
            ),
            style: IconButton.styleFrom(backgroundColor: Colors.black26),
          ),
          const SizedBox(width: 15),
          const Text(
            "Registrasi Wajah",
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

  Widget _buildInstructionUI() {
    return Positioned(
      bottom: 50,
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
                // Icon Dinamis berdasarkan step
                _buildStepIcon(),
                const SizedBox(height: 15),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _instructionText,
                    key: ValueKey(_instructionText),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
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

  // Icon kecil untuk membantu instruksi visual
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
      default:
        iconData = Icons.check_circle_outline_rounded;
    }
    return Icon(iconData, color: Colors.greenAccent, size: 40);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _tts.stop();
    super.dispose();
  }
}
