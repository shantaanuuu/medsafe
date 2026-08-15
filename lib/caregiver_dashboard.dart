import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';
import 'emergency_card.dart';
import 'features/onboarding/onboarding_provider.dart';
import 'features/onboarding/onboarding_flow_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/onboarding_repository.dart';

class CaregiverDashboardScreen extends ConsumerWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final dependents = ref.watch(dependentProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);

    return Scaffold(
      backgroundColor: access.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: access.textColor,
        elevation: 0,
        title: Text(
          'Caregiver Dashboard',
          style: access.getTextStyle(
            baseSize: 20.0,
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
                vertical: access.scaleSpacing(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Linked Dependents',
                    style: access.getTextStyle(
                      baseSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dependents.length,
                    itemBuilder: (context, index) {
                      final dependent = dependents[index];
                      return _buildDependentCard(context, ref, dependent, access);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDependentCard(
    BuildContext context,
    WidgetRef ref,
    Dependent dep,
    AccessibilityConfig access,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: EdgeInsets.all(access.scaleSpacing(18.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: access.textColor.withOpacity(0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: access.textColor.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dependent details header
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: access.primaryTeal.withOpacity(0.08),
                child: Icon(Icons.face_rounded, color: access.primaryTeal, size: access.scaleText(28.0)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dep.name,
                            style: access.getTextStyle(baseSize: 18.0, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (dep.id != 'dep_1' && dep.id != 'dep_2')
                          IconButton(
                            icon: Icon(Icons.edit_rounded, size: 18, color: access.primaryTeal),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _showEditNicknameDialog(context, ref, dep, access);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Age: ${dep.age} | Weight: ${dep.weight} kg',
                      style: access.getTextStyle(
                        baseSize: 13.0,
                        color: access.textColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Adherence streak indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Text('🔥', style: TextStyle(fontSize: access.scaleText(15.0))),
                    const SizedBox(width: 4),
                    Text(
                      '${dep.streakDays} Days',
                      style: access.getTextStyle(
                        baseSize: 12.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Log Summary / Rate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Adherence Rate',
                style: access.getTextStyle(baseSize: 13.0, color: access.textColor.withOpacity(0.5)),
              ),
              Text(
                '${(dep.adherenceRate * 100).toStringAsFixed(0)}% On-time',
                style: access.getTextStyle(
                  baseSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: access.successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Adherence List Items
          Text(
            'Today\'s Schedule:',
            style: access.getTextStyle(baseSize: 13.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ...dep.adherenceLog.map((log) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '• ${log.medicineName} (${log.timeString})',
                      style: access.getTextStyle(
                        baseSize: 14.0,
                        color: log.isTaken ? access.textColor : access.textColor.withOpacity(0.5),
                        height: 1.2,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        log.isTaken ? 'Confirmed' : 'Pending',
                        style: access.getTextStyle(
                          baseSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: log.isTaken ? access.successGreen : access.textColor.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Action switch target size guaranteed
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: log.isTaken,
                          activeColor: access.successGreen,
                          onChanged: (val) {
                            ref.read(dependentProvider.notifier).recordAdherence(
                                  dep.id,
                                  log.medicineName,
                                  log.timeString,
                                  val,
                                );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),

          // Emergency Card Trigger
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmergencyCardScreen(dependent: dep),
                ),
              );
            },
            icon: Icon(Icons.contact_emergency_outlined, size: access.scaleText(20.0), color: Colors.white),
            label: Text(
              'Show Emergency Hospital Card',
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
        ],
      ),
    );
  }

  void _showEditNicknameDialog(
    BuildContext context,
    WidgetRef ref,
    Dependent dep,
    AccessibilityConfig access,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: access.textColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Manage ${dep.name}',
                  style: access.getTextStyle(
                    baseSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: access.primaryTeal.withOpacity(0.1),
                    child: Icon(Icons.edit_rounded, color: access.primaryTeal),
                  ),
                  title: Text(
                    'Edit Health Profile',
                    style: access.getTextStyle(baseSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Update conditions, current meds, or vitals',
                    style: access.getTextStyle(baseSize: 13.0, color: access.textColor.withOpacity(0.5)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    final profiles = ref.read(allProfilesProvider).value ?? [];
                    final depProfile = profiles.firstWhere((p) => p.id == dep.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OnboardingFlowScreen(
                          isAddingDependent: true,
                          prefilledDependent: depProfile,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50,
                    child: Icon(Icons.delete_rounded, color: Colors.red.shade700),
                  ),
                  title: Text(
                    'Delete Profile',
                    style: access.getTextStyle(baseSize: 16.0, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                  ),
                  subtitle: Text(
                    'Permanently remove from caregiver cabinet',
                    style: access.getTextStyle(baseSize: 13.0, color: access.textColor.withOpacity(0.5)),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, ref, dep, access);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Dependent dep,
    AccessibilityConfig access,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Delete ${dep.name}?',
            style: access.getTextStyle(baseSize: 18.0, fontWeight: FontWeight.bold, color: Colors.red.shade700),
          ),
          content: Text(
            'Are you sure you want to permanently delete this dependent profile and all their medications? This action cannot be undone.',
            style: access.getTextStyle(baseSize: 14.0),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: access.getTextStyle(baseSize: 14.0, color: access.textColor.withOpacity(0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleting dependent profile...')),
                );

                try {
                  final repo = ref.read(onboardingRepositoryProvider);
                  await repo.deleteDependent(dep.id, user.uid);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dependent profile deleted successfully!'),
                        backgroundColor: Color(0xFF0F766E),
                      ),
                    );
                    ref.invalidate(allProfilesProvider);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete dependent: $e'),
                        backgroundColor: const Color(0xFFB91C1C),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Delete',
                style: access.getTextStyle(baseSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
