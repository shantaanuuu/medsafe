import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';
import 'dosage_calculator.dart';
import 'risk_profiler.dart';
import 'models/medicine_model.dart';

class MedicineDetailScreen extends ConsumerWidget {
  final Medicine medicine;

  const MedicineDetailScreen({super.key, required this.medicine});

  // Helper method to look up mock interactions for a specific medicine
  List<Map<String, String>> _getMockInteractions(List<Medicine> cabinet) {
    final List<Map<String, String>> interactions = [];
    final otherMeds = cabinet.where((m) => m.id != medicine.id).toList();

    for (var other in otherMeds) {
      if (medicine.name.contains('Paracetamol') && other.name.contains('Metformin')) {
        interactions.add({
          'otherMed': other.name,
          'severity': 'monitor',
          'description': 'Concomitant use may alter glycemic control. Monitor blood glucose closely.',
        });
      } else if (medicine.name.contains('Metformin') && other.name.contains('Paracetamol')) {
        interactions.add({
          'otherMed': other.name,
          'severity': 'monitor',
          'description': 'Concomitant use may alter glycemic control. Monitor blood glucose closely.',
        });
      }
    }
    return interactions;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final cabinet = ref.watch(cabinetProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);
    
    final interactions = _getMockInteractions(cabinet);

    // Dynamic Source Icon and Label
    IconData sourceIcon;
    String sourceText;
    switch (medicine.verifiedSource) {
      case VerifiedSource.barcode:
        sourceIcon = Icons.qr_code_scanner_rounded;
        sourceText = 'Barcode Scanner (100% Verified)';
        break;
      case VerifiedSource.ocr:
        sourceIcon = Icons.document_scanner_outlined;
        sourceText = 'Prescription OCR (Verified)';
        break;
      case VerifiedSource.manual:
      default:
        sourceIcon = Icons.edit_note_rounded;
        sourceText = 'Manual Entry (Unverified)';
        break;
    }

    return Scaffold(
      backgroundColor: access.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: access.textColor,
        elevation: 0,
        title: Text(
          'Medicine Profile',
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
          // Non-dismissible disclaimer at the top
          DisclaimerBanner(access: access),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: access.scaleSpacing(20.0),
                vertical: access.scaleSpacing(20.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Medicine Header Information Card
                  _buildHeaderCard(context, ref, access, sourceIcon, sourceText),
                  const SizedBox(height: 24),

                  // 2. Drug Interaction Status
                  Text(
                    'Cabinet Interactions',
                    style: access.getTextStyle(
                      baseSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (interactions.isEmpty)
                    _buildNoInteractionsCard(access)
                  else
                    ...interactions.map((inter) => _buildInteractionTile(inter, access)),

                  const SizedBox(height: 24),

                  // 3. Clinical Guidelines & Info (mocked from FDA labels)
                  Text(
                    'Clinical Information',
                    style: access.getTextStyle(
                      baseSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildClinicalInfoCard(access),
                  const SizedBox(height: 20),

                  // Dosage Calculator Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DosageCalculatorScreen(medicine: medicine),
                        ),
                      );
                    },
                    icon: Icon(Icons.calculate_outlined, size: access.scaleText(20.0), color: Colors.white),
                    label: Text(
                      'Check Safe Dosage Range',
                      style: access.getTextStyle(
                        baseSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: access.primaryTeal,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, access.minTapTargetSize),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Side Effect Profiler Button
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SideEffectProfilerScreen(medicine: medicine),
                        ),
                      );
                    },
                    icon: Icon(Icons.analytics_outlined, size: access.scaleText(18.0), color: access.primaryTeal),
                    label: Text(
                      'Side Effect Risk Profile (FAERS)',
                      style: access.getTextStyle(
                        baseSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: access.primaryTeal,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: access.primaryTeal, width: 1.5),
                      minimumSize: Size(double.infinity, access.minTapTargetSize),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // 4. Action triggers
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(cabinetProvider.notifier).removeMedicine(medicine.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${medicine.name} removed from cabinet.'),
                          backgroundColor: access.textColor,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.delete_outline_rounded, color: access.alertRed),
                    label: Text(
                      'Remove from Cabinet',
                      style: access.getTextStyle(
                        baseSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: access.alertRed,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: access.alertRed.withOpacity(0.5), width: 1.5),
                      minimumSize: Size(double.infinity, access.minTapTargetSize),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    WidgetRef ref,
    AccessibilityConfig access,
    IconData sourceIcon,
    String sourceText,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(access.scaleSpacing(20.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: access.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: access.pastelBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: access.primaryBlue,
                  size: access.scaleText(32.0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (medicine.nickname != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: access.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          medicine.nickname!.toUpperCase(),
                          style: access.getTextStyle(
                            baseSize: 11.0,
                            fontWeight: FontWeight.bold,
                            color: access.primaryTeal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      medicine.name,
                      style: access.getTextStyle(
                        baseSize: 22.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medicine.genericName,
                      style: access.getTextStyle(
                        baseSize: 15.0,
                        color: access.textColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Metadata Grid
          _buildMetaRow('Formulation', medicine.dosageForm, access),
          const SizedBox(height: 10),
          if (medicine.nickname != null) ...[
            _buildMetaRow('Nickname', medicine.nickname!, access),
            const SizedBox(height: 10),
          ],
          if (medicine.quantity != null) ...[
            _buildMetaRow('Quantity', '${medicine.quantity!.toStringAsFixed(0)} units', access),
            const SizedBox(height: 10),
          ],
          if (medicine.dosageSchedule != null) ...[
            _buildMetaRow('Schedule', medicine.dosageSchedule!, access),
            const SizedBox(height: 10),
          ],
          if (medicine.batchNumber != null) ...[
            _buildMetaRow('Batch Code', medicine.batchNumber!, access),
            const SizedBox(height: 10),
          ],
          // Expiry Date Row with Edit Pen Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expiry Date',
                style: access.getTextStyle(
                  baseSize: 14.0,
                  color: access.textColor.withOpacity(0.5),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${medicine.expiryDate.year}-${medicine.expiryDate.month.toString().padLeft(2, '0')}-${medicine.expiryDate.day.toString().padLeft(2, '0')}',
                    style: access.getTextStyle(
                      baseSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: medicine.expiryDate.difference(DateTime.now()).inDays <= 30
                          ? access.alertRed
                          : access.textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.edit_rounded, size: 18, color: access.primaryTeal),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: medicine.expiryDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        _updateExpiryDate(context, ref, picked, access);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Source Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Source Status',
                style: access.getTextStyle(
                  baseSize: 14.0,
                  color: access.textColor.withOpacity(0.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: access.primaryTeal.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(sourceIcon, size: access.scaleText(14.0), color: access.primaryTeal),
                    const SizedBox(width: 6),
                    Text(
                      sourceText,
                      style: access.getTextStyle(
                        baseSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: access.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateExpiryDate(
    BuildContext context,
    WidgetRef ref,
    DateTime newDate,
    AccessibilityConfig access,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Updating expiry date...')),
    );

    try {
      final newMedicine = Medicine(
        id: medicine.id,
        name: medicine.name,
        genericName: medicine.genericName,
        batchNumber: medicine.batchNumber,
        expiryDate: newDate,
        addedDate: medicine.addedDate,
        dosageForm: medicine.dosageForm,
        verifiedSource: medicine.verifiedSource,
        price: medicine.price,
        manufacturer: medicine.manufacturer,
        sideEffects: medicine.sideEffects,
        drugInteractions: medicine.drugInteractions,
        medicineDesc: medicine.medicineDesc,
        substitutes: medicine.substitutes,
        chemicalClass: medicine.chemicalClass,
        therapeuticClass: medicine.therapeuticClass,
        habitForming: medicine.habitForming,
        nickname: medicine.nickname,
        quantity: medicine.quantity,
        dosageSchedule: medicine.dosageSchedule,
      );

      await ref.read(cabinetProvider.notifier).addMedicine(newMedicine);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expiry date updated successfully!'),
            backgroundColor: const Color(0xFF2563EB),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update expiry date: $e'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    }
  }

  Widget _buildMetaRow(String label, String value, AccessibilityConfig access, {bool isAlert = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: access.getTextStyle(
            baseSize: 14.0,
            color: access.textColor.withOpacity(0.5),
          ),
        ),
        Text(
          value,
          style: access.getTextStyle(
            baseSize: 14.0,
            fontWeight: FontWeight.bold,
            color: isAlert ? access.alertRed : access.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNoInteractionsCard(AccessibilityConfig access) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(access.scaleSpacing(16.0)),
      decoration: BoxDecoration(
        color: access.successGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: access.successGreen.withOpacity(0.15), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: access.successGreen, size: access.scaleText(20.0)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No active interactions detected with medicines currently inside your cabinet.',
              style: access.getTextStyle(
                baseSize: 13.0,
                fontWeight: FontWeight.bold,
                color: access.successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionTile(Map<String, String> inter, AccessibilityConfig access) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(access.scaleSpacing(16.0)),
      decoration: BoxDecoration(
        color: access.alertRed.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: access.alertRed.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Interacts with: ${inter['otherMed']}',
                style: access.getTextStyle(
                  baseSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SeverityChip(access: access, severity: inter['severity']!),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            inter['description']!,
            style: access.getTextStyle(
              baseSize: 13.0,
              color: access.textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalInfoCard(AccessibilityConfig access) {
    final hasDbData = medicine.manufacturer != null || medicine.substitutes != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(access.scaleSpacing(16.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: access.textColor.withOpacity(0.08), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasDbData ? 'Database Verification & Metadata' : 'Approved FDA Labeling Highlights',
            style: access.getTextStyle(
              baseSize: 14.0,
              fontWeight: FontWeight.bold,
              color: access.primaryTeal,
            ),
          ),
          const SizedBox(height: 12),
          if (hasDbData) ...[
            if (medicine.manufacturer != null) ...[
              _buildMetaRow('Manufacturer', medicine.manufacturer!, access),
              const SizedBox(height: 8),
            ],
            if (medicine.price != null && medicine.price! > 0) ...[
              _buildMetaRow('MRP (Price)', '₹ ${medicine.price!.toStringAsFixed(2)}', access),
              const SizedBox(height: 8),
            ],
            if (medicine.therapeuticClass != null && medicine.therapeuticClass!.isNotEmpty) ...[
              _buildMetaRow('Therapeutic Class', medicine.therapeuticClass!, access),
              const SizedBox(height: 8),
            ],
            if (medicine.chemicalClass != null && medicine.chemicalClass!.isNotEmpty) ...[
              _buildMetaRow('Chemical Class', medicine.chemicalClass!, access),
              const SizedBox(height: 8),
            ],
            if (medicine.habitForming != null && medicine.habitForming!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Habit Forming: ',
                    style: access.getTextStyle(baseSize: 13.0, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    medicine.habitForming!,
                    style: access.getTextStyle(
                      baseSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: medicine.habitForming!.toLowerCase() == 'yes' ? access.alertRed : access.successGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (medicine.medicineDesc != null && medicine.medicineDesc!.isNotEmpty) ...[
              Text(
                'Description:',
                style: access.getTextStyle(baseSize: 13.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                medicine.medicineDesc!,
                style: access.getTextStyle(baseSize: 12.0, color: access.textColor.withOpacity(0.7)),
              ),
              const SizedBox(height: 12),
            ],
            if (medicine.substitutes != null && medicine.substitutes!.isNotEmpty) ...[
              const Divider(height: 32),
              Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, color: access.primaryTeal, size: access.scaleText(20.0)),
                  const SizedBox(width: 8),
                  Text(
                    'ALTERNATIVE SUBSTITUTES',
                    style: access.getTextStyle(
                      baseSize: 13.0,
                      fontWeight: FontWeight.w900,
                      color: access.primaryTeal,
                    ).copyWith(letterSpacing: 1.1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 10.0,
                children: medicine.substitutes!
                    .split(',')
                    .map((sub) => sub.trim())
                    .where((sub) => sub.isNotEmpty)
                    .map((subName) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: access.primaryTeal.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: access.scaleText(16.0),
                          color: access.primaryTeal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          subName,
                          style: access.getTextStyle(
                            baseSize: 13.0,
                            fontWeight: FontWeight.bold,
                            color: access.textColor.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ] else ...[
            _buildBulletPoint('Do not exceed the maximum daily dosage ranges.', access),
            const SizedBox(height: 8),
            _buildBulletPoint('Consult with a medical professional if symptoms persist.', access),
            const SizedBox(height: 8),
            _buildBulletPoint('Store in a cool, dry place away from direct sunlight.', access),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, AccessibilityConfig access) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: access.getTextStyle(
            baseSize: 14.0,
            fontWeight: FontWeight.bold,
            color: access.primaryTeal,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: access.getTextStyle(
              baseSize: 13.0,
              color: access.textColor.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
