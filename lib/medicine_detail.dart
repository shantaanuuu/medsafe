import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';
import 'dosage_calculator.dart';
import 'risk_profiler.dart';

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
                  _buildHeaderCard(context, access, sourceIcon, sourceText),
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
        border: Border.all(color: access.textColor.withOpacity(0.08), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: access.primaryTeal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: access.primaryTeal,
                  size: access.scaleText(32.0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
          if (medicine.batchNumber != null) ...[
            _buildMetaRow('Batch Code', medicine.batchNumber!, access),
            const SizedBox(height: 10),
          ],
          _buildMetaRow(
            'Expiry Date',
            '${medicine.expiryDate.year}-${medicine.expiryDate.month.toString().padLeft(2, '0')}-${medicine.expiryDate.day.toString().padLeft(2, '0')}',
            access,
            isAlert: medicine.expiryDate.difference(DateTime.now()).inDays <= 30,
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
            'Approved FDA Labeling Highlights',
            style: access.getTextStyle(
              baseSize: 14.0,
              fontWeight: FontWeight.bold,
              color: access.primaryTeal,
            ),
          ),
          const SizedBox(height: 12),
          _buildBulletPoint('Do not exceed the maximum daily dosage ranges.', access),
          const SizedBox(height: 8),
          _buildBulletPoint('Consult with a medical professional if symptoms persist.', access),
          const SizedBox(height: 8),
          _buildBulletPoint('Store in a cool, dry place away from direct sunlight.', access),
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
