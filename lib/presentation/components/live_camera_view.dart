import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/camera_image_converter.dart';
import 'face_detector_painter.dart';

/// Highly modular front camera live feed widget with real-time Google ML Kit face detection
/// and custom bounding box overlay.
///
/// Handles permissions, hardware lifecycle, stream processing, frame dropping,
/// and delegates detected faces to the provided callback for recognition/TFLite inference.
class LiveCameraView extends StatefulWidget {
  /// Preferred camera lens direction (defaults to front-facing for Kiosks).
  final CameraLensDirection initialDirection;

  /// Optional callback invoked on every detected frame when at least one face is present.
  /// Pass this to your downstream TensorFlow Lite face embedding model.
  /// Includes the [CameraDescription] so callers use the real sensor orientation.
  final void Function(Face dominantFace, CameraImage rawImage, CameraDescription camera)? onFaceDetected;

  /// Optional callback when all faces in a frame need to be inspected.
  final void Function(List<Face> faces, CameraImage rawImage)? onFacesDetected;

  /// Optional custom overlay child widget (e.g. custom kiosk guidelines, buttons).
  final Widget? overlay;

  /// Face detector performance mode (defaults to fast mode for real-time tracking).
  final FaceDetectorMode performanceMode;

  const LiveCameraView({
    super.key,
    this.initialDirection = CameraLensDirection.front,
    this.onFaceDetected,
    this.onFacesDetected,
    this.overlay,
    this.performanceMode = FaceDetectorMode.fast,
  });

  @override
  State<LiveCameraView> createState() => _LiveCameraViewState();
}

