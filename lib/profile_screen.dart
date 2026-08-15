import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'main.dart';
import 'how_to_use_screen.dart';
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final profileAsync = ref.watch(onboardingProfileProvider);
    final isElderly = ref.watch(elderlyModeProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderly);

    final String email = user?.email ?? 'No email';
    final String phone = user?.phoneNumber ?? '';
    
    // Attempt to get name from UserHealthProfile, then Firebase, then fallback
    String name = 'User';
    profileAsync.whenData((profile) {
      if (profile != null && profile.nickname != null && profile.nickname!.isNotEmpty) {
        name = profile.nickname!;
      }
    });
    if (name == 'User' && user?.displayName != null && user!.displayName!.isNotEmpty) {
      name = user.displayName!;
    }

    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: access.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(access.scaleSpacing(16.0)),
          child: Column(
            children: [
              SizedBox(height: access.scaleSpacing(16.0)),
              // HEADER
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: access.scaleSpacing(40.0),
                      backgroundColor: access.primaryBlue,
                      child: Text(
                        initial,
                        style: access.headerText.copyWith(
                          color: Colors.white,
                          fontSize: access.scaleText(32.0),
                        ),
                      ),
                    ),
                    SizedBox(height: access.scaleSpacing(16.0)),
                    Text(
                      name,
                      style: access.headerText,
                    ),
                    SizedBox(height: access.scaleSpacing(4.0)),
                    Text(
                      email,
                      style: access.bodyText.copyWith(color: access.secondaryTextColor),
                    ),
                    if (phone.isNotEmpty) ...[
                      SizedBox(height: access.scaleSpacing(4.0)),
                      Text(
                        phone,
                        style: access.bodyText.copyWith(color: access.secondaryTextColor),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: access.scaleSpacing(32.0)),

              // SETTINGS LIST
              Container(
                decoration: BoxDecoration(
                  color: access.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: access.borderColor),
                ),
                child: Column(
                  children: [
                    _buildListTile(
                      access: access,
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      onTap: () => _showComingSoon(context),
                    ),
                    _buildDivider(access),
                    _buildListTile(
                      access: access,
                      icon: Icons.medical_services_outlined,
                      title: 'Medical Information',
                      onTap: () => _showComingSoon(context),
                    ),
                    _buildDivider(access),
                    _buildListTile(
                      access: access,
                      icon: Icons.language_outlined,
                      title: 'Language Settings',
                      onTap: () => _showComingSoon(context),
                    ),
                    _buildDivider(access),
                    ListTile(
                      leading: Icon(Icons.accessibility_new, color: access.primaryBlue),
                      title: Text('Elderly Mode', style: access.bodyText),
                      trailing: Switch(
                        value: isElderly,
                        onChanged: (val) {
                          ref.read(elderlyModeProvider.notifier).toggle();
                        },
                        activeColor: access.primaryBlue,
                      ),
                    ),
                    _buildDivider(access),
                    _buildListTile(
                      access: access,
                      icon: Icons.contact_emergency_outlined,
                      title: 'Emergency Contacts',
                      onTap: () => _showComingSoon(context),
                    ),
                    _buildDivider(access),
                    _buildListTile(
                      access: access,
                      icon: Icons.lock_outline,
                      title: 'Privacy Settings',
                      onTap: () => _showComingSoon(context),
                    ),
                    _buildDivider(access),
                    _buildListTile(
                      access: access,
                      icon: Icons.notifications_outlined,
                      title: 'Notification Settings',
                      onTap: () => _showComingSoon(context),
                    ),
                  ],
                ),
              ),
              SizedBox(height: access.scaleSpacing(32.0)),

              // HELP & SUPPORT
              Container(
                decoration: BoxDecoration(
                  color: access.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: access.borderColor),
                ),
                child: Column(
                  children: [
                    _buildListTile(
                      access: access,
                      icon: Icons.help_outline,
                      title: 'How to Use MedSafe',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HowToUseScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: access.scaleSpacing(32.0)),

              // LOGOUT
              SizedBox(
                width: double.infinity,
                height: access.minTapTargetSize,
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
                  label: Text(
                    'Logout',
                    style: access.labelText.copyWith(color: const Color(0xFFDC2626)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE2E2), // Very light red/pink
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: access.scaleSpacing(32.0)),

              // FOOTER
              Text(
                'MedSafe v1.0.0 · AI-Powered',
                style: access.captionText,
              ),
              SizedBox(height: access.scaleSpacing(16.0)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required AccessibilityConfig access,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: access.primaryBlue),
      title: Text(title, style: access.bodyText),
      trailing: Icon(Icons.chevron_right, color: access.secondaryTextColor),
      onTap: onTap,
    );
  }

  Widget _buildDivider(AccessibilityConfig access) {
    return Divider(height: 1, color: access.borderColor, indent: 16, endIndent: 16);
  }
}
