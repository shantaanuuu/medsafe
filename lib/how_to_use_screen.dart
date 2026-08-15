import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'main_dashboard.dart';
import 'interaction_graph.dart';
import 'add_medicine_scan.dart';
import 'dosage_calculator.dart';
import 'risk_profiler.dart';
import 'symptom_mapper.dart';
import 'emergency_card.dart';
import 'caregiver_dashboard.dart';
import 'features/onboarding/onboarding_flow_screen.dart';
import 'main.dart';
import 'shared_states.dart';

class HowToUseScreen extends ConsumerWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isElderly = ref.watch(elderlyModeProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderly);

    return Scaffold(
      backgroundColor: access.backgroundColor,
      appBar: AppBar(
        title: Text(
          'How to Use MedSafe',
          style: access.getTextStyle(
            baseSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE5E7EB),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(access.scaleSpacing(20.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(access),
              SizedBox(height: access.scaleSpacing(32.0)),

              // How MedSafe Works
              _buildSectionTitle('How MedSafe Works', access),
              SizedBox(height: access.scaleSpacing(16.0)),
              _buildHowItWorks(access),
              SizedBox(height: access.scaleSpacing(32.0)),

              // Key Features
              _buildSectionTitle('Explore Features', access),
              SizedBox(height: access.scaleSpacing(16.0)),
              _buildFeaturesGrid(context, access),
              SizedBox(height: access.scaleSpacing(32.0)),

              // Profile Switching Concept
              _buildSectionTitle('Managing Multiple Profiles', access),
              SizedBox(height: access.scaleSpacing(16.0)),
              _buildProfileSwitching(access),
              SizedBox(height: access.scaleSpacing(32.0)),

              // FAQs
              _buildSectionTitle('Frequently Asked Questions', access),
              SizedBox(height: access.scaleSpacing(16.0)),
              _buildFAQs(access),
              SizedBox(height: access.scaleSpacing(32.0)),

              // Disclaimer
              _buildDisclaimer(access),
              SizedBox(height: access.scaleSpacing(24.0)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, AccessibilityConfig access) {
    return Text(
      title,
      style: access.getTextStyle(
        baseSize: 20,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF111827),
      ),
    );
  }

  Widget _buildWelcomeSection(AccessibilityConfig access) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(access.scaleSpacing(20.0)),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 28),
              SizedBox(width: access.scaleSpacing(12.0)),
              Expanded(
                child: Text(
                  'Welcome to MedSafe',
                  style: access.getTextStyle(
                    baseSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: access.scaleSpacing(12.0)),
          Text(
            'MedSafe helps you organize your medicines, monitor medication safety, and ensure you never miss a dose. Our platform is designed for you and your loved ones.',
            style: access.getTextStyle(
              baseSize: 15,
              color: const Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(AccessibilityConfig access) {
    return Container(
      padding: EdgeInsets.all(access.scaleSpacing(20.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          _buildTimelineStep('01', 'Complete your profile', 'Add your age, weight, and allergies.', const Color(0xFF2563EB), const Color(0xFFE8F0FF), access, false),
          _buildTimelineStep('02', 'Add medicines', 'Scan barcodes or add manually.', const Color(0xFF16A34A), const Color(0xFFDDF7E8), access, false),
          _buildTimelineStep('03', 'Manage cabinet', 'Keep track of stock and expiry dates.', const Color(0xFFD97706), const Color(0xFFFEF3C7), access, false),
          _buildTimelineStep('04', 'Check interactions', 'Ensure your medications are safe together.', const Color(0xFFDC2626), const Color(0xFFFEE2E2), access, false),
          _buildTimelineStep('05', 'Stay informed', 'Get alerts for schedules and recalls.', const Color(0xFF9333EA), const Color(0xFFF3E8FF), access, false),
          _buildTimelineStep('06', 'Care for others', 'Switch to dependent profiles as a caregiver.', const Color(0xFF475569), const Color(0xFFF1F5F9), access, true),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String number, String title, String subtitle, Color color, Color bgColor, AccessibilityConfig access, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: access.getTextStyle(
                    baseSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE5E7EB),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                )
              else
                const SizedBox(height: 16),
            ],
          ),
          SizedBox(width: access.scaleSpacing(16.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  title,
                  style: access.getTextStyle(
                    baseSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: access.getTextStyle(
                    baseSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: access.scaleSpacing(16.0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context, AccessibilityConfig access) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                'Medicine Cabinet',
                'View all meds',
                Icons.medication_rounded,
                const Color(0xFFD97706),
                const Color(0xFFFEF3C7),
                () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use the bottom navigation bar to access the Medicine Cabinet')));
                },
                access,
              ),
            ),
            SizedBox(width: access.scaleSpacing(12.0)),
            Expanded(
              child: _buildFeatureCard(
                'Scan Medicine',
                'Add via camera',
                Icons.document_scanner_rounded,
                const Color(0xFF2563EB),
                const Color(0xFFE8F0FF),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMedicineScanScreen())),
                access,
              ),
            ),
          ],
        ),
        SizedBox(height: access.scaleSpacing(12.0)),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                'Interactions',
                'Check drug safety',
                Icons.hub_outlined,
                const Color(0xFFDC2626),
                const Color(0xFFFEE2E2),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InteractionGraphScreen())),
                access,
              ),
            ),
            SizedBox(width: access.scaleSpacing(12.0)),
            Expanded(
              child: _buildFeatureCard(
                'Dosage Calculator',
                'Calculate exactly',
                Icons.calculate_outlined,
                const Color(0xFF16A34A),
                const Color(0xFFDDF7E8),
                () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open a medicine from your cabinet to use the Dosage Calculator')));
                },
                access,
              ),
            ),
          ],
        ),
        SizedBox(height: access.scaleSpacing(12.0)),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                'Recall Alerts',
                'FDA warnings',
                Icons.warning_amber_rounded,
                const Color(0xFFEA580C),
                const Color(0xFFFFEDD5),
                () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use the bottom navigation bar to access Recall Alerts')));
                },
                access,
              ),
            ),
            SizedBox(width: access.scaleSpacing(12.0)),
            Expanded(
              child: _buildFeatureCard(
                'Risk Profiler',
                'Personal safety',
                Icons.analytics_outlined,
                const Color(0xFF9333EA),
                const Color(0xFFF3E8FF),
                () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open a medicine from your cabinet to view its Risk Profile')));
                },
                access,
              ),
            ),
          ],
        ),
        SizedBox(height: access.scaleSpacing(12.0)),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                'Symptom Mapper',
                'Log your symptoms',
                Icons.bubble_chart_outlined,
                const Color(0xFF0D9488),
                const Color(0xFFCCFBF1),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomMapperScreen())),
                access,
              ),
            ),
            SizedBox(width: access.scaleSpacing(12.0)),
            Expanded(
              child: _buildFeatureCard(
                'Emergency Card',
                'Critical info fast',
                Icons.medical_information_outlined,
                const Color(0xFFE11D48),
                const Color(0xFFFFE4E6),
                () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open a dependent to view their Emergency Card')));
                },
                access,
              ),
            ),
          ],
        ),
        SizedBox(height: access.scaleSpacing(12.0)),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                'Your Profile',
                'Manage your details',
                Icons.person_rounded,
                const Color(0xFF475569),
                const Color(0xFFF1F5F9),
                () {
                  Navigator.pop(context);
                },
                access,
              ),
            ),
            SizedBox(width: access.scaleSpacing(12.0)),
            Expanded(
              child: _buildFeatureCard(
                'Caregiver',
                'Manage dependents',
                Icons.supervisor_account_outlined,
                const Color(0xFF2563EB),
                const Color(0xFFE8F0FF),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiverDashboardScreen())),
                access,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, String subtitle, IconData icon, Color iconColor, Color iconBgColor, VoidCallback onTap, AccessibilityConfig access) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(access.scaleSpacing(16.0)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
            Container(
              padding: EdgeInsets.all(access.scaleSpacing(10.0)),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            SizedBox(height: access.scaleSpacing(12.0)),
            Text(
              title,
              style: access.getTextStyle(
                baseSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: access.getTextStyle(
                baseSize: 12,
                color: const Color(0xFF6B7280),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSwitching(AccessibilityConfig access) {
    return Container(
      padding: EdgeInsets.all(access.scaleSpacing(20.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.people_outline, color: Color(0xFF9333EA), size: 28),
          ),
          SizedBox(width: access.scaleSpacing(16.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Caregivers & Dependents',
                  style: access.getTextStyle(
                    baseSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: access.scaleSpacing(8.0)),
                Text(
                  'MedSafe allows Caregivers to manage medications for multiple people (Dependents). When you select a Dependent from the home screen, the entire app switches context to their profile, allowing you to view and manage their medicines safely.',
                  style: access.getTextStyle(
                    baseSize: 14,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQs(AccessibilityConfig access) {
    return Column(
      children: [
        _buildFAQTile(
          'How do I add a new medicine?',
          'You can add a new medicine by navigating to the "Medicine Cabinet" tab and tapping the "+" button, or by using the "Scan Medicine" feature from the home dashboard.',
          access,
        ),
        _buildFAQTile(
          'What happens when a medicine gets recalled?',
          'MedSafe continuously monitors the FDA database. If a medicine in your cabinet matches a recalled batch, you will receive a high-priority alert in the Alerts tab.',
          access,
        ),
        _buildFAQTile(
          'How do I calculate a dosage for my child?',
          'Use the "Dosage Calculator" feature. Enter the child\'s weight and select the medication. MedSafe will provide a safe dosage recommendation based on standard medical guidelines. Always consult your pediatrician.',
          access,
        ),
        _buildFAQTile(
          'Can I share my profile with my doctor?',
          'Yes, you can generate and share an "Emergency Card" which summarizes your health profile, allergies, and current medications.',
          access,
        ),
      ],
    );
  }

  Widget _buildFAQTile(String question, String answer, AccessibilityConfig access) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: access.getTextStyle(
            baseSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111827),
          ),
        ),
        iconColor: const Color(0xFF2563EB),
        collapsedIconColor: const Color(0xFF6B7280),
        childrenPadding: EdgeInsets.fromLTRB(
          access.scaleSpacing(16.0),
          0,
          access.scaleSpacing(16.0),
          access.scaleSpacing(16.0),
        ),
        children: [
          Text(
            answer,
            style: access.getTextStyle(
              baseSize: 14,
              color: const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(AccessibilityConfig access) {
    return Container(
      padding: EdgeInsets.all(access.scaleSpacing(16.0)),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, color: Color(0xFF9CA3AF), size: 20),
          SizedBox(width: access.scaleSpacing(12.0)),
          Expanded(
            child: Text(
              'Medical Disclaimer: MedSafe provides informational support and does not constitute professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider.',
              style: access.getTextStyle(
                baseSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
