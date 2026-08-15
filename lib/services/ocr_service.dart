import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class OcrScanResult {
  const OcrScanResult({
    required this.horizontalText,
    required this.verticalText,
    required this.mergedText,
  });

  final String horizontalText;
  final String verticalText;
  final String mergedText;
}

class OcrService {
  OcrService()
      : _textRecognizer =
            TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _textRecognizer;

  Future<OcrScanResult> extractText(
    File imageFile, {
    required CameraController controller,
    required ui.Size previewSurfaceSize,
  }) async {
    debugPrint('OCR START');
    try {
      final _CropArtifacts cropArtifacts = await _cropCapturedImage(
        imageFile,
        controller: controller,
        previewSurfaceSize: previewSurfaceSize,
      );
      debugPrint('Crop Complete');

      final String horizontalText = await _recognizeText(cropArtifacts.file);
      debugPrint('Horizontal OCR Complete');

      final File rotatedFile = await _rotateCroppedImage(cropArtifacts.image);
      debugPrint('Rotation Complete');

      final String verticalText = await _recognizeText(rotatedFile);
      debugPrint('Vertical OCR Complete');

      // Fallback: Scan the FULL original image to capture anything missed by viewfinder crops
      String fullImageText = '';
      try {
        fullImageText = await _recognizeText(imageFile);
        debugPrint('Full Image OCR Complete');
      } catch (e) {
        debugPrint('OCR_SERVICE: Full image OCR failed, continuing: $e');
      }

      final String finalText =
          _mergeOcrText(horizontalText, verticalText);
      debugPrint('Text Cleaning Complete');

      // Combine cleaned results with all raw line inputs to give backend rich matching context
      final String mergedText = '$finalText\n$horizontalText\n$verticalText\n$fullImageText';

      return OcrScanResult(
        horizontalText: horizontalText,
        verticalText: verticalText,
        mergedText: mergedText,
      );
    } catch (error) {
      debugPrint('OCR_SERVICE: extractText ERROR: $error');
      rethrow;
    } finally {
      debugPrint('OCR_SERVICE: extractText FINALLY');
    }
  }

