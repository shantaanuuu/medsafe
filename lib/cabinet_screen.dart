import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';
import 'add_medicine_scan.dart';
import 'medicine_detail.dart';
import 'interaction_graph.dart';
import 'caregiver_dashboard.dart';
import 'symptom_mapper.dart';
import 'pharmacy_fallback.dart';
import 'features/medication_entry/manual/manual_search_screen.dart';
import 'features/caregiver/profile_switcher.dart';
import 'main.dart';

class CabinetScreen extends ConsumerStatefulWidget {
  const CabinetScreen({super.key});

  @override
  ConsumerState<CabinetScreen> createState() => _CabinetScreenState();
}

class _CabinetScreenState extends ConsumerState<CabinetScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final cabinet = ref.watch(cabinetProvider);
    final syncState = ref.watch(syncProvider);
    final activeProfile = ref.watch(activeProfileProvider);
    final caregiverProfile = ref.watch(onboardingProfileProvider).value;
    final userRole = caregiverProfile?.role ?? 'Patient';
    final isCaregiver = userRole == 'Caregiver';
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final userEmail = firebaseUser?.email ?? 'User';
    final userName = activeProfile != null
        ? (activeProfile.nickname ?? 'Dependent')
        : (firebaseUser?.displayName ?? userEmail.split('@')[0]);

    // Initialize accessibility configuration
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);

    // Filter cabinet based on search query
    final filteredCabinet = cabinet.where((med) {
      final nameMatch = med.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final genericMatch = med.genericName.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatch || genericMatch;
    }).toList();

    // Check for urgent warnings (expired or expiring in <= 7 days)
    final now = DateTime.now();
    final urgentAlerts = cabinet.where((med) {
      final diff = med.expiryDate.difference(now).inDays;
      return diff <= 7;
    }).toList();

    return Scaffold(
      backgroundColor: access.backgroundColor,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Drawer Header displaying logged-in user info
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF0F766E), // MedSafe primary teal
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.person, color: Colors.white, size: 40),
              ),
              accountName: Text(
                userName,
                style: access.getTextStyle(baseSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              accountEmail: Text(
                userEmail,
                style: access.getTextStyle(baseSize: 14.0, color: Colors.white.withOpacity(0.8)),
              ),
            ),
            
            // Drawer Menu Items
            ListTile(
              leading: Icon(Icons.inventory_2_outlined, color: access.primaryTeal),
              title: Text('Cabinet Inventory', style: access.getTextStyle(baseSize: 15.0)),
              onTap: () {
                Navigator.pop(context); // close drawer
              },
            ),
            if (isCaregiver)
              ListTile(
                leading: Icon(Icons.people_alt_outlined, color: access.primaryTeal),
                title: Text('Caregiver Dashboard', style: access.getTextStyle(baseSize: 15.0)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CaregiverDashboardScreen()),
                  );
                },
              ),
            ListTile(
              leading: Icon(Icons.hub_outlined, color: access.primaryTeal),
              title: Text('Interaction Graph', style: access.getTextStyle(baseSize: 15.0)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InteractionGraphScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.bubble_chart_outlined, color: access.primaryTeal),
              title: Text('Symptom Mapper', style: access.getTextStyle(baseSize: 15.0)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SymptomMapperScreen()),
                );
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: Text(
                'Logout',
                style: access.getTextStyle(baseSize: 15.0, color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'MEDSAFE',
          style: access.getTextStyle(
            baseSize: 22.0,
            fontWeight: FontWeight.w900,
            color: access.primaryTeal,
          ),
        ),
        actions: [
          // Caregiver Dashboard button
          if (isCaregiver)
            IconButton(
              icon: Icon(Icons.people_alt_outlined, color: access.primaryTeal),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CaregiverDashboardScreen(),
                  ),
                );
              },
              tooltip: 'Caregiver dashboard',
            ),
          // Symptom Mapper button
          IconButton(
            icon: Icon(Icons.bubble_chart_outlined, color: access.primaryTeal),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SymptomMapperScreen(),
                ),
              );
            },
            tooltip: 'Symptom mapper',
          ),
          // Graph link button
          IconButton(
            icon: Icon(Icons.hub_outlined, color: access.primaryTeal),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InteractionGraphScreen(),
                ),
              );
            },
            tooltip: 'View interaction graph',
          ),
          // Elderly Mode Toggle (Simple Mode) in header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Center(
              child: ElderlyModeToggle(
                access: access,
                value: isElderlyMode,
                onChanged: (val) {
                  ref.read(elderlyModeProvider.notifier).toggle();
                },
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(
            color: access.textColor.withOpacity(0.08),
            height: 1.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Disclaimer Banner (non-dismissible strip at the top)
          DisclaimerBanner(access: access),

          // Profile switcher for caregivers
          const ProfileSwitcher(),

          // 2. Offline Sync Banner (displayed when in offline mode)
          if (syncState.isOffline)
            OfflineSyncBanner(
              access: access,
              lastSynced: syncState.lastSynced,
            ),

          // Main Scrollable Area
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: access.scaleSpacing(20.0),
                vertical: access.scaleSpacing(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Caregiver / Patient indicator bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Cabinet',
                            style: access.getTextStyle(
                              baseSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${activeProfile?.id == caregiverProfile?.id ? (userRole == 'Patient' ? 'Patient' : 'Caregiver') : 'Patient'}: $userName',
                            style: access.getTextStyle(
                              baseSize: 14.0,
                              color: access.textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      RoleBadge(access: access, role: activeProfile?.id == caregiverProfile?.id ? userRole : 'Patient'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Simulation panel (Interactive testing controls for demo helper)
                  _buildSimulationPanel(context, ref, syncState, access),
                  const SizedBox(height: 20),

                  // Search Bar
                  _buildSearchBar(access),
                  const SizedBox(height: 24),

                  // Urgent Expiry Warnings Section
                  if (urgentAlerts.isNotEmpty) ...[
                    _buildWarningSection(urgentAlerts, access),
                    const SizedBox(height: 24),
                  ],

                  // Cabinet Inventory Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cabinet Inventory (${filteredCabinet.length})',
                        style: access.getTextStyle(
                          baseSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (syncState.isOffline)
                        Text(
                          'Showing Offline Cache',
                          style: access.getTextStyle(
                            baseSize: 12.0,
                            color: access.warmAmber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Empty State & List
                  if (filteredCabinet.isEmpty)
                    _buildEmptyState(access)
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredCabinet.length,
                      itemBuilder: (context, index) {
                        final medicine = filteredCabinet[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MedicineDetailScreen(medicine: medicine),
                              ),
                            );
                          },
                          child: MedicineCard(
                            access: access,
                            medicine: medicine,
                            onDelete: () {
                              ref.read(cabinetProvider.notifier).removeMedicine(medicine.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${medicine.name} removed from cabinet.'),
                                  backgroundColor: access.textColor,
                                ),
                              );
                            },
                            onTaken: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Dose confirmed for ${medicine.name}. Logged in adherence history.'),
                                  backgroundColor: access.successGreen,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
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
                        'Add New Medication',
                        style: access.getTextStyle(
                          baseSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: access.primaryTeal.withOpacity(0.1),
                          child: Icon(Icons.qr_code_scanner_rounded, color: access.primaryTeal),
                        ),
                        title: Text(
                          'Scan Package',
                          style: access.getTextStyle(baseSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Scan barcode or text using your camera',
                          style: access.getTextStyle(baseSize: 13.0, color: access.textColor.withOpacity(0.5)),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddMedicineScanScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(Icons.edit_note_rounded, color: Colors.blue.shade700),
                        ),
                        title: Text(
                          'Add Manually',
                          style: access.getTextStyle(baseSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Type medicine name to search database',
                          style: access.getTextStyle(baseSize: 13.0, color: access.textColor.withOpacity(0.5)),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManualSearchScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        backgroundColor: access.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: Text(
          'Add Medicine',
          style: access.getTextStyle(
            baseSize: 14.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AccessibilityConfig access) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: access.textColor.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: access.getTextStyle(baseSize: 15.0),
        decoration: InputDecoration(
          hintText: 'Search medicines (e.g. Paracetamol)',
          hintStyle: access.getTextStyle(baseSize: 14.0, color: access.textColor.withOpacity(0.4)),
          prefixIcon: Icon(Icons.search_rounded, color: access.textColor.withOpacity(0.5), size: access.scaleText(22.0)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  // Accessibility: touch target 48dp min guaranteed by constraints or padding
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            vertical: access.scaleSpacing(16.0),
            horizontal: access.scaleSpacing(20.0),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: access.textColor.withOpacity(0.1), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: access.textColor.withOpacity(0.08), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: access.primaryTeal, width: 2.0),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildWarningSection(List<Medicine> urgentAlerts, AccessibilityConfig access) {
    return Container(
      padding: EdgeInsets.all(access.scaleSpacing(16.0)),
      decoration: BoxDecoration(
        color: access.alertRed.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: access.alertRed.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: access.alertRed, size: access.scaleText(22.0)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CRITICAL ALERTS',
                  style: access.getTextStyle(
                    baseSize: 14.0,
                    fontWeight: FontWeight.w900,
                    color: access.alertRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: urgentAlerts.length,
            itemBuilder: (context, index) {
              final med = urgentAlerts[index];
              final diff = med.expiryDate.difference(DateTime.now()).inDays;
              final warningText = diff <= 0
                  ? '${med.name} is EXPIRED. Do not consume!'
                  : '${med.name} expires in $diff days! Dispose/Replace soon.';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: access.alertRed, fontSize: 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            warningText,
                            style: access.getTextStyle(
                              baseSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: access.alertRed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                                ),
                                builder: (context) => PharmacyFallbackBottomSheet(
                                  access: access,
                                  medicine: med,
                                ),
                              );
                            },
                            child: Text(
                              'Find Replacement Pharmacy →',
                              style: access.getTextStyle(
                                baseSize: 12.0,
                                fontWeight: FontWeight.bold,
                                color: access.primaryTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AccessibilityConfig access) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: access.textColor.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: access.textColor.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No medicines in cabinet yet',
            style: access.getTextStyle(
              baseSize: 16.0,
              fontWeight: FontWeight.bold,
              color: access.textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add medicines by scanning the package barcode or uploading an prescription photo scan.',
            textAlign: TextAlign.center,
            style: access.getTextStyle(
              baseSize: 13.0,
              color: access.textColor.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationPanel(
    BuildContext context,
    WidgetRef ref,
    SyncState syncState,
    AccessibilityConfig access,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: access.textColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEMO CONTROLS',
            style: access.getTextStyle(
              baseSize: 11.0,
              fontWeight: FontWeight.w900,
              color: access.primaryTeal,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Toggle connection simulation button
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    ref.read(syncProvider.notifier).toggleConnectivity(!syncState.isOffline);
                  },
                  icon: Icon(
                    syncState.isOffline ? Icons.wifi : Icons.wifi_off,
                    size: access.scaleText(16.0),
                    color: syncState.isOffline ? access.primaryTeal : access.warmAmber,
                  ),
                  label: Text(
                    syncState.isOffline ? 'Connect Online' : 'Simulate Offline',
                    style: access.getTextStyle(
                      baseSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: syncState.isOffline ? access.primaryTeal : access.warmAmber,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: syncState.isOffline
                        ? access.primaryTeal.withOpacity(0.08)
                        : access.warmAmber.withOpacity(0.08),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Add mock medicine button
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    final newMed = Medicine(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: 'Metformin 500mg',
                      genericName: 'Metformin HCl',
                      barcode: '8901043003422',
                      batchNumber: 'MF-7788',
                      expiryDate: DateTime.now().add(const Duration(days: 45)),
                      addedDate: DateTime.now(),
                      dosageForm: 'Tablet',
                      verifiedSource: VerifiedSource.manual,
                    );
                    ref.read(cabinetProvider.notifier).addMedicine(newMed);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Mock Metformin 500mg added to cabinet.'),
                        backgroundColor: access.primaryTeal,
                      ),
                    );
                  },
                  icon: Icon(Icons.add, size: access.scaleText(16.0), color: access.primaryTeal),
                  label: Text(
                    'Add Mock Medicine',
                    style: access.getTextStyle(
                      baseSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: access.primaryTeal,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: access.primaryTeal.withOpacity(0.08),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
