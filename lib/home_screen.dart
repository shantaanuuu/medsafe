import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main.dart';
import 'accessibility_config.dart';
import 'add_medicine_scan.dart';
import 'interaction_graph.dart';
import 'symptom_mapper.dart';
import 'features/medication_entry/manual/manual_search_screen.dart';
import 'caregiver_dashboard.dart';
import 'shared_widgets.dart';
import 'models/user_health_profile.dart';
import 'models/medicine_model.dart';
import 'models/medication_schedule.dart';
import 'models/medication_log.dart';
import 'shared_states.dart';
import 'services/api_service.dart';
import 'features/onboarding/onboarding_flow_screen.dart';
import 'medicine_detail.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — Modern light-theme healthcare dashboard
// Business logic (Firebase auth, providers) preserved exactly.
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // ── Greeting helper ────────────────────────────────────────────────────────
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Auth (preserved) ────────────────────────────────────────────────────
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'User';
    final userName = user?.displayName ?? userEmail.split('@')[0];

    // ── Accessibility ────────────────────────────────────────────────────────
    final isElderly = ref.watch(elderlyModeProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderly);

    // ── Health profile ───────────────────────────────────────────────────────
    final authProfileAsync = ref.watch(onboardingProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── 1. TOP HEADER ROW ─────────────────────────────────────────
              _buildHeader(context, userName, access),

              const SizedBox(height: 24),

              if (authProfileAsync.value?.role == 'Caregiver') ...[
                _buildCaregiverDependents(context, ref, access),
                const SizedBox(height: 24),
              ],

              // ── 2. HEALTH PROFILE ─────────────────────────────────────────
              authProfileAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  ),
                ),
                error: (e, s) => const SizedBox.shrink(),
                data: (profile) {
                  final profileToDisplay = activeProfile ?? profile;
                  return profileToDisplay == null
                      ? _buildIncompleteProfile(access)
                      : _buildHealthProfile(profileToDisplay, access);
                },
              ),

              const SizedBox(height: 24),

              // ── 3. QUICK ACTIONS ──────────────────────────────────────────
              authProfileAsync.maybeWhen(
                data: (profile) =>
                    _buildQuickActions(context, profile, access),
                orElse: () => _buildQuickActions(context, null, access),
              ),

              const SizedBox(height: 32),

              // ── 5. CABINET MEDICATIONS ─────────────────────────────────────
              _buildCabinetMedsSection(context, ref, access),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Caregiver Dependents Section
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCaregiverDependents(
      BuildContext context, WidgetRef ref, AccessibilityConfig access) {
    final dependents = ref.watch(dependentProvider);
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'User';
    final userName = user?.displayName ?? userEmail.split('@')[0];
    final authProfileAsync = ref.watch(onboardingProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);
    
    if (dependents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'No dependents yet. Add someone you care for...',
              style: access.getTextStyle(
                baseSize: 14,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingFlowScreen(isAddingDependent: true),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: Text(
                'Add Dependent',
                style: access.getTextStyle(
                  baseSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'People you care for',
          style: access.getTextStyle(
            baseSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              // Self (Caregiver) Card
              (() {
                final bool isSelfSelected = activeProfile == null || activeProfile.id == authProfileAsync.value?.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(activeProfileProvider.notifier).setActiveProfile(authProfileAsync.value);
                    },
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelfSelected ? const Color(0xFFE8F0FF) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelfSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                          width: isSelfSelected ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFDCFCE7),
                            child: Icon(
                              Icons.admin_panel_settings_rounded,
                              color: isSelfSelected ? const Color(0xFF16A34A) : const Color(0xFF16A34A).withOpacity(0.7),
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userName,
                            style: access.getTextStyle(
                              baseSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Self',
                            style: access.getTextStyle(
                              baseSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Caregiver',
                            style: access.getTextStyle(
                              baseSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              })(),
              ...dependents.map((dep) {
                final String initial = dep.name.isNotEmpty ? dep.name[0].toUpperCase() : '?';
                final bool isSelected = activeProfile?.id == dep.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      final profiles = ref.read(allProfilesProvider).value ?? [];
                      final depProfile = profiles.firstWhere((p) => p.id == dep.id);
                      ref.read(activeProfileProvider.notifier).setActiveProfile(depProfile);
                    },
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE8F0FF) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFE8F0FF),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dep.name,
                            style: access.getTextStyle(
                              baseSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Dependent',
                            style: access.getTextStyle(
                              baseSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${dep.adherenceLog.length} medicines',
                            style: access.getTextStyle(
                              baseSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OnboardingFlowScreen(isAddingDependent: true),
                    ),
                  );
                },
                child: Container(
                  width: 140,
                  height: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB), size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Add Dependent',
                        style: access.getTextStyle(
                          baseSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Header
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, String userName, AccessibilityConfig access) {
    return Row(
      children: [
        // Avatar
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFF2563EB),
          child: Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),

        // Greeting + name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: access.getTextStyle(
                  baseSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Text(
                'Hello, $userName 👋',
                style: access.getTextStyle(
                  baseSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),

        // Notification Bell icon
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF6B7280),
              size: 20,
            ),
            onPressed: () {
              // Notifications logic will go here
            },
            tooltip: 'Notifications',
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Health Profile Card (Incomplete)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildIncompleteProfile(AccessibilityConfig access) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Health Profile',
          style: access.getTextStyle(
            baseSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const PastelIconContainer(
                icon: Icons.person_add_alt_1_outlined,
                iconColor: Color(0xFF2563EB),
                backgroundColor: Color(0xFFE8F0FF),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete your profile',
                      style: access.getTextStyle(
                        baseSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Add your basic details to personalize your experience.',
                      style: access.getTextStyle(
                        baseSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Health Profile Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHealthProfile(
      UserHealthProfile profile, AccessibilityConfig access) {
    final hasStats = profile.age != null ||
        profile.weightKg != null ||
        (profile.sex != null && profile.sex != 'Prefer not to say');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Text(
              'Your Health Profile',
              style: access.getTextStyle(
                baseSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 12),

        // Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Identity layout
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE8F0FF),
                    child: Text(
                      (profile.nickname?.isNotEmpty == true) 
                          ? profile.nickname![0].toUpperCase() 
                          : 'P',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.nickname ?? 'Patient',
                        style: access.getTextStyle(
                          baseSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        profile.role,
                        style: access.getTextStyle(
                          baseSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Stats row (age / weight / sex)
              if (hasStats) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (profile.age != null)
                      Expanded(
                        child: _statBox(
                          label: 'Age',
                          value: '${profile.age}',
                          icon: Icons.cake_outlined,
                          iconColor: const Color(0xFF2563EB),
                          bgColor: const Color(0xFFE8F0FF),
                          access: access,
                        ),
                      ),
                    if (profile.weightKg != null)
                      Expanded(
                        child: _statBox(
                          label: 'Weight',
                          value: '${profile.weightKg?.toStringAsFixed(1)} kg',
                          icon: Icons.monitor_weight_outlined,
                          iconColor: const Color(0xFF16A34A),
                          bgColor: const Color(0xFFDDF7E8),
                          access: access,
                        ),
                      ),
                    if (profile.sex != null &&
                        profile.sex != 'Prefer not to say')
                      Expanded(
                        child: _statBox(
                          label: 'Sex',
                          value: profile.sex!,
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFF64748B),
                          bgColor: const Color(0xFFEEF1F5),
                          access: access,
                        ),
                      ),
                  ],
                ),
              ],

              // Chronic conditions
              if (profile.chronicConditions.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Conditions',
                  style: access.getTextStyle(
                    baseSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: profile.chronicConditions
                      .map((c) => _chip(
                            label: c,
                            textColor: const Color(0xFF2563EB),
                            bgColor: const Color(0xFFE8F0FF),
                            access: access,
                          ))
                      .toList(),
                ),
              ],

              // Allergies
              if (profile.allergies.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Allergies',
                  style: access.getTextStyle(
                    baseSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: profile.allergies
                      .map((a) => _chip(
                            label: a,
                            textColor: const Color(0xFFDC2626),
                            bgColor: const Color(0xFFFEF2F2),
                            access: access,
                          ))
                      .toList(),
                ),
              ],

              // Current medications
              if (profile.currentMedications.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Current Medications',
                  style: access.getTextStyle(
                    baseSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: profile.currentMedications
                      .map((m) => _chip(
                            label: m.medicineName,
                            textColor: const Color(0xFF16A34A),
                            bgColor: const Color(0xFFDDF7E8),
                            access: access,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Stat box helper (age / weight / sex)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _statBox({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required AccessibilityConfig access,
  }) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: access.getTextStyle(
              baseSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: access.getTextStyle(
              baseSize: 11,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Chip helper
  // ───────────────────────────────────────────────────────────────────────────
  Widget _chip({
    required String label,
    required Color textColor,
    required Color bgColor,
    required AccessibilityConfig access,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: access.getTextStyle(
          baseSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Quick Actions section
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActions(
    BuildContext context,
    UserHealthProfile? profile,
    AccessibilityConfig access,
  ) {
    final isCaregiver = profile?.role == 'Caregiver';

    // Build the action list
    final actions = <_QuickAction>[
      _QuickAction(
        title: 'Scan Medicine',
        subtitle: 'Barcode & QR scanner',
        icon: Icons.qr_code_scanner_rounded,
        iconColor: const Color(0xFF2563EB),
        iconBgColor: const Color(0xFFE8F0FF),
        onTap: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const AddMedicineScanScreen()),
        ),
      ),
      _QuickAction(
        title: 'Drug Interaction',
        subtitle: 'Check interactions',
        icon: Icons.hub_outlined,
        iconColor: const Color(0xFF16A34A),
        iconBgColor: const Color(0xFFDDF7E8),
        onTap: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const InteractionGraphScreen()),
        ),
      ),
      _QuickAction(
        title: 'Symptom Mapper',
        subtitle: 'Map & track symptoms',
        icon: Icons.bubble_chart_outlined,
        iconColor: const Color(0xFF16A34A),
        iconBgColor: const Color(0xFFDDF7E8),
        onTap: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const SymptomMapperScreen()),
        ),
      ),
      _QuickAction(
        title: 'Manual Search',
        subtitle: 'Search by name',
        icon: Icons.edit_note_rounded,
        iconColor: const Color(0xFF64748B),
        iconBgColor: const Color(0xFFEEF1F5),
        onTap: (ctx) => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => const ManualSearchScreen()),
        ),
      ),
      if (isCaregiver)
        _QuickAction(
          title: 'Caregiver Dashboard',
          subtitle: 'Manage dependents',
          icon: Icons.supervisor_account_outlined,
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFE8F0FF),
          onTap: (ctx) => Navigator.push(
            ctx,
            MaterialPageRoute(
                builder: (_) => const CaregiverDashboardScreen()),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Text(
              'Quick Actions',
              style: access.getTextStyle(
                baseSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const Spacer(),
            Text(
              '${actions.length} tools',
              style: access.getTextStyle(
                baseSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grid — 2-column layout using paired rows
        ...List.generate(
          (actions.length / 2).ceil(),
          (rowIndex) {
            final left = actions[rowIndex * 2];
            final rightIndex = rowIndex * 2 + 1;
            final right =
                rightIndex < actions.length ? actions[rightIndex] : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: QuickActionCard(
                      title: left.title,
                      subtitle: left.subtitle,
                      icon: left.icon,
                      iconColor: left.iconColor,
                      iconBgColor: left.iconBgColor,
                      onTap: () => left.onTap(context),
                      access: access,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (right != null)
                    Expanded(
                      child: QuickActionCard(
                        title: right.title,
                        subtitle: right.subtitle,
                        icon: right.icon,
                        iconColor: right.iconColor,
                        iconBgColor: right.iconBgColor,
                        onTap: () => right.onTap(context),
                        access: access,
                      ),
                    )
                  else
                    // Empty spacer to keep left card half-width when odd count
                    const Expanded(child: SizedBox.shrink()),
                ],
              ),
            );
          },
        ),
      ],
    );
  }


  // ───────────────────────────────────────────────────────────────────────────
  // Dashboard Overview
  // ───────────────────────────────────────────────────────────────────────────
  // Cabinet Medications Section
  // ───────────────────────────────────────────────────────────────────────────
  static const Color _kPrimaryBlue   = Color(0xFF2563EB);
  static const Color _kBlueLight     = Color(0xFFE8F0FF);
  static const Color _kTextPrimary   = Color(0xFF111827);
  static const Color _kTextSecond    = Color(0xFF6B7280);
  static const Color _kIconMuted     = Color(0xFF9CA3AF);
  static const Color _kCardBorder    = Color(0xFFE5E7EB);

  Widget _buildCabinetMedsSection(BuildContext context, WidgetRef ref, AccessibilityConfig access) {
    final cabinet = ref.watch(cabinetProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Medicine Cabinet',
          style: access.getTextStyle(
            baseSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 16),
        if (cabinet.isEmpty)
          _buildEmptyCabinetState(context, access)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cabinet.length,
            itemBuilder: (context, index) {
              final medicine = cabinet[index];
              return _buildMedicineCardItem(medicine, access, ref, context);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyCabinetState(BuildContext context, AccessibilityConfig access) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.medication_outlined, size: 48, color: _kIconMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            'Your cabinet is empty',
            style: access.getTextStyle(baseSize: 15.0, fontWeight: FontWeight.bold, color: _kTextPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your medications to track their details.',
            textAlign: TextAlign.center,
            style: access.getTextStyle(baseSize: 13.0, color: _kTextSecond),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCardItem(Medicine medicine, AccessibilityConfig access, WidgetRef ref, BuildContext context) {
    final diff = medicine.expiryDate.difference(DateTime.now()).inDays;
    
    String statusText;
    Color statusBg;
    Color statusColor;

    if (diff < 0) {
      statusText = 'Expired';
      statusBg = const Color(0xFFFEF2F2);
      statusColor = const Color(0xFFDC2626);
    } else if (diff <= 30) {
      statusText = 'Expiring Soon';
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFD97706);
    } else {
      statusText = 'Safe';
      statusBg = const Color(0xFFD1FAE5);
      statusColor = const Color(0xFF16A34A);
    }

    final schedulesAsync = ref.watch(schedulesProvider);
    final scheduleList = schedulesAsync.value ?? [];
    MedicationSchedule? schedule;
    for (var s in scheduleList) {
      if (s.cabinetItemId == medicine.id) {
        schedule = s;
        break;
      }
    }

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final logsAsync = ref.watch(logsProvider(todayStr));
    final logsList = logsAsync.value ?? [];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicineDetailScreen(medicine: medicine),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kCardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _kBlueLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.medication_rounded, color: _kPrimaryBlue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: access.getTextStyle(
                          baseSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: _kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        medicine.genericName,
                        style: access.getTextStyle(
                          baseSize: 13.0,
                          color: _kTextSecond,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 14, color: _kIconMuted),
                          const SizedBox(width: 4),
                          Text(
                            medicine.dosageForm ?? 'Tablet',
                            style: access.getTextStyle(baseSize: 12.0, color: _kTextSecond),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.event_outlined, size: 14, color: _kIconMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Exp: ${medicine.expiryDate.month}/${medicine.expiryDate.year}',
                            style: access.getTextStyle(baseSize: 12.0, color: _kTextSecond),
                          ),
                        ],
                      ),
                      if (schedule != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: access.primaryTeal),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${schedule.frequencyPerDay} times/day',
                                    style: access.getTextStyle(
                                      baseSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                      color: access.textColor,
                                    ),
                                  ),
                                  Text(
                                    schedule.scheduledTimes.join(' • '),
                                    style: access.getTextStyle(
                                      baseSize: 11.0,
                                      color: access.textColor.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (schedule != null) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Text(
                          'Daily Dose Checklist',
                          style: access.getTextStyle(
                            baseSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: access.textColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...schedule.scheduledTimes.map((timeStr) {
                          final isTaken = logsList.any((l) =>
                              l.cabinetItemId == medicine.id &&
                              l.doseTime == timeStr &&
                              l.taken);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isTaken
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      size: 16,
                                      color: isTaken
                                          ? access.primaryTeal
                                          : access.textColor.withOpacity(0.4),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      timeStr,
                                      style: access.getTextStyle(
                                        baseSize: 13.0,
                                        fontWeight: isTaken ? FontWeight.bold : FontWeight.normal,
                                        color: isTaken ? access.primaryTeal : access.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
                                    value: isTaken,
                                    activeColor: access.primaryTeal,
                                    activeTrackColor: access.primaryTeal.withOpacity(0.2),
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: access.textColor.withOpacity(0.08),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (val) async {
                                      final user = FirebaseAuth.instance.currentUser;
                                      if (user == null) return;
                                      final activeProfile = ref.read(activeProfileProvider);
                                      final caregiverProfile = ref.read(onboardingProfileProvider).value;
                                      final String? dependentId = (activeProfile != null && caregiverProfile != null && activeProfile.id != caregiverProfile.id)
                                          ? activeProfile.id
                                          : null;

                                      final log = MedicationLog(
                                        id: '${medicine.id}_${timeStr}_$todayStr',
                                        cabinetItemId: medicine.id,
                                        dependentId: dependentId,
                                        userUid: user.uid,
                                        doseTime: timeStr,
                                        takenDate: todayStr,
                                        taken: val,
                                      );

                                      try {
                                        await ref.read(apiServiceProvider).saveLog(log);
                                        ref.invalidate(logsProvider(todayStr));
                                      } catch (e) {
                                        debugPrint("TOGGLE DOSE ERROR: $e");
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: access.getTextStyle(
                      baseSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: _kCardBorder),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCompactAction(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: _kTextPrimary,
                  onTap: () {},
                  access: access,
                ),
                _buildCompactAction(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: const Color(0xFFDC2626),
                  onTap: () {
                    ref.read(cabinetProvider.notifier).removeMedicine(medicine.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${medicine.name} removed from cabinet.'),
                        backgroundColor: access.textColor,
                      ),
                    );
                  },
                  access: access,
                ),
                _buildCompactAction(
                  icon: Icons.notifications_none_rounded,
                  label: 'Reminder',
                  color: _kPrimaryBlue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Dose confirmed for ${medicine.name}. Logged in adherence history.'),
                        backgroundColor: access.successGreen,
                      ),
                    );
                  },
                  access: access,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required AccessibilityConfig access,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: access.getTextStyle(
                baseSize: 13.0,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal data class for quick actions (not exposed outside)
// ─────────────────────────────────────────────────────────────────────────────
class _QuickAction {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final void Function(BuildContext) onTap;

  const _QuickAction({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });
}

