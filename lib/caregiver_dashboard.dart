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
import 'features/chatbot/widgets/chatbot_overlay.dart';
import 'features/chatbot/providers/chatbot_provider.dart';

class CaregiverDashboardScreen extends ConsumerWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final dependents = ref.watch(dependentProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);
    
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Caregiver';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentScreenProvider.notifier).setScreen('Caregiver Dashboard Screen with ${dependents.length} dependents');
    });

    return Scaffold(
      floatingActionButton: const ChatbotOverlayButton(),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: access.textColor,
        elevation: 0,
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
            child: dependents.isEmpty
                ? _buildEmptyState(context, userName, access)
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: access.scaleSpacing(20.0),
                      vertical: access.scaleSpacing(16.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Evening, $userName',
                          style: access.getTextStyle(
                            baseSize: 16.0,
                            color: access.textColor.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage the people you care for',
                          style: access.getTextStyle(
                            baseSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dependents.length,
                          itemBuilder: (context, index) {
                            final dependent = dependents[index];
                            return _buildDependentCard(context, ref, dependent, access);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildAddDependentButton(context, access),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String userName, AccessibilityConfig access) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: access.scaleSpacing(20.0),
        vertical: access.scaleSpacing(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good Evening, $userName',
            style: access.getTextStyle(
              baseSize: 16.0,
              color: access.textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage the people you care for',
            style: access.getTextStyle(
              baseSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: access.scaleSpacing(64.0)),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.family_restroom,
                  size: access.scaleText(64.0),
                  color: const Color(0xFF2563EB).withOpacity(0.2),
                ),
                const SizedBox(height: 24),
                Text(
                  'No dependents yet',
                  style: access.getTextStyle(
                    baseSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Add someone you care for to help manage their medicines and health information.',
                    textAlign: TextAlign.center,
                    style: access.getTextStyle(
                      baseSize: 16.0,
                      color: access.textColor.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OnboardingFlowScreen(isAddingDependent: true),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: access.scaleSpacing(32),
                      vertical: access.scaleSpacing(16),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '+ Add Dependent',
                    style: access.getTextStyle(
                      baseSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDependentButton(BuildContext context, AccessibilityConfig access) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OnboardingFlowScreen(isAddingDependent: true),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(access.scaleSpacing(20.0)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: const Color(0xFF2563EB), size: access.scaleText(24.0)),
            const SizedBox(width: 12),
            Text(
              'Add Dependent',
              style: access.getTextStyle(
                baseSize: 16.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(access.scaleSpacing(20.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE8F0FF),
                child: Icon(Icons.person_rounded, color: const Color(0xFF2563EB), size: access.scaleText(26.0)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dep.name,
                      style: access.getTextStyle(baseSize: 18.0, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Age: ${dep.age} | ${dep.weight} kg',
                      style: access.getTextStyle(
                        baseSize: 14.0,
                        color: access.textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dep.id != 'dep_1' && dep.id != 'dep_2') ...[
                    IconButton(
                      icon: Icon(Icons.edit_rounded, size: 22, color: const Color(0xFF2563EB)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showEditNicknameDialog(context, ref, dep, access),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 22, color: Colors.red.shade600),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showDeleteConfirmation(context, ref, dep, access),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adherence',
                        style: access.getTextStyle(baseSize: 12.0, color: access.textColor.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(dep.adherenceRate * 100).toStringAsFixed(0)}% On-time',
                        style: access.getTextStyle(
                          baseSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Streak',
                        style: access.getTextStyle(baseSize: 12.0, color: access.textColor.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('🔥', style: TextStyle(fontSize: access.scaleText(14.0))),
                          const SizedBox(width: 4),
                          Text(
                            '${dep.streakDays} Days',
                            style: access.getTextStyle(
                              baseSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (dep.adherenceLog.isNotEmpty) ...[
            Text(
              'Today\'s Schedule',
              style: access.getTextStyle(baseSize: 14.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...dep.adherenceLog.map((log) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${log.medicineName} (${log.timeString})',
                        style: access.getTextStyle(
                          baseSize: 14.0,
                          color: log.isTaken ? access.textColor : access.textColor.withOpacity(0.6),
                          height: 1.2,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          log.isTaken ? 'Done' : 'Pending',
                          style: access.getTextStyle(
                            baseSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: log.isTaken ? const Color(0xFF16A34A) : access.textColor.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: log.isTaken,
                            activeColor: const Color(0xFF16A34A),
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
            const SizedBox(height: 12),
          ],
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
              'Show Emergency Card',
              style: access.getTextStyle(
                baseSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, access.minTapTargetSize),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
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
                    backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                    child: Icon(Icons.edit_rounded, color: const Color(0xFF2563EB)),
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
                        backgroundColor: Color(0xFF2563EB),
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

