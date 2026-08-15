import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';

class EmergencyCardScreen extends ConsumerWidget {
  final Dependent dependent;

  const EmergencyCardScreen({super.key, required this.dependent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);

    return Scaffold(
      backgroundColor: access.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: access.textColor,
        elevation: 0,
        title: Text(
          'Emergency Card',
          style: access.getTextStyle(
            baseSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
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
          // Non-dismissible disclaimer
          DisclaimerBanner(access: access),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: access.scaleSpacing(20.0),
                vertical: access.scaleSpacing(20.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Family Emergency Card',
                    style: access.getTextStyle(
                      baseSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Designed to be shown at a hospital front desk in case of emergencies.',
                    style: access.getTextStyle(
                      baseSize: 13.0,
                      color: access.textColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // The Visual Emergency Card Container
                  Container(
                    padding: EdgeInsets.all(access.scaleSpacing(20.0)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: access.alertRed, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: access.alertRed.withOpacity(0.06),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'EMERGENCY DATA',
                              style: access.getTextStyle(
                                baseSize: 14.0,
                                fontWeight: FontWeight.w900,
                                color: access.alertRed,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: access.alertRed.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'CRITICAL',
                                style: access.getTextStyle(
                                  baseSize: 11.0,
                                  fontWeight: FontWeight.w900,
                                  color: access.alertRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Name/Age/Weight
                        Text(
                          dependent.name.toUpperCase(),
                          style: access.getTextStyle(baseSize: 22.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Age: ${dependent.age} Years  |  Weight: ${dependent.weight} kg',
                          style: access.getTextStyle(
                            baseSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: access.textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Allergies Section (Critical - Red Alert)
                        Text(
                          'KNOWN ALLERGIES:',
                          style: access.getTextStyle(
                            baseSize: 13.0,
                            fontWeight: FontWeight.w900,
                            color: access.alertRed,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (dependent.allergies.isEmpty)
                          Text('NONE REPORTED', style: access.getTextStyle(baseSize: 14.0, fontWeight: FontWeight.bold))
                        else
                          Wrap(
                            spacing: 8,
                            children: dependent.allergies.map((allergy) {
                              return Chip(
                                backgroundColor: access.alertRed.withOpacity(0.08),
                                side: BorderSide(color: access.alertRed, width: 1.5),
                                label: Text(
                                  allergy,
                                  style: access.getTextStyle(
                                    baseSize: 13.0,
                                    fontWeight: FontWeight.bold,
                                    color: access.alertRed,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 16),

                        // Medical Conditions
                        Text(
                          'DIAGNOSED CONDITIONS:',
                          style: access.getTextStyle(
                            baseSize: 13.0,
                            fontWeight: FontWeight.w900,
                            color: access.textColor.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dependent.conditions.join(', '),
                          style: access.getTextStyle(baseSize: 15.0, fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 20),

                        // Active Medicines
                        Text(
                          'CURRENT ACTIVE MEDICATIONS:',
                          style: access.getTextStyle(
                            baseSize: 13.0,
                            fontWeight: FontWeight.w900,
                            color: access.primaryTeal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...dependent.adherenceLog.map((log) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                '• ${log.medicineName}',
                                style: access.getTextStyle(baseSize: 14.0, fontWeight: FontWeight.bold),
                              ),
                            )),

                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Emergency Contacts
                        Text(
                          'PRIMARY EMERGENCY CONTACT:',
                          style: access.getTextStyle(
                            baseSize: 13.0,
                            fontWeight: FontWeight.w900,
                            color: access.textColor.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dependent.emergencyContactName,
                          style: access.getTextStyle(baseSize: 15.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dependent.emergencyContactPhone,
                          style: access.getTextStyle(
                            baseSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: access.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Share/Export Button
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Exporting Emergency Card PDF...'),
                          backgroundColor: access.primaryTeal,
                        ),
                      );
                    },
                    icon: Icon(Icons.share_rounded, size: access.scaleText(20.0), color: Colors.white),
                    label: Text(
                      'Share / Export Card as PDF',
                      style: access.getTextStyle(
                        baseSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: access.primaryTeal,
                      foregroundColor: Colors.white,
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
}
