import 'dart:async';
import 'dart:io';
import 'package:image/image.dart' as img;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/medicine_model.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';
import '../services/ocr_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    this.backendBaseUrl = const String.fromEnvironment(
      'BACKEND_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000', // Default to emulator loopback for Android
    ),
  });

  final String backendBaseUrl;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  final OcrService _ocrService = OcrService();
  final GlobalKey _previewKey = GlobalKey();

  late final ApiService _apiService;

  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _permissionMessage;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(baseUrl: widget.backendBaseUrl);
    _prepareCamera();
  }

  Future<void> _prepareCamera() async {
    debugPrint('CAMERA_SCREEN: _prepareCamera START');
    if (!mounted) {
      debugPrint('CAMERA_SCREEN: _prepareCamera ABORTED - not mounted');
      return;
    }
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _permissionMessage = null;
    });
    try {
      debugPrint('CAMERA_SCREEN: permission request start');
      final PermissionStatus permissionStatus = await Permission.camera.request();
      debugPrint('CAMERA_SCREEN: permission request done = $permissionStatus');
      if (!permissionStatus.isGranted) {
        if (!mounted) {
          debugPrint('CAMERA_SCREEN: permission denied, but widget unmounted');
          return;
        }
        setState(() {
          _permissionMessage = permissionStatus.isPermanentlyDenied
              ? 'Camera permission is permanently denied. Please enable it in Settings.'
              : 'Camera permission is required to scan medicine labels.';
        });
        return;
      }

      debugPrint('CAMERA_SCREEN: initialize camera start');
      await _cameraService.initialize();
      debugPrint('CAMERA_SCREEN: initialize camera done');
      debugPrint('CAMERA_SCREEN: set autofocus start');
      await _cameraService.setAutoFocus();
      debugPrint('CAMERA_SCREEN: set autofocus done');
      if (!mounted) {
        debugPrint('CAMERA_SCREEN: initialize finished, but widget unmounted');
        return;
      }
      setState(() {
        _isInitializing = false;
      });
      debugPrint('CAMERA_SCREEN: _prepareCamera COMPLETE');
    } catch (error) {
      debugPrint('CAMERA_SCREEN: _prepareCamera ERROR: $error');
      if (!mounted) {
        debugPrint('CAMERA_SCREEN: error occurred, but widget unmounted');
        return;
      }
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Unable to open camera: $error';
      });
    } finally {
      debugPrint('CAMERA_SCREEN: _prepareCamera FINALLY');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      } else {
        _isInitializing = false;
      }
    }
  }

  Future<void> _toggleFlash() async {
    try {
      debugPrint('CAMERA_SCREEN: toggle flash start');
      await _cameraService.toggleFlash();
      debugPrint('CAMERA_SCREEN: toggle flash done');
      if (!mounted) {
        return;
      }
      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Flash could not be changed: $error';
      });
    } finally {
      debugPrint('CAMERA_SCREEN: toggle flash finally');
    }
  }

  Future<void> _captureAndScan() async {
    debugPrint('CAMERA_SCREEN: _captureAndScan START');
    if (_isInitializing || _isProcessing) {
      debugPrint('CAMERA_SCREEN: _captureAndScan EXIT - busy');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      debugPrint('CAMERA_SCREEN: STEP 1 - capturePhoto start');
      final XFile capturedImage = await _cameraService.capturePhoto();
      debugPrint('CAMERA_SCREEN: STEP 1 - capturePhoto done path=${capturedImage.path}');

      final File imageFile = File(capturedImage.path);

      if (!mounted) return;

      File uploadFile = imageFile;
      bool wasCompressed = false;
      try {
        debugPrint('Compressing Captured Image in Background...');
        final bytes = await imageFile.readAsBytes();
        final compressedBytes = await compute(_compressImageBytes, bytes);
        
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(compressedBytes);
        uploadFile = tempFile;
        wasCompressed = true;
        debugPrint('Compression Done. Original: ${bytes.length} bytes, Compressed: ${compressedBytes.length} bytes');
      } catch (e) {
        debugPrint('Compression failed, falling back to original: $e');
      }

      debugPrint('Sending Image To Backend');
      final MedicineModel medicine =
          await _apiService.scanImage(uploadFile);

      // Clean up the temporary compressed file on device
      if (wasCompressed) {
        try {
          await uploadFile.delete();
        } catch (e) {
          debugPrint('Failed to delete temp compressed file: $e');
        }
      }

      if (!mounted) {
        debugPrint('CAMERA_SCREEN: success, but widget unmounted before pop');
        return;
      }

      debugPrint('CAMERA_SCREEN: Navigator.pop start');
      Navigator.of(context).pop<MedicineModel>(medicine);
      debugPrint('CAMERA_SCREEN: Navigator.pop done');
    } catch (error) {
      debugPrint('CAMERA_SCREEN: _captureAndScan ERROR: $error');
      if (!mounted) {
        debugPrint('CAMERA_SCREEN: error occurred, but widget unmounted');
        return;
      }
      setState(() {
        _errorMessage = 'Scan failed: $error';
      });
    } finally {
      debugPrint('CAMERA_SCREEN: _captureAndScan FINALLY');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      } else {
        _isProcessing = false;
        debugPrint('CAMERA_SCREEN: skip reset - widget unmounted');
      }
      debugPrint('CAMERA_SCREEN: _isProcessing reset to false');
    }
  }

  Future<void> _openSettings() async {
    try {
      debugPrint('CAMERA_SCREEN: open settings start');
      await openAppSettings();
      debugPrint('CAMERA_SCREEN: open settings done');
    } catch (error) {
      debugPrint('CAMERA_SCREEN: open settings ERROR: $error');
      rethrow;
    } finally {
      debugPrint('CAMERA_SCREEN: open settings finally');
    }
  }

  @override
  void dispose() {
    unawaited(_cameraService.dispose());
    unawaited(_ocrService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CameraController? controller = _cameraService.controller;
    final bool hasCamera = controller?.value.isInitialized ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF07111A),
      body: SafeArea(
        child: Stack(
          key: _previewKey,
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      const Color(0xFF0B1B2B),
                      const Color(0xFF07111A),
                      Colors.black.withOpacity(0.95),
                    ],
                  ),
                ),
              ),
            ),
            if (hasCamera)
              Positioned.fill(
                child: CameraPreview(controller!),
              )
            else
              const Positioned.fill(
                child: SizedBox.shrink(),
              ),
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.25),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _ScannerOverlayPainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: _isProcessing
                            ? null
                            : () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: Colors.white,
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                        child: IconButton(
                          onPressed: (_isInitializing ||
                                  _isProcessing ||
                                  !_cameraService.isFlashAvailable)
                              ? null
                              : _toggleFlash,
                          icon: Icon(
                            _cameraService.isFlashEnabled
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                          ),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.38),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.10),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Align the medicine label inside the frame',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Capture a clear photo to extract OCR text and send it to the MedSafe backend.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                        if (_errorMessage != null) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFFB4B4),
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                        if (_permissionMessage != null) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(
                            _permissionMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFFD6A5),
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _openSettings,
                            child: const Text('Open Settings'),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: 76,
                          height: 76,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: <Color>[
                                  Color(0xFF22C55E),
                                  Color(0xFF0EA5E9),
                                ],
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: const Color(0xFF0EA5E9).withOpacity(0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: (_isInitializing ||
                                      _isProcessing ||
                                      !hasCamera)
                                  ? null
                                  : _captureAndScan,
                              icon: _isProcessing
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.6,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isInitializing)
              Container(
                color: Colors.black.withOpacity(0.45),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint dimPaint = Paint()..color = Colors.black.withOpacity(0.42);
    final Paint framePaint = Paint()
      ..color = const Color(0xFF7DD3FC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final double frameWidth = size.width * 0.78;
    final double frameHeight = size.height * 0.28;
    final Rect frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: frameWidth,
      height: frameHeight,
    );

    final Path backgroundPath = Path()..addRect(Offset.zero & size);
    final Path holePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(frameRect, const Radius.circular(24)),
      );
    final Path overlayPath =
        Path.combine(PathOperation.difference, backgroundPath, holePath);
    canvas.drawPath(overlayPath, dimPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(24)),
      framePaint,
    );

    final Paint cornerPaint = Paint()
      ..color = const Color(0xFF22D3EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 28;

    void drawCorner(List<Offset> points) {
      final Path path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final Offset point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, cornerPaint);
    }

    drawCorner(<Offset>[
      frameRect.topLeft,
      Offset(frameRect.left + cornerLength, frameRect.top),
    ]);
    drawCorner(<Offset>[
      Offset(frameRect.right, frameRect.top),
      Offset(frameRect.right - cornerLength, frameRect.top),
    ]);
    drawCorner(<Offset>[
      Offset(frameRect.left, frameRect.bottom),
      Offset(frameRect.left + cornerLength, frameRect.bottom),
    ]);
    drawCorner(<Offset>[
      frameRect.bottomRight,
      Offset(frameRect.right - cornerLength, frameRect.bottom),
    ]);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

List<int> _compressImageBytes(List<int> bytes) {
  try {
    final image = img.decodeImage(Uint8List.fromList(bytes));
    if (image == null) return bytes;
    
    img.Image resized = image;
    if (image.width > 1200) {
      resized = img.copyResize(image, width: 1200);
    }
    
    return img.encodeJpg(resized, quality: 80);
  } catch (e) {
    debugPrint('Background compression exception: $e');
    return bytes;
  }
}