class _LiveCameraViewState extends State<LiveCameraView>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  late FaceDetector _faceDetector;

  bool _isCameraInitialized = false;
  bool _isPermissionGranted = false;
  bool _isProcessingFrame = false;
  String? _errorMessage;

  /// Throttle ML Kit face detection interval for smooth and responsive tracking
  static const int _minFrameIntervalMs = 60;
  DateTime _lastFrameTimestamp = DateTime(2000);

  List<Face> _faces = [];
  Size _imageSize = Size.zero;
  InputImageRotation _imageRotation = InputImageRotation.rotation0deg;
  CameraLensDirection _currentLensDirection = CameraLensDirection.front;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initFaceDetector();
    _checkPermissionAndInitCamera();
  }

  /// Configures ML Kit FaceDetector optimized for high-speed kiosk throughput and accurate capture.
  void _initFaceDetector() {
    final options = FaceDetectorOptions(
      performanceMode: widget.performanceMode,
      enableLandmarks: false,
      enableContours: false,
      enableClassification: false,
      enableTracking: true, // Assigns persistent tracking IDs across frames
      minFaceSize: 0.1,     // Sensitive to faces at regular distance
    );
    _faceDetector = FaceDetector(options: options);
  }

  /// Requests camera runtime permission and discovers available hardware lenses.
  Future<void> _checkPermissionAndInitCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      setState(() => _isPermissionGranted = true);
      await _initializeCamera();
    } else {
      setState(() {
        _isPermissionGranted = false;
        _errorMessage =
            'Camera permission is required for facial recognition attendance.';
      });
    }
  }

  /// Discovers cameras, selects preferred lens, and starts the image stream.
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _errorMessage = 'No camera devices found on this terminal.');
        return;
      }

      // Find front camera or fallback to first available
      final selectedCamera = _cameras.firstWhere(
        (c) => c.lensDirection == widget.initialDirection,
        orElse: () => _cameras.first,
      );

      _currentLensDirection = selectedCamera.lensDirection;

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium, // Balanced for 30fps ML Kit inference on mobile
        enableAudio: false,
        imageFormatGroup:
            defaultTargetPlatform == TargetPlatform.android
                ? ImageFormatGroup.nv21
                : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;

      // Start streaming frames to ML Kit
      await _cameraController!.startImageStream(_processFrame);

      setState(() {
        _isCameraInitialized = true;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to initialize camera: $e');
      }
    }
  }

  /// Processes each incoming camera stream frame without blocking the UI thread.
  Future<void> _processFrame(CameraImage cameraImage) async {
    if (_isProcessingFrame || !mounted || _cameraController == null) return;

    // Throttle: skip frames that arrive faster than ~8 fps.
    // ML Kit's internal face detection TFLite model triggers native
    // XNNPackDelegate logging on every processImage() call. Limiting to
    // ~8 fps drastically reduces log spam and GC pressure while keeping
    // face tracking responsive.
    final now = DateTime.now();
    if (now.difference(_lastFrameTimestamp).inMilliseconds < _minFrameIntervalMs) {
      return;
    }
    _lastFrameTimestamp = now;
    _isProcessingFrame = true;

    try {
      final camera = _cameraController!.description;
      final orientation =
          _cameraController!.value.deviceOrientation;

      final inputImage = CameraImageConverter.inputImageFromCameraImage(
        image: cameraImage,
        camera: camera,
        deviceOrientation: orientation,
      );

      if (inputImage == null || inputImage.metadata == null) {
        _isProcessingFrame = false;
        return;
      }

      // Execute ML Kit Face Detection
      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) {
        _isProcessingFrame = false;
        return;
      }

      // Filter and isolate ONLY the dominant foreground face (ignore background people)
      final dominantFace = _findDominantFace(faces);
      final List<Face> dominantFacesList =
          dominantFace != null ? [dominantFace] : [];

      // Update state for CustomPainter overlay with single dominant face
      setState(() {
        _faces = dominantFacesList;
        _imageSize = inputImage.metadata!.size;
        _imageRotation = inputImage.metadata!.rotation;
      });

      // Trigger user callbacks for downstream ML / TFLite processing ONLY on dominant face
      if (dominantFace != null) {
        widget.onFacesDetected?.call(dominantFacesList, cameraImage);
        widget.onFaceDetected?.call(dominantFace, cameraImage, camera);
      }
    } catch (e) {
      debugPrint('Face detection frame error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Identifies the largest face (closest foreground face) among detected candidates.
  Face? _findDominantFace(List<Face> faces) {
    if (faces.isEmpty) return null;
    if (faces.length == 1) return faces.first;

    Face dominant = faces.first;
    double maxArea = dominant.boundingBox.width * dominant.boundingBox.height;

    for (int i = 1; i < faces.length; i++) {
      final area = faces[i].boundingBox.width * faces[i].boundingBox.height;
      if (area > maxArea) {
        maxArea = area;
        dominant = faces[i];
      }
    }
    return dominant;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _stopAndDisposeCamera();
    } else if (state == AppLifecycleState.resumed && _isPermissionGranted) {
      _initializeCamera();
    }
  }

  /// Stops streaming and disposes camera resources cleanly and safely.
  Future<void> _stopAndDisposeCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      try {
        if (controller.value.isInitialized) {
          if (controller.value.isStreamingImages) {
            try {
              await controller.stopImageStream();
            } catch (e) {
              debugPrint('Error stopping image stream: $e');
            }
          }
          await controller.dispose();
        }
      } catch (e) {
        // Safely catch CameraX releaseFlutterSurfaceTexture IllegalStateException
        debugPrint('Safe camera disposal handled: $e');
      }
    }
    if (mounted) {
      setState(() => _isCameraInitialized = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAndDisposeCamera();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorView(_errorMessage!);
    }

    if (!_isPermissionGranted) {
      return _buildPermissionRequestView();
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return _buildLoadingView();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final double screenHeight = constraints.maxHeight;

        // In the camera plugin, aspectRatio is width / height in landscape (e.g. 4/3 or 16/9)
        // In portrait orientation, the visual aspect ratio is 1 / aspectRatio (e.g. 3/4 or 9/16)
        final double rawRatio = _cameraController!.value.aspectRatio;
        final double portraitRatio =
            rawRatio > 0 ? (1.0 / rawRatio) : (9.0 / 16.0);

        final double previewWidth = screenWidth;
        final double previewHeight = screenWidth / portraitRatio;

        return ClipRect(
          child: Container(
            width: screenWidth,
            height: screenHeight,
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                // 1. Camera Preview & FaceDetectorPainter rendered in unified aspect-ratio container
                FittedBox(
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: previewWidth,
                    height: previewHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_cameraController!),
                        CustomPaint(
                          painter: FaceDetectorPainter(
                            faces: _faces,
                            absoluteImageSize: _imageSize,
                            rotation: _imageRotation,
                            cameraLensDirection: _currentLensDirection,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. User-supplied overlay widgets
                if (widget.overlay != null) widget.overlay!,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
            ),
            SizedBox(height: 16),
            Text(
              'Initializing Camera Stream...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequestView() {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.orangeAccent),
            const SizedBox(height: 16),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please grant camera permission to enable face detection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: Colors.black,
              ),
              onPressed: _checkPermissionAndInitCamera,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00E676),
                side: const BorderSide(color: Color(0xFF00E676)),
              ),
              onPressed: _checkPermissionAndInitCamera,
              child: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
