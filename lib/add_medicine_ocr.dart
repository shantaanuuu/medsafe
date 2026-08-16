import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';
import 'models/medicine_model.dart';
import 'models/medication_schedule.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'services/api_service.dart';

class AddMedicineOcrScreen extends ConsumerStatefulWidget {
  final String? mockImageName;
  final MedicineModel? prefilledMedicine;

  const AddMedicineOcrScreen({
    super.key,
    this.mockImageName,
    this.prefilledMedicine,
  });

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
  final _substitutesController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _scheduleController = TextEditingController();

  bool _isProcessingImage = true;
  double _ocrConfidence = 0.89; // 89% confidence level simulation

  String _frequency = 'Once Daily';
  int _customTimesCount = 1;
  List<TimeOfDay> _doseTimes = [const TimeOfDay(hour: 9, minute: 0)];

  void _updateDoseTimesForFrequency(String freq) {
    setState(() {
      _frequency = freq;
      if (freq == 'Once Daily') {
        _doseTimes = [const TimeOfDay(hour: 9, minute: 0)];
      } else if (freq == 'Twice Daily') {
        _doseTimes = [
          const TimeOfDay(hour: 9, minute: 0),
          const TimeOfDay(hour: 21, minute: 0),
        ];
      } else if (freq == 'Three Times Daily') {
        _doseTimes = [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 14, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];
      } else if (freq == 'Four Times Daily') {
        _doseTimes = [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 12, minute: 0),
          const TimeOfDay(hour: 16, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ];
      } else if (freq == 'Custom') {
        _customTimesCount = _doseTimes.length;
        if (_customTimesCount == 0) {
          _customTimesCount = 1;
          _doseTimes = [const TimeOfDay(hour: 9, minute: 0)];
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.prefilledMedicine != null) {
      final med = widget.prefilledMedicine!;
      _nameController.text = med.brandName ?? '';
      _genericController.text = med.genericName ?? '';
      _dosageController.text = med.strength ?? 'Tablet';
      _batchController.text = med.batchNumber ?? '';
      _substitutesController.text = med.substitutes ?? '';
      
      // Parse expiry date format (ISO format, DD-MM-YYYY, MM/YY or MM/YYYY)
      String formattedExpiry = '';
      if (med.expiryDate != null) {
        final parsed = DateTime.tryParse(med.expiryDate!);
        if (parsed != null) {
          formattedExpiry = '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
        } else {
          final cleaned = med.expiryDate!.replaceAll(RegExp(r'[^0-9/-]'), '').trim();
          final parts = cleaned.split(RegExp(r'[/-]'));
          if (parts.length == 2) {
            final month = int.tryParse(parts[0]);
            final year = int.tryParse(parts[1]);
            if (month != null && year != null) {
              final fullYear = year < 100 ? 2000 + year : year;
              formattedExpiry = '$fullYear-${month.toString().padLeft(2, '0')}-01';
            }
          } else if (parts.length == 3) {
            final p0 = int.tryParse(parts[0]);
            final p1 = int.tryParse(parts[1]);
            final p2 = int.tryParse(parts[2]);
            if (p0 != null && p1 != null && p2 != null) {
              if (p0 > 1000) {
                formattedExpiry = '$p0-${p1.toString().padLeft(2, '0')}-${p2.toString().padLeft(2, '0')}';
              } else if (p2 > 1000) {
                formattedExpiry = '$p2-${p1.toString().padLeft(2, '0')}-${p0.toString().padLeft(2, '0')}';
              }
            }
          }
        }
      }
      
      if (formattedExpiry.isEmpty) {
        final futureDate = DateTime.now().add(const Duration(days: 90));
        formattedExpiry = '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';
      }
      
      _expiryController.text = formattedExpiry;
      _nicknameController.text = med.nickname ?? '';
      if (med.quantity != null) {
        _quantityController.text = med.quantity.toString();
      }
      _scheduleController.text = med.dosageSchedule ?? '';
      _isProcessingImage = false;
    } else {
      _simulateOcrProcessing();
    }
  }

  void _simulateOcrProcessing() {
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _nameController.text = 'Metformin 500mg';
        _genericController.text = 'Metformin Hydrochloride';
        _dosageController.text = 'Tablet';
        _batchController.text = 'MF-22119';
        _substitutesController.text = '';
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
    _substitutesController.dispose();
    _nicknameController.dispose();
    _quantityController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Parse expiry date
    DateTime expiryDate;
    try {
      expiryDate = DateTime.parse(_expiryController.text);
    } catch (_) {
      // Default to 30 days if parse fails
      expiryDate = DateTime.now().add(const Duration(days: 30));
    }

    final double? quantity = double.tryParse(_quantityController.text.trim());
    final newMed = Medicine(
      id: widget.prefilledMedicine?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      genericName: _genericController.text.trim(),
      batchNumber: _batchController.text.trim().isEmpty ? null : _batchController.text.trim(),
      expiryDate: expiryDate,
      addedDate: DateTime.now(),
      dosageForm: _dosageController.text.trim(),
      verifiedSource: widget.prefilledMedicine?.verifiedSource != null
          ? VerifiedSource.values[widget.prefilledMedicine!.verifiedSource!]
          : VerifiedSource.ocr,
      price: widget.prefilledMedicine?.mrp != null ? double.tryParse(widget.prefilledMedicine!.mrp!) : null,
      manufacturer: widget.prefilledMedicine?.manufacturer,
      sideEffects: widget.prefilledMedicine?.sideEffects,
      drugInteractions: widget.prefilledMedicine?.drugInteractions,
      medicineDesc: widget.prefilledMedicine?.medicineDesc,
      substitutes: _substitutesController.text.trim().isEmpty ? null : _substitutesController.text.trim(),
      chemicalClass: widget.prefilledMedicine?.chemicalClass,
      therapeuticClass: widget.prefilledMedicine?.therapeuticClass,
      habitForming: widget.prefilledMedicine?.habitForming,
      nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
      quantity: quantity,
      dosageSchedule: '${_doseTimes.length} times/day',
    );

    // Save to provider (awaits database sync)
    await ref.read(cabinetProvider.notifier).addMedicine(newMed);

    // Save the MedicationSchedule to database
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final activeProfile = ref.read(activeProfileProvider);
      final caregiverProfile = ref.read(onboardingProfileProvider).value;
      final String? dependentId = (activeProfile != null && caregiverProfile != null && activeProfile.id != caregiverProfile.id)
          ? activeProfile.id
          : null;

      final List<String> formattedTimes = _doseTimes.map((t) {
        final hr = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
        final min = t.minute.toString().padLeft(2, '0');
        final period = t.period == DayPeriod.am ? 'AM' : 'PM';
        return '${hr.toString().padLeft(2, '0')}:$min $period';
      }).toList();

      final schedule = MedicationSchedule(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cabinetItemId: newMed.id,
        dependentId: dependentId,
        userUid: user.uid,
        frequencyPerDay: _doseTimes.length,
        scheduledTimes: formattedTimes,
      );

      await ref.read(apiServiceProvider).saveSchedule(schedule);
      ref.invalidate(schedulesProvider);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newMed.name} successfully added to cabinet!'),
          backgroundColor: const Color(0xFF2563EB),
        ),
      );
      Navigator.pop(context); // Go back to cabinet
    }
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
                            labelText: 'Generic Name (Optional)',
                            icon: Icons.science_outlined,
                            mockTranscript: 'Metformin Hydrochloride',
                          ),
                          const SizedBox(height: 16),

                          VoiceInputField(
                            access: access,
                            controller: _substitutesController,
                            labelText: 'Alternative Substitutes (Optional)',
                            icon: Icons.swap_horiz_rounded,
                            mockTranscript: 'Obimet 500, Glycomet 500',
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
                            readOnly: true,
                            onTap: () async {
                              DateTime parsedInitial = DateTime.now().add(const Duration(days: 90));
                              final existingText = _expiryController.text.trim();
                              if (existingText.isNotEmpty) {
                                final parsed = DateTime.tryParse(existingText);
                                if (parsed != null) {
                                  parsedInitial = parsed;
                                }
                              }
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: parsedInitial,
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                              );
                              if (picked != null) {
                                setState(() {
                                  _expiryController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                });
                              }
                            },
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
                          const SizedBox(height: 16),

                          VoiceInputField(
                            access: access,
                            controller: _nicknameController,
                            labelText: 'Medicine Nickname (Optional)',
                            icon: Icons.bookmark_border_rounded,
                            mockTranscript: 'Morning BP Pill',
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            style: access.getTextStyle(baseSize: 15.0),
                            decoration: InputDecoration(
                              labelText: 'Quantity / Pack Size (Optional)',
                              labelStyle: access.getTextStyle(
                                baseSize: 14.0,
                                color: access.textColor.withOpacity(0.6),
                              ),
                              prefixIcon: Icon(
                                Icons.numbers_rounded,
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
                          ),
                          const SizedBox(height: 16),

                          // Interactive Medication Schedule Section
                          const SizedBox(height: 24),
                          Text(
                            'Medication Schedule',
                            style: access.getTextStyle(
                              baseSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Specify how often and at what times this medicine should be taken.',
                            style: access.getTextStyle(
                              baseSize: 13.0,
                              color: access.textColor.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Frequency Dropdown
                          DropdownButtonFormField<String>(
                            value: _frequency,
                            dropdownColor: Colors.white,
                            style: access.getTextStyle(baseSize: 15.0),
                            decoration: InputDecoration(
                              labelText: 'Frequency',
                              labelStyle: access.getTextStyle(
                                baseSize: 14.0,
                                color: access.textColor.withOpacity(0.6),
                              ),
                              prefixIcon: Icon(
                                Icons.repeat_rounded,
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
                            items: [
                              'Once Daily',
                              'Twice Daily',
                              'Three Times Daily',
                              'Four Times Daily',
                              'Custom',
                            ].map((f) {
                              return DropdownMenuItem<String>(
                                value: f,
                                child: Text(f, style: access.getTextStyle(baseSize: 15.0)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                _updateDoseTimesForFrequency(val);
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Custom count selector if Custom is selected
                          if (_frequency == 'Custom') ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Number of doses per day:',
                                  style: access.getTextStyle(baseSize: 15.0, fontWeight: FontWeight.w500),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: _customTimesCount > 1
                                          ? () {
                                              setState(() {
                                                _customTimesCount--;
                                                _doseTimes.removeLast();
                                              });
                                            }
                                          : null,
                                    ),
                                    Text(
                                      '$_customTimesCount',
                                      style: access.getTextStyle(baseSize: 16.0, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: _customTimesCount < 12
                                          ? () {
                                              setState(() {
                                                _customTimesCount++;
                                                _doseTimes.add(const TimeOfDay(hour: 9, minute: 0));
                                              });
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Dose time list pickers
                          ...List.generate(_doseTimes.length, (index) {
                            final time = _doseTimes[index];
                            final hr = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
                            final min = time.minute.toString().padLeft(2, '0');
                            final period = time.period == DayPeriod.am ? 'AM' : 'PM';
                            final formattedTime = '${hr.toString().padLeft(2, '0')}:$min $period';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: time,
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _doseTimes[index] = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: access.textColor.withOpacity(0.08), width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.access_time_rounded, color: access.primaryTeal),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Dose ${index + 1}',
                                            style: access.getTextStyle(baseSize: 15.0, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            formattedTime,
                                            style: access.getTextStyle(baseSize: 15.0, fontWeight: FontWeight.bold, color: access.primaryTeal),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.arrow_drop_down, color: access.textColor.withOpacity(0.5)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
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
            const CircularProgressIndicator(color: Color(0xFF2563EB)),
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
