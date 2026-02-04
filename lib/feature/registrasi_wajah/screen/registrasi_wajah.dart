import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/feature/absensi/data/provider/enroll_face_provider.dart';
import 'package:saraspatika/feature/login/data/provider/auth_provider.dart';

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

  // Guard supaya _onSuccess() tidak terpanggil berkali-kali
  bool _enrollTriggered = false;

  // State Liveness
  int _currentStep = 0;
  final List<String> _steps = [
    "blink",
    "look_left",
    "look_right",
    "face_forward",
    "face_forward",
    "success",
  ];
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
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() {});
  }

  // 3. Logika Pemrosesan Frame (Liveness)
  void _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);

      if (inputImage == null) {
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

  void _checkLiveness(Face face) {
    double leftEye = face.leftEyeOpenProbability ?? 1.0;
    double rightEye = face.rightEyeOpenProbability ?? 1.0;
    double headY = face.headEulerAngleY ?? 0;

    debugPrint("Step: $_currentStep | Eye: $leftEye | HeadY: $headY");

    if (mounted) {
      setState(() {
        _debugInfo =
            "Mata: ${leftEye.toStringAsFixed(2)} | Kepala: ${headY.toStringAsFixed(0)}";
      });
    }

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
      // Toleransi posisi depan biasanya di antara -5 sampai 5 derajat
      if (headY > -5 && headY < 5) {
        _currentStep = 4; // Step sukses
        _speak("Sempurna. Verifikasi berhasil.");
        _onSuccess(); // Foto diambil saat wajah sudah di tengah
      }
    }
  }

  Future<void> _onSuccess() async {
    if (_enrollTriggered) return;
    _enrollTriggered = true;

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kamera belum siap.')));
      }
      _enrollTriggered = false;
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final enrollProvider = context.read<EnrollFaceProvider>();

    try {
      // Stop stream dulu (takePicture tidak bisa saat image stream aktif)
      try {
        await controller.stopImageStream();
      } catch (_) {
        // ignore: jika stream sudah berhenti
      }

      final XFile shot = await controller.takePicture();
      final Uint8List bytes = await shot.readAsBytes();
      final String fileName = shot.name.isNotEmpty
          ? shot.name
          : shot.path.split(Platform.pathSeparator).last;

      final String userId = (authProvider.me?.idUser ?? '').trim();
      if (userId.isEmpty) {
        throw StateError('User ID tidak ditemukan. Silakan login ulang.');
      }

      await enrollProvider.enrollFace(
        userId: userId,
        images: [bytes],
        filenames: [fileName],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi wajah berhasil.')),
      );

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/home-screen', (route) => false);
    } catch (e) {
      if (!mounted) return;

      final msg = enrollProvider.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg ?? 'Gagal registrasi wajah: $e')),
      );

      // Allow retry: restart liveness flow
      _enrollTriggered = false;
      _currentStep = 0;
      _hasGameStarted = false;
      _isFaceInside = false;

      // Restart stream so existing liveness logic keeps working
      try {
        await controller.startImageStream(_processCameraImage);
      } catch (err) {
        debugPrint('Gagal restart image stream: $err');
      }
    }
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
          _buildHeader(),
          _buildProgressBar(),
          _buildInstructionUI(),

          // Loading overlay (di atas semuanya)
          Consumer<EnrollFaceProvider>(
            builder: (context, p, _) {
              if (!p.isLoading) return const SizedBox.shrink();
              return Positioned.fill(
                child: AbsorbPointer(
                  absorbing: true,
                  child: Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      top: 110,
      left: 40,
      right: 40,
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
