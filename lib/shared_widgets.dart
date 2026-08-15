import 'package:flutter/material.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';

// --- PASTEL ICON CONTAINER ---
class PastelIconContainer extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final double size;
  final double iconSize;
  final double borderRadius;

  const PastelIconContainer({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.size = 46.0,
    this.iconSize = 22.0,
    this.borderRadius = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: iconColor,
        size: iconSize,
      ),
    );
  }
}

// --- SECTION HEADER ---
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final AccessibilityConfig access;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    required this.access,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: access.getTextStyle(
                baseSize: 18.0,
                fontWeight: FontWeight.bold,
                color: access.textColor,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: access.getTextStyle(
                  baseSize: 13.0,
                  color: access.secondaryTextColor,
                ),
              ),
            ],
          ],
        ),
        if (actionText != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                actionText!,
                style: access.getTextStyle(
                  baseSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: access.secondaryTextColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// --- QUICK ACTION CARD ---
class QuickActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;
  final AccessibilityConfig access;

  const QuickActionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
    required this.access,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: iconColor.withOpacity(0.08),
        highlightColor: iconColor.withOpacity(0.04),
        child: Container(
          padding: EdgeInsets.all(access.scaleSpacing(14.0)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: access.borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              PastelIconContainer(
                icon: icon,
                iconColor: iconColor,
                backgroundColor: iconBgColor,
                size: access.scaleSpacing(44.0),
                iconSize: access.scaleText(22.0),
                borderRadius: 12.0,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: access.getTextStyle(
                        baseSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: access.textColor,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: access.getTextStyle(
                          baseSize: 11.5,
                          color: access.secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        vertical: access.scaleSpacing(10.0),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // soft blue tint
        border: Border(
          bottom: BorderSide(color: access.primaryBlue.withOpacity(0.15), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: access.primaryBlue,
            size: access.scaleText(18.0),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'For informational purposes only — not a substitute for professional medical advice.',
              style: access.getTextStyle(
                baseSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E40AF),
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
        color: access.pastelYellow,
        border: Border(
          bottom: BorderSide(color: access.warmAmber.withOpacity(0.4), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: access.warmAmber,
            size: access.scaleText(16.0),
          ),
          const SizedBox(width: 8),
          Text(
            'Offline — last synced today at $timeStr',
            style: access.getTextStyle(
              baseSize: 12.5,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF92400E),
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
    final color = isPatient ? access.primaryBlue : access.purpleAccent;
    final bg = isPatient ? access.pastelBlue : access.pastelPurple;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: access.scaleSpacing(10.0),
        vertical: access.scaleSpacing(4.0),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPatient ? Icons.person_outline_rounded : Icons.people_outline_rounded,
            size: access.scaleText(13.0),
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            role,
            style: access.getTextStyle(
              baseSize: 12.0,
              fontWeight: FontWeight.bold,
              color: color,
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
    Color chipBg;
    String label;
    IconData icon;

    switch (severity.toLowerCase()) {
      case 'contraindicated':
        chipColor = access.alertRed;
        chipBg = access.pastelRed;
        label = 'Contraindicated';
        icon = Icons.cancel_outlined;
        break;
      case 'caution':
        chipColor = access.warmAmber;
        chipBg = access.pastelYellow;
        label = 'Caution';
        icon = Icons.warning_amber_rounded;
        break;
      case 'monitor':
        chipColor = access.primaryBlue;
        chipBg = access.pastelBlue;
        label = 'Monitor';
        icon = Icons.visibility_outlined;
        break;
      case 'safe':
      default:
        chipColor = access.successGreen;
        chipBg = access.pastelGreen;
        label = 'Safe';
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: access.scaleSpacing(10.0),
        vertical: access.scaleSpacing(4.0),
      ),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withOpacity(0.3), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: access.scaleText(13.0), color: chipColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: access.getTextStyle(
              baseSize: 11.5,
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
    Color tagBg;
    String text;
    IconData icon;

    if (difference <= 0) {
      tagColor = access.alertRed;
      tagBg = access.pastelRed;
      text = 'Expired';
      icon = Icons.gpp_bad_rounded;
    } else if (difference <= 7) {
      tagColor = access.alertRed;
      tagBg = access.pastelRed;
      text = 'Exp in $difference d';
      icon = Icons.priority_high_rounded;
    } else if (difference <= 30) {
      tagColor = access.warmAmber;
      tagBg = access.pastelYellow;
      text = 'Exp in $difference d';
      icon = Icons.warning_amber_rounded;
    } else {
      tagColor = access.successGreen;
      tagBg = access.pastelGreen;
      text = 'Active';
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: access.scaleSpacing(9.0),
        vertical: access.scaleSpacing(4.0),
      ),
      decoration: BoxDecoration(
        color: tagBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tagColor.withOpacity(0.3), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tagColor, size: access.scaleText(13.0)),
          const SizedBox(width: 4),
          Text(
            text,
            style: access.getTextStyle(
              baseSize: 11.5,
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
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value ? access.pastelBlue : access.pastelGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? access.primaryBlue : access.borderColor,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.accessibility_new_rounded,
              color: value ? access.primaryBlue : access.secondaryTextColor,
              size: access.scaleText(16.0),
            ),
            const SizedBox(width: 6),
            Text(
              'Simple Mode',
              style: access.getTextStyle(
                baseSize: 12.0,
                fontWeight: FontWeight.w600,
                color: value ? access.primaryBlue : access.textColor,
              ),
            ),
          ],
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
    IconData sourceIcon;
    String sourceText;
    switch (medicine.verifiedSource) {
      case VerifiedSource.barcode:
        sourceIcon = Icons.qr_code_scanner_rounded;
        sourceText = 'Barcode';
        break;
      case VerifiedSource.ocr:
        sourceIcon = Icons.document_scanner_outlined;
        sourceText = 'Rx OCR';
        break;
      case VerifiedSource.manual:
      default:
        sourceIcon = Icons.edit_note_rounded;
        sourceText = 'Manual';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: access.scaleSpacing(12.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: access.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(access.scaleSpacing(16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine Header Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PastelIconContainer(
                  icon: Icons.medication_rounded,
                  iconColor: access.primaryBlue,
                  backgroundColor: access.pastelBlue,
                  size: access.scaleSpacing(48.0),
                  iconSize: access.scaleText(26.0),
                  borderRadius: 14.0,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: access.getTextStyle(
                          baseSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: access.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        medicine.genericName,
                        style: access.getTextStyle(
                          baseSize: 13.0,
                          color: access.secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Form: ${medicine.dosageForm}',
                            style: access.getTextStyle(
                              baseSize: 12.0,
                              fontWeight: FontWeight.w500,
                              color: access.secondaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: access.pastelGray,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(sourceIcon, size: 10, color: access.secondaryTextColor),
                                const SizedBox(width: 3),
                                Text(
                                  sourceText,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: access.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Expiry Tag
                ExpiryTag(access: access, expiryDate: medicine.expiryDate),
              ],
            ),
            const SizedBox(height: 14),

            // Action Buttons Section
            Row(
              children: [
                if (onTaken != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTaken,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: Text(
                        'Confirm Dose',
                        style: access.getTextStyle(
                          baseSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: access.successGreen,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: access.scaleSpacing(10.0)),
                        minimumSize: Size(0, access.minTapTargetSize),
                        foregroundColor: access.successGreen,
                        side: BorderSide(color: access.successGreen.withOpacity(0.5), width: 1.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: access.pastelGreen.withOpacity(0.3),
                      ),
                    ),
                  ),
                if (onTaken != null) const SizedBox(width: 10),
                
                // Delete button
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded, color: access.alertRed, size: 16),
                  label: Text(
                    'Remove',
                    style: access.getTextStyle(
                      baseSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: access.alertRed,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: access.scaleSpacing(14.0),
                      vertical: access.scaleSpacing(10.0),
                    ),
                    minimumSize: Size(0, access.minTapTargetSize),
                    foregroundColor: access.alertRed,
                    side: BorderSide(color: access.alertRed.withOpacity(0.3), width: 1.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: access.pastelRed.withOpacity(0.3),
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
  final String mockTranscript;

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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.access.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (_isListening) ...[
                    Text(
                      'Listening...',
                      style: widget.access.getTextStyle(
                        baseSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: widget.access.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.graphic_eq_rounded, size: 48, color: widget.access.primaryBlue),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Speak medicine details clearly',
                      style: widget.access.getTextStyle(
                        baseSize: 14.0,
                        color: widget.access.secondaryTextColor,
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
                        color: widget.access.pastelGray,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: widget.access.borderColor),
                      ),
                      child: Text(
                        widget.mockTranscript,
                        style: widget.access.getTextStyle(
                          baseSize: 15.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                _isListening = true;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size(0, widget.access.minTapTargetSize),
                              side: BorderSide(color: widget.access.borderColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              widget.controller.text = widget.mockTranscript;
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.access.primaryBlue,
                              foregroundColor: Colors.white,
                              minimumSize: Size(0, widget.access.minTapTargetSize),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
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
          color: widget.access.secondaryTextColor,
        ),
        prefixIcon: Icon(
          widget.icon,
          color: widget.access.secondaryTextColor,
          size: widget.access.scaleText(20.0),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 6.0),
          child: IconButton(
            icon: Icon(
              Icons.mic_none_rounded,
              color: widget.access.primaryBlue,
              size: widget.access.scaleText(22.0),
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
          borderSide: BorderSide(color: widget.access.borderColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: widget.access.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: widget.access.alertRed.withOpacity(0.5), width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: widget.access.alertRed, width: 1.5),
        ),
      ),
      validator: widget.validator,
    );
  }
}