  Future<String> _recognizeText(File imageFile) async {
    final bool exists = await imageFile.exists();
    debugPrint('OCR_SERVICE: file exists=$exists path=${imageFile.path}');
    if (!exists) {
      throw Exception('Image file does not exist: ${imageFile.path}');
    }

    final int length = await imageFile.length();
    debugPrint('OCR_SERVICE: file length=$length');

    final InputImage inputImage = InputImage.fromFile(imageFile);
    debugPrint('OCR_SERVICE: InputImage.fromFile done');

    final RecognizedText recognizedText = await _textRecognizer
        .processImage(inputImage)
        .timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw Exception('OCR timed out while waiting for ML Kit.');
      },
    );
    debugPrint(
      'OCR_SERVICE: processImage done textLength=${recognizedText.text.length}',
    );
    return recognizedText.text.trim();
  }

  Future<_CropArtifacts> _cropCapturedImage(
    File imageFile, {
    required CameraController controller,
    required ui.Size previewSurfaceSize,
  }) async {
    final img.Image? decodedImage = await img.decodeImageFile(imageFile.path);
    if (decodedImage == null) {
      throw Exception('Unable to decode captured image.');
    }

    final img.Image bakedImage = img.bakeOrientation(decodedImage);
    debugPrint(
      'OCR_SERVICE: original image width=${bakedImage.width} height=${bakedImage.height}',
    );
    debugPrint(
      'OCR_SERVICE: preview width=${previewSurfaceSize.width} height=${previewSurfaceSize.height}',
    );

    final ui.Rect overlayRect = _overlayRect(previewSurfaceSize);
    final ui.Rect viewportRect =
        _previewViewportRect(previewSurfaceSize, controller);
    final ui.Rect imageCropRect =
        _mapOverlayToImageRect(overlayRect, viewportRect, bakedImage);

    debugPrint(
      'OCR_SERVICE: crop rect left=${imageCropRect.left} top=${imageCropRect.top} width=${imageCropRect.width} height=${imageCropRect.height}',
    );

    final int cropLeft = imageCropRect.left.floor().clamp(
          0,
          math.max(0, bakedImage.width - 1),
        ).toInt();
    final int cropTop = imageCropRect.top.floor().clamp(
          0,
          math.max(0, bakedImage.height - 1),
        ).toInt();
    final int cropWidth = imageCropRect.width.ceil().clamp(
          1,
          bakedImage.width - cropLeft,
        ).toInt();
    final int cropHeight = imageCropRect.height.ceil().clamp(
          1,
          bakedImage.height - cropTop,
        ).toInt();

    final img.Image croppedImage = img.copyCrop(
      bakedImage,
      x: cropLeft,
      y: cropTop,
      width: cropWidth,
      height: cropHeight,
    );
    debugPrint(
      'OCR_SERVICE: cropped image width=${croppedImage.width} height=${croppedImage.height}',
    );

    final Directory tempDirectory =
        await Directory.systemTemp.createTemp('medsafe_ocr_');
    final File croppedFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}cropped.png',
    );
    await croppedFile.writeAsBytes(
      img.encodePng(croppedImage),
      flush: true,
    );

    return _CropArtifacts(
      image: croppedImage,
      file: croppedFile,
    );
  }

  Future<File> _rotateCroppedImage(img.Image croppedImage) async {
    final img.Image rotatedImage = img.copyRotate(
      croppedImage,
      angle: 90,
    );

    final Directory tempDirectory =
        await Directory.systemTemp.createTemp('medsafe_ocr_rotated_');
    final File rotatedFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}rotated.png',
    );
    await rotatedFile.writeAsBytes(
      img.encodePng(rotatedImage),
      flush: true,
    );

    return rotatedFile;
  }

  ui.Rect _overlayRect(ui.Size surfaceSize) {
    final double frameWidth = surfaceSize.width * 0.78;
    final double frameHeight = surfaceSize.height * 0.28;
    return ui.Rect.fromCenter(
      center: ui.Offset(surfaceSize.width / 2, surfaceSize.height * 0.42),
      width: frameWidth,
      height: frameHeight,
    );
  }

  ui.Rect _previewViewportRect(
    ui.Size surfaceSize,
    CameraController controller,
  ) {
    final DeviceOrientation orientation = controller.value.deviceOrientation;
    final bool isLandscape =
        orientation == DeviceOrientation.landscapeLeft ||
            orientation == DeviceOrientation.landscapeRight;
    final double previewAspectRatio = isLandscape
        ? controller.value.aspectRatio
        : (1 / controller.value.aspectRatio);
    final double surfaceAspectRatio = surfaceSize.width / surfaceSize.height;

    if (surfaceAspectRatio > previewAspectRatio) {
      final double viewportWidth = surfaceSize.height * previewAspectRatio;
      return ui.Rect.fromLTWH(
        (surfaceSize.width - viewportWidth) / 2,
        0,
        viewportWidth,
        surfaceSize.height,
      );
    }

    final double viewportHeight = surfaceSize.width / previewAspectRatio;
    return ui.Rect.fromLTWH(
      0,
      (surfaceSize.height - viewportHeight) / 2,
      surfaceSize.width,
      viewportHeight,
    );
  }

  ui.Rect _mapOverlayToImageRect(
    ui.Rect overlayRect,
    ui.Rect viewportRect,
    img.Image image,
  ) {
    final ui.Rect visibleOverlayRect = overlayRect.intersect(viewportRect);
    if (visibleOverlayRect.isEmpty) {
      throw Exception('Overlay crop rectangle is empty.');
    }

    final double leftFraction =
        (visibleOverlayRect.left - viewportRect.left) / viewportRect.width;
    final double topFraction =
        (visibleOverlayRect.top - viewportRect.top) / viewportRect.height;
    final double widthFraction =
        visibleOverlayRect.width / viewportRect.width;
    final double heightFraction =
        visibleOverlayRect.height / viewportRect.height;

    return ui.Rect.fromLTWH(
      leftFraction * image.width,
      topFraction * image.height,
      widthFraction * image.width,
      heightFraction * image.height,
    );
  }

  String _mergeOcrText(
    String horizontalText,
    String verticalText,
  ) {
    final List<String> merged = [];
    final Set<String> seen = {};

    void add(String text) {
      for (String line in text.split(RegExp(r'\r?\n'))) {
        line = line.trim();

        if (line.isEmpty) continue;

        final upper = line.toUpperCase();

        if (seen.add(upper)) {
          merged.add(line);
        }
      }
    }

    add(horizontalText);
    add(verticalText);

    return _cleanText(merged);
  }

  String _cleanText(List<String> lines) {
    const blacklist = [
      "MANUFACTURED",
      "MARKETED",
      "ADDRESS",
      "INDUSTRIAL",
      "ESTATE",
      "LIMITED",
      "WARNING",
      "DOSAGE",
      "PHYSICIAN",
      "DOCTOR",
      "KEEP OUT",
      "CHILDREN",
      "STORE",
      "TEMPERATURE",
      "MOISTURE",
      "READ",
      "LEAFLET",
      "PRESCRIPTION",
      "NON STEROIDAL",
      "BRONCHOSPASM",
      "ASTHMA",
      "PATIENTS",
      "REACTION",
      "EXCIPIENTS",
      "COLOUR",
      "COLOURS",
      "SCAN",
      "INFO",
      "LIGHT",
      "TABLET SHOULD"
    ];

    final List<String> result = [];

    for (final original in lines) {
      final line = original.trim();

      if (line.isEmpty) continue;

      final upper = line.toUpperCase();

      bool reject = false;

      for (final word in blacklist) {
        if (upper.contains(word)) {
          reject = true;
          break;
        }
      }

      if (reject) continue;

      if (line.length > 45) continue;

      result.add(line);
    }

    result.sort(
      (a, b) => _scoreLine(b).compareTo(_scoreLine(a)),
    );

    return result.join("\n");
  }

  int _scoreLine(String line) {
    final upper = line.toUpperCase();

    int score = 0;

    if (RegExp(r'^[A-Z0-9\- ]+$').hasMatch(upper)) {
      score += 20;
    }

    if (upper.contains("TABLET")) score += 15;
    if (upper.contains("TABLETS")) score += 15;
    if (upper.contains("CAPSULE")) score += 15;
    if (upper.contains("SYRUP")) score += 15;
    if (upper.contains("INJECTION")) score += 15;

    if (upper.contains("MG")) score += 12;

    if (upper.contains("EXP")) score += 12;

    if (upper.contains("MFD")) score += 12;

    if (upper.contains("BATCH")) score += 12;

    if (upper.contains("B.NO")) score += 12;

    if (upper.contains("MRP")) score += 8;

    if (line.length < 25) score += 5;

    return score;
  }

  Future<void> dispose() async {
    debugPrint('OCR_SERVICE: dispose START');
    try {
      await _textRecognizer.close();
      debugPrint('OCR_SERVICE: dispose done');
    } catch (error) {
      debugPrint('OCR_SERVICE: dispose ERROR: $error');
      rethrow;
    } finally {
      debugPrint('OCR_SERVICE: dispose FINALLY');
    }
  }
}

class _CropArtifacts {
  const _CropArtifacts({
    required this.image,
    required this.file,
  });

  final img.Image image;
  final File file;
}
