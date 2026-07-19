import 'package:flutter/material.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';

// --- DISCLAIMER BANNER ---
class DisclaimerBanner extends StatelessWidget {
  final AccessibilityConfig access;

  const DisclaimerBanner({super.key, required this.access});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: access.scaleSpacing(16.0),
        vertical: access.scaleSpacing(12.0),
      ),
      decoration: BoxDecoration(
        color: access.textColor.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: access.textColor.withOpacity(0.12), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: access.primaryTeal,
            size: access.scaleText(20.0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'For informational purposes only — not a substitute for professional medical advice.',
              style: access.getTextStyle(
                baseSize: 13.0,
                fontWeight: FontWeight.w600,
                color: access.textColor.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- OFFLINE SYNC BANNER ---
class OfflineSyncBanner extends StatelessWidget {
  final AccessibilityConfig access;
  final DateTime? lastSynced;

  const OfflineSyncBanner({super.key, required this.access, this.lastSynced});

  @override
  Widget build(BuildContext context) {
    final timeStr = lastSynced != null
        ? '${lastSynced!.hour.toString().padLeft(2, '0')}:${lastSynced!.minute.toString().padLeft(2, '0')}'
        : 'Never';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: access.scaleSpacing(16.0),
        vertical: access.scaleSpacing(8.0),
      ),
      decoration: BoxDecoration(
        color: access.warmAmber.withOpacity(0.15),
        border: Border(
          bottom: BorderSide(color: access.warmAmber, width: 1.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: access.warmAmber,
            size: access.scaleText(18.0),
          ),
          const SizedBox(width: 8),
          Text(
            'Offline — last synced today at $timeStr',
            style: access.getTextStyle(
              baseSize: 13.0,
              fontWeight: FontWeight.bold,
              color: access.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// --- ROLE BADGE ---
class RoleBadge extends StatelessWidget {
  final AccessibilityConfig access;
  final String role; // 'Patient' or 'Caregiver'

  const RoleBadge({super.key, required this.access, required this.role});

  @override
  Widget build(BuildContext context) {
    final isPatient = role.toLowerCase() == 'patient';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: access.scaleSpacing(12.0),
        vertical: access.scaleSpacing(6.0),
      ),
      decoration: BoxDecoration(
        color: isPatient
            ? access.primaryTeal.withOpacity(0.12)
            : const Color(0xFF6366F1).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPatient ? access.primaryTeal : const Color(0xFF6366F1),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPatient ? Icons.person_outline_rounded : Icons.people_outline_rounded,
            size: access.scaleText(14.0),
            color: isPatient ? access.primaryTeal : const Color(0xFF6366F1),
          ),
          const SizedBox(width: 4),
          Text(
            role.toUpperCase(),
            style: access.getTextStyle(
              baseSize: 12.0,
              fontWeight: FontWeight.bold,
              color: isPatient ? access.primaryTeal : const Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }
}

// --- SEVERITY CHIP ---
class SeverityChip extends StatelessWidget {
  final AccessibilityConfig access;
  final String severity; // 'contraindicated', 'caution', 'monitor', 'safe'

  const SeverityChip({super.key, required this.access, required this.severity});

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    String label;
    IconData icon;

    switch (severity.toLowerCase()) {
      case 'contraindicated':
        chipColor = access.alertRed;
        label = 'Contraindicated';
        icon = Icons.cancel_outlined;
        break;
      case 'caution':
        chipColor = access.warmAmber;
        label = 'Caution';
        icon = Icons.warning_amber_rounded;
        break;
      case 'monitor':
        chipColor = Colors.blue.shade700;
        label = 'Monitor';
        icon = Icons.visibility_outlined;
        break;
      case 'safe':
      default:
        chipColor = access.successGreen;
        label = 'Safe';
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: access.scaleSpacing(10.0),
        vertical: access.scaleSpacing(6.0),
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: access.scaleText(14.0), color: chipColor),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: access.getTextStyle(
              baseSize: 11.0,
              fontWeight: FontWeight.bold,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}

// --- EXPIRY TAG ---
class ExpiryTag extends StatelessWidget {
  final AccessibilityConfig access;
  final DateTime expiryDate;

  const ExpiryTag({super.key, required this.access, required this.expiryDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;

    Color tagColor;
    String text;
    IconData icon;

    if (difference <= 0) {
      tagColor = access.alertRed;
      text = 'Expired';
      icon = Icons.gpp_bad_rounded;
    } else if (difference <= 7) {
      tagColor = access.alertRed;
      text = 'Expires in $difference days';
      icon = Icons.priority_high_rounded;
    } else if (difference <= 30) {
      tagColor = access.warmAmber;
      text = 'Expires in $difference days';
      icon = Icons.warning_rounded;
    } else if (difference <= 90) {
      tagColor = Colors.orange.shade700;
      text = 'Expires in $difference days';
      icon = Icons.schedule_rounded;
    } else {
      tagColor = access.successGreen;
      text = 'Safe';
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: access.scaleSpacing(10.0),
        vertical: access.scaleSpacing(6.0),
      ),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tagColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tagColor, size: access.scaleText(15.0)),
          const SizedBox(width: 6),
          Text(
            text,
            style: access.getTextStyle(
              baseSize: 12.0,
              fontWeight: FontWeight.bold,
              color: tagColor,
            ),
          ),
        ],
      ),
    );
  }
}

// --- ELDERLY MODE TOGGLE ---
class ElderlyModeToggle extends StatelessWidget {
  final AccessibilityConfig access;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ElderlyModeToggle({
    super.key,
    required this.access,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Ensuring touch target is large (at least 48dp)
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: access.minTapTargetSize,
          minWidth: access.scaleSpacing(140.0),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: value ? access.primaryTeal : access.textColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: value ? access.primaryTeal : access.textColor.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                value ? Icons.check_circle : Icons.accessibility_new_rounded,
                color: value ? Colors.white : access.textColor,
                size: access.scaleText(20.0),
              ),
              const SizedBox(width: 8),
              Text(
                'Simple Mode',
                style: access.getTextStyle(
                  baseSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: value ? Colors.white : access.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MEDICINE CARD ---
class MedicineCard extends StatelessWidget {
  final AccessibilityConfig access;
  final Medicine medicine;
  final VoidCallback onDelete;
  final VoidCallback? onTaken;

  const MedicineCard({
    super.key,
    required this.access,
    required this.medicine,
    required this.onDelete,
    this.onTaken,
  });

  @override
  Widget build(BuildContext context) {
    // Display different icons based on verification source
    IconData sourceIcon;
    String sourceText;
    switch (medicine.verifiedSource) {
      case VerifiedSource.barcode:
        sourceIcon = Icons.qr_code_scanner_rounded;
        sourceText = 'Barcode Verified';
        break;
      case VerifiedSource.ocr:
        sourceIcon = Icons.document_scanner_outlined;
        sourceText = 'Rx OCR Scanned';
        break;
      case VerifiedSource.manual:
      default:
        sourceIcon = Icons.edit_note_rounded;
        sourceText = 'Manual Entry';
        break;
    }

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: access.textColor.withOpacity(0.08), width: 1.5),
      ),
      margin: EdgeInsets.only(bottom: access.scaleSpacing(14.0)),
      child: Padding(
        padding: EdgeInsets.all(access.scaleSpacing(16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine Header Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: access.primaryTeal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    color: access.primaryTeal,
                    size: access.scaleText(28.0),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: access.getTextStyle(
                          baseSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        medicine.genericName,
                        style: access.getTextStyle(
                          baseSize: 14.0,
                          color: access.textColor.withOpacity(0.5),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                // Expiry Tag
                ExpiryTag(access: access, expiryDate: medicine.expiryDate),
              ],
            ),
            const SizedBox(height: 16),

            // Source & Detail Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Batch/Form info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Form: ${medicine.dosageForm}',
                      style: access.getTextStyle(
                        baseSize: 13.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (medicine.batchNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Batch: ${medicine.batchNumber}',
                        style: access.getTextStyle(
                          baseSize: 12.0,
                          color: access.textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
                // Source details
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: access.textColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(sourceIcon, size: access.scaleText(13.0), color: access.primaryTeal),
                      const SizedBox(width: 4),
                      Text(
                        sourceText,
                        style: access.getTextStyle(
                          baseSize: 11.0,
                          fontWeight: FontWeight.bold,
                          color: access.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions Buttons Section
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onTaken != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTaken,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        'Confirm Dose',
                        style: access.getTextStyle(baseSize: 14.0, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: access.scaleSpacing(12.0)),
                        minimumSize: Size(0, access.minTapTargetSize),
                        foregroundColor: access.successGreen,
                        side: BorderSide(color: access.successGreen, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                if (onTaken != null) const SizedBox(width: 12),
                
                // Delete button with explicit text label in Elderly Mode
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline_rounded, color: access.alertRed),
                    label: Text(
                      'Remove',
                      style: access.getTextStyle(
                        baseSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: access.alertRed,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: access.scaleSpacing(12.0)),
                      minimumSize: Size(0, access.minTapTargetSize),
                      foregroundColor: access.alertRed,
                      side: BorderSide(color: access.alertRed.withOpacity(0.5), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- VOICE INPUT FIELD ---
class VoiceInputField extends StatefulWidget {
  final AccessibilityConfig access;
  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final String? Function(String?)? validator;
  final String mockTranscript; // Mock text to return upon voice simulation

  const VoiceInputField({
    super.key,
    required this.access,
    required this.controller,
    required this.labelText,
    required this.icon,
    this.validator,
    required this.mockTranscript,
  });

  @override
  State<VoiceInputField> createState() => _VoiceInputFieldState();
}

class _VoiceInputFieldState extends State<VoiceInputField> {
  bool _isListening = false;

  void _startListening() {
    setState(() => _isListening = true);

    showModalBottomSheet(
      context: context,
      backgroundColor: widget.access.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Simulate voice transcript arrival after 1.5 seconds
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (context.mounted && _isListening) {
                setModalState(() {
                  _isListening = false;
                });
              }
            });

            return Container(
              padding: EdgeInsets.all(widget.access.scaleSpacing(24.0)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.access.textColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Listening Indicator or Transcript
                  if (_isListening) ...[
                    Text(
                      'Listening...',
                      style: widget.access.getTextStyle(
                        baseSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: widget.access.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Animated pulsing wave mockup
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.graphic_eq_rounded, size: 48, color: Color(0xFF0F766E)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Speak medicine details clearly',
                      style: widget.access.getTextStyle(
                        baseSize: 14.0,
                        color: widget.access.textColor.withOpacity(0.5),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Recognized Transcript',
                      style: widget.access.getTextStyle(
                        baseSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: widget.access.textColor.withOpacity(0.1)),
                      ),
                      child: Text(
                        widget.mockTranscript,
                        style: widget.access.getTextStyle(
                          baseSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        // Try again button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                _isListening = true;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(0, widget.access.minTapTargetSize),
                              side: BorderSide(color: widget.access.textColor.withOpacity(0.2)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Try Again',
                              style: widget.access.getTextStyle(
                                baseSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: widget.access.textColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Confirm button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              widget.controller.text = widget.mockTranscript;
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.access.primaryTeal,
                              foregroundColor: Colors.white,
                              minimumSize: Size(0, widget.access.minTapTargetSize),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Confirm Text',
                              style: widget.access.getTextStyle(
                                baseSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() => _isListening = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      style: widget.access.getTextStyle(baseSize: 15.0),
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: widget.access.getTextStyle(
          baseSize: 14.0,
          color: widget.access.textColor.withOpacity(0.6),
        ),
        prefixIcon: Icon(
          widget.icon,
          color: widget.access.textColor.withOpacity(0.6),
          size: widget.access.scaleText(20.0),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 6.0),
          child: IconButton(
            // Accessibility target size guaranteed
            icon: Icon(
              Icons.mic_none_rounded,
              color: widget.access.primaryTeal,
              size: widget.access.scaleText(24.0),
            ),
            onPressed: _startListening,
            tooltip: 'Use voice input',
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: widget.access.textColor.withOpacity(0.08), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: widget.access.primaryTeal, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: widget.access.alertRed.withOpacity(0.5), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: widget.access.alertRed, width: 2.0),
        ),
      ),
      validator: widget.validator,
    );
  }
}
