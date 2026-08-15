import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraController? _controller;
  bool _flashEnabled = false;

  CameraController? get controller => _controller;

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  bool get isFlashEnabled => _flashEnabled;

  bool get isFlashAvailable => isInitialized;

  Future<void> initialize() async {
    debugPrint('CAMERA_SERVICE: initialize START');

    final List<CameraDescription> cameras = await availableCameras();

    if (cameras.isEmpty) {
      throw Exception('No camera found.');
    }

    final CameraDescription camera = cameras.firstWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();

    try {
      await _controller!.setFocusMode(FocusMode.auto);
    } catch (e) {
      debugPrint('Focus mode not supported: $e');
    }

    try {
      await _controller!.setExposureMode(ExposureMode.auto);
    } catch (e) {
      debugPrint('Exposure mode not supported: $e');
    }

    try {
      await _controller!.setFlashMode(FlashMode.off);
    } catch (e) {
      debugPrint('Flash mode error: $e');
    }

    debugPrint('CAMERA_SERVICE: initialize DONE');
  }

  Future<XFile> capturePhoto() async {
    final CameraController? controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      throw Exception('Camera is not ready.');
    }

    if (controller.value.isTakingPicture) {
      throw Exception('Camera is already taking a picture.');
    }

    debugPrint('CAMERA_SERVICE: takePicture START');

    final XFile picture = await controller.takePicture();

    debugPrint(
      'CAMERA_SERVICE: takePicture DONE path=${picture.path}',
    );

    return picture;
  }

  Future<void> toggleFlash() async {
    final CameraController? controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    _flashEnabled = !_flashEnabled;

    await controller.setFlashMode(
      _flashEnabled ? FlashMode.torch : FlashMode.off,
    );
  }

  Future<void> setAutoFocus() async {
    final CameraController? controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      await controller.setFocusMode(FocusMode.auto);
    } catch (e) {
      debugPrint('Autofocus error: $e');
    }
  }

  Future<void> dispose() async {
    debugPrint('CAMERA_SERVICE: dispose');

    final CameraController? controller = _controller;

    _controller = null;

    if (controller != null) {
      await controller.dispose();
    }
  }
}
