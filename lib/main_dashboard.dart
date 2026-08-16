import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_screen.dart';
import 'cabinet_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';
import 'add_medicine_scan.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'features/medication_entry/manual/manual_search_screen.dart';
import 'features/chatbot/widgets/chatbot_overlay.dart';
import 'features/chatbot/providers/chatbot_provider.dart';

class MainDashboard extends ConsumerStatefulWidget {
  const MainDashboard({super.key});

  @override
  ConsumerState<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends ConsumerState<MainDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SizedBox(), // Placeholder for Scan (handled in onTap)
    const AlertsScreen(),
    const CabinetScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 1) {
      // Trigger Scan Bottom Sheet
      final access = AccessibilityConfig(isElderlyMode: ref.read(elderlyModeProvider));
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildScanBottomSheet(context, access),
      );
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildScanBottomSheet(BuildContext context, AccessibilityConfig access) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add New Medication',
              style: access.getTextStyle(
                baseSize: 18.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F0FF),
                child: Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2563EB)),
              ),
              title: Text(
                'Scan Package or Barcode',
                style: access.getTextStyle(baseSize: 16.0, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Use camera to scan medicine box',
                style: access.getTextStyle(baseSize: 13.0, color: const Color(0xFF6B7280)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddMedicineScanScreen()),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFDCFCE7),
                child: Icon(Icons.edit_note_rounded, color: Color(0xFF16A34A)),
              ),
              title: Text(
                'Add Manually',
                style: access.getTextStyle(baseSize: 16.0, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Type medicine name to search database',
                style: access.getTextStyle(baseSize: 13.0, color: const Color(0xFF6B7280)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManualSearchScreen()),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String screenName = 'Home Screen';
      if (_currentIndex == 2) {
        screenName = 'Alerts Screen';
      } else if (_currentIndex == 3) {
        final medsCount = ref.read(cabinetProvider).length;
        screenName = 'Cabinet Screen ($medsCount medicines)';
      } else if (_currentIndex == 4) {
        screenName = 'Profile Screen';
      }
      ref.read(currentScreenProvider.notifier).setScreen(screenName);
    });

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 1 ? 0 : _currentIndex, // fallback if scan is selected somehow
        children: _screens,
      ),
      floatingActionButton: const ChatbotOverlayButton(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_rounded)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.center_focus_weak_rounded)),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.notifications_rounded)),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.medication_rounded)),
              label: 'Cabinet',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
