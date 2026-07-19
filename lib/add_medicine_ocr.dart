import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';

class AddMedicineOcrScreen extends ConsumerStatefulWidget {
  final String? mockImageName;

  const AddMedicineOcrScreen({super.key, this.mockImageName});

  @override
  ConsumerState<AddMedicineOcrScreen> createState() => _AddMedicineOcrScreenState();
}

class _AddMedicineOcrScreenState extends ConsumerState<AddMedicineOcrScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _genericController = TextEditingController();
  final _dosageController = TextEditingController();
  final _batchController = TextEditingController();
  final _expiryController = TextEditingController();

  bool _isProcessingImage = true;
  double _ocrConfidence = 0.89; // 89% confidence level simulation

  @override
  void initState() {
    super.initState();
    _simulateOcrProcessing();
  }

  void _simulateOcrProcessing() {
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _nameController.text = 'Metformin 500mg';
        _genericController.text = 'Metformin Hydrochloride';
        _dosageController.text = 'Tablet';
        _batchController.text = 'MF-22119';
        // Mock expiry date format: YYYY-MM-DD
        final futureDate = DateTime.now().add(const Duration(days: 45));
        _expiryController.text = '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';
        _isProcessingImage = false;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genericController.dispose();
    _dosageController.dispose();
    _batchController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Parse expiry date
    DateTime expiryDate;
    try {
      expiryDate = DateTime.parse(_expiryController.text);
    } catch (_) {
      // Default to 30 days if parse fails
      expiryDate = DateTime.now().add(const Duration(days: 30));
    }

    final newMed = Medicine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      genericName: _genericController.text.trim(),
      batchNumber: _batchController.text.trim().isEmpty ? null : _batchController.text.trim(),
      expiryDate: expiryDate,
      addedDate: DateTime.now(),
      dosageForm: _dosageController.text.trim(),
      verifiedSource: VerifiedSource.ocr,
    );

    // Save to provider
    ref.read(cabinetProvider.notifier).addMedicine(newMed);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newMed.name} successfully added to cabinet via OCR!'),
        backgroundColor: const Color(0xFF0F766E),
      ),
    );

    Navigator.pop(context); // Go back to cabinet
  }

  @override
  Widget build(BuildContext context) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);

    return Scaffold(
      backgroundColor: access.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: access.textColor,
        elevation: 0,
        title: Text(
          'OCR Photo Scan',
          style: access.getTextStyle(
            baseSize: 20.0,
            fontWeight: FontWeight.bold,
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
      body: Column(
        children: [
          // Shared Disclaimer Banner
          DisclaimerBanner(access: access),
          
          Expanded(
            child: _isProcessingImage
                ? _buildLoadingScreen(access)
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: access.scaleSpacing(20.0),
                      vertical: access.scaleSpacing(16.0),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // OCR Quality Indicator
                          _buildOcrStatusHeader(access),
                          const SizedBox(height: 24),

                          // Extracted Fields section
                          Text(
                            'Verify Extracted Details',
                            style: access.getTextStyle(
                              baseSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please correct any values that were misread. Tap the mic button to speak updates.',
                            style: access.getTextStyle(
                              baseSize: 13.0,
                              color: access.textColor.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Text fields with Voice Input capability
                          VoiceInputField(
                            access: access,
                            controller: _nameController,
                            labelText: 'Medicine Name',
                            icon: Icons.medication_rounded,
                            mockTranscript: 'Metformin 500mg',
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter medicine name' : null,
                          ),
                          const SizedBox(height: 16),

                          VoiceInputField(
                            access: access,
                            controller: _genericController,
                            labelText: 'Generic Name',
                            icon: Icons.science_outlined,
                            mockTranscript: 'Metformin Hydrochloride',
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter generic name' : null,
                          ),
                          const SizedBox(height: 16),

                          VoiceInputField(
                            access: access,
                            controller: _dosageController,
                            labelText: 'Dosage Form',
                            icon: Icons.layers_outlined,
                            mockTranscript: 'Tablet',
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter dosage form' : null,
                          ),
                          const SizedBox(height: 16),

                          VoiceInputField(
                            access: access,
                            controller: _batchController,
                            labelText: 'Batch Number (Optional)',
                            icon: Icons.pin_outlined,
                            mockTranscript: 'MF-22119',
                          ),
                          const SizedBox(height: 16),

                          // Expiry Date Field
                          TextFormField(
                            controller: _expiryController,
                            style: access.getTextStyle(baseSize: 15.0),
                            decoration: InputDecoration(
                              labelText: 'Expiry Date (YYYY-MM-DD)',
                              labelStyle: access.getTextStyle(
                                baseSize: 14.0,
                                color: access.textColor.withOpacity(0.6),
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_today_rounded,
                                color: access.textColor.withOpacity(0.6),
                                size: access.scaleText(20.0),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: access.textColor.withOpacity(0.08), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: access.primaryTeal, width: 2.0),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter expiry date';
                              try {
                                DateTime.parse(val.trim());
                              } catch (_) {
                                return 'Enter a valid date format (YYYY-MM-DD)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Action Buttons
                          ElevatedButton.icon(
                            onPressed: _submit,
                            icon: Icon(Icons.check_rounded, size: access.scaleText(20.0), color: Colors.white),
                            label: Text(
                              'Save Medicine to Cabinet',
                              style: access.getTextStyle(
                                baseSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: access.primaryTeal,
                              foregroundColor: Colors.white,
                              minimumSize: Size(0, access.minTapTargetSize),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: access.textColor.withOpacity(0.12)),
                              minimumSize: Size(0, access.minTapTargetSize),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              'Cancel',
                              style: access.getTextStyle(
                                baseSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: access.textColor.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen(AccessibilityConfig access) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF0F766E)),
            const SizedBox(height: 24),
            Text(
              'Analyzing Prescription Image...',
              textAlign: TextAlign.center,
              style: access.getTextStyle(
                baseSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Parsing text labels and matching drug profiles against openFDA...',
              textAlign: TextAlign.center,
              style: access.getTextStyle(
                baseSize: 14.0,
                color: access.textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOcrStatusHeader(AccessibilityConfig access) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: access.primaryTeal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: access.primaryTeal.withOpacity(0.12), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_rounded,
            color: access.primaryTeal,
            size: access.scaleText(24.0),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OCR Text Extraction Complete',
                  style: access.getTextStyle(
                    baseSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: access.primaryTeal,
                  ),
                ),
                Text(
                  'Confidence Score: ${(_ocrConfidence * 100).toStringAsFixed(0)}%',
                  style: access.getTextStyle(
                    baseSize: 12.0,
                    color: access.textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
