import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';
import 'add_medicine_ocr.dart';

class AddMedicineScanScreen extends ConsumerStatefulWidget {
  const AddMedicineScanScreen({super.key});

  @override
  ConsumerState<AddMedicineScanScreen> createState() => _AddMedicineScanScreenState();
}

class _AddMedicineScanScreenState extends ConsumerState<AddMedicineScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerAnimationController;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _scannerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerAnimationController.dispose();
    super.dispose();
  }

  void _simulateScan(String type) {
    setState(() => _isScanning = false);

    // Simulated scanner success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text('Barcode detected: $type'),
          ],
        ),
        backgroundColor: const Color(0xFF0F766E),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;

      if (type == 'Paracetamol') {
        // Automatically add to cabinet (since barcode scans are 100% verified source)
        final newMed = Medicine(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Paracetamol 500mg',
          genericName: 'Acetaminophen',
          barcode: '8901043001815',
          batchNumber: 'PR-4402',
          expiryDate: DateTime.now().add(const Duration(days: 150)),
          addedDate: DateTime.now(),
          dosageForm: 'Tablet',
          verifiedSource: VerifiedSource.barcode,
        );

        ref.read(cabinetProvider.notifier).addMedicine(newMed);
        Navigator.pop(context); // Go back to cabinet
      } else {
        // Redirection to OCR/manual validation for other/unknown labels
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AddMedicineOcrScreen(
              mockImageName: 'Metformin label',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black, // Camera view is black background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Barcode Scanner',
          style: access.getTextStyle(
            baseSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Elderly toggle in header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: ElderlyModeToggle(
              access: access,
              value: isElderlyMode,
              onChanged: (val) {
                ref.read(elderlyModeProvider.notifier).toggle();
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Simulated camera preview background
          Container(
            height: size.height,
            width: size.width,
            color: Colors.grey.shade900,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Simulated Camera Viewfinder',
                    style: access.getTextStyle(
                      baseSize: 14.0,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scanning Overlay Box Guidelines
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: size.width * 0.75,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: Stack(
                    children: [
                      // Scanner red line animation
                      if (_isScanning)
                        AnimatedBuilder(
                          animation: _scannerAnimationController,
                          builder: (context, child) {
                            return Positioned(
                              top: 200 * _scannerAnimationController.value,
                              left: 8,
                              right: 8,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: access.alertRed,
                                  boxShadow: [
                                    BoxShadow(
                                      color: access.alertRed.withOpacity(0.8),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    'Align medicine package barcode inside the box',
                    textAlign: TextAlign.center,
                    style: access.getTextStyle(
                      baseSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Simulation Controls Tray (Overlay at bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(access.scaleSpacing(24.0)),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'SIMULATE SCAN OPTIONS',
                    textAlign: TextAlign.center,
                    style: access.getTextStyle(
                      baseSize: 11.0,
                      fontWeight: FontWeight.w900,
                      color: access.primaryTeal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Primary Action: Simulate scanner success on standard package
                  ElevatedButton.icon(
                    onPressed: _isScanning ? () => _simulateScan('Paracetamol') : null,
                    icon: Icon(Icons.qr_code_2_rounded, size: access.scaleText(20.0), color: Colors.white),
                    label: Text(
                      'Scan Paracetamol Barcode',
                      style: access.getTextStyle(
                        baseSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: access.primaryTeal,
                      foregroundColor: Colors.white,
                      minimumSize: Size(0, access.minTapTargetSize),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Alternative Action: Redirect to OCR Scanner fallback
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddMedicineOcrScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.document_scanner_outlined, size: access.scaleText(18.0), color: Colors.white),
                    label: Text(
                      'Barcode not scanning? Use OCR Scan',
                      style: access.getTextStyle(
                        baseSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                      minimumSize: Size(0, access.minTapTargetSize),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Non-dismissible disclaimer banner inside scanner
                  DisclaimerBanner(access: access),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
