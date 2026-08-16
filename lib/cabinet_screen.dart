import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';
import 'add_medicine_scan.dart';
import 'medicine_detail.dart';
import 'pharmacy_fallback.dart';
import 'features/medication_entry/manual/manual_search_screen.dart';
import 'models/medication_schedule.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kBackground   = Color(0xFFF8FAFC);
const _kPrimaryBlue  = Color(0xFF2563EB);
const _kCardBorder   = Color(0xFFE5E7EB);
const _kTextPrimary  = Color(0xFF111827);
const _kTextSecond   = Color(0xFF6B7280);
const _kIconMuted    = Color(0xFF9CA3AF);
const _kSearchFill   = Color(0xFFF1F5F9);
const _kAlertBg      = Color(0xFFFEF2F2);
const _kAlertBorder  = Color(0xFFFCA5A5);
const _kBlueLight    = Color(0xFFE8F0FF);
const _kGreenLight   = Color(0xFFD1FAE5);
const _kGreenIcon    = Color(0xFF059669);
// ──────────────────────────────────────────────────────────────────────────────

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
    // Watch providers (Logic preserved strictly)
    final isElderlyMode     = ref.watch(elderlyModeProvider);
    final cabinet           = ref.watch(cabinetProvider);
    final syncState         = ref.watch(syncProvider);

    // Initialize accessibility configuration
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);

    // Filter cabinet based on search query
    final filteredCabinet = cabinet.where((med) {
      final nameMatch    = med.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final genericMatch = med.genericName.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatch || genericMatch;
    }).toList();

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medicine Cabinet',
              style: access.getTextStyle(
                baseSize: 24.0,
                fontWeight: FontWeight.bold,
                color: _kTextPrimary,
              ),
            ),
            Text(
              '${filteredCabinet.length} medicines stored',
              style: access.getTextStyle(
                baseSize: 14.0,
                color: _kTextSecond,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () => _showAddMedicineBottomSheet(context, access),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _kPrimaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: access.scaleSpacing(20.0),
            vertical:   access.scaleSpacing(16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(access),
              const SizedBox(height: 24),

              if (syncState.isOffline)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: OfflineSyncBanner(access: access, lastSynced: syncState.lastSynced),
                ),
              
              if (filteredCabinet.isEmpty)
                _buildEmptyState(access)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredCabinet.length,
                  itemBuilder: (context, index) {
                    final medicine = filteredCabinet[index];
                    return _buildMedicineCardItem(medicine, access, ref, context);
                  },
                ),
            ],
          ),
        ),
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



  // 2. SEARCH
  Widget _buildSearchBar(AccessibilityConfig access) {
    return Container(
      decoration: BoxDecoration(
        color: _kSearchFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        style: access.getTextStyle(baseSize: 15.0, color: _kTextPrimary),
        decoration: InputDecoration(
          hintText: 'Search medicines...',
          hintStyle: access.getTextStyle(baseSize: 15.0, color: _kIconMuted),
          prefixIcon: Icon(Icons.search_rounded,
              color: _kIconMuted, size: access.scaleText(22.0)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: _kIconMuted),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(
            vertical: access.scaleSpacing(16.0),
            horizontal: access.scaleSpacing(20.0),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
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


  // ── FAB BOTTOM SHEET ──────────────────────────────────────────────────────
  void _showAddMedicineBottomSheet(BuildContext context, AccessibilityConfig access) {
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
                    color: _kCardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Add New Medication',
                  style: access.getTextStyle(
                    baseSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: _kBlueLight,
                    child: Icon(Icons.qr_code_scanner_rounded, color: _kPrimaryBlue),
                  ),
                  title: Text(
                    'Scan Package',
                    style: access.getTextStyle(baseSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Scan barcode or text using your camera',
                    style: access.getTextStyle(baseSize: 13.0, color: _kTextSecond),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddMedicineScanScreen()),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: _kGreenLight,
                    child: Icon(Icons.edit_note_rounded, color: _kGreenIcon),
                  ),
                  title: Text(
                    'Add Manually',
                    style: access.getTextStyle(baseSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Type medicine name to search database',
                    style: access.getTextStyle(baseSize: 13.0, color: _kTextSecond),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManualSearchScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AccessibilityConfig access) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64, color: _kIconMuted),
          const SizedBox(height: 16),
          Text(
            'No medicines in cabinet yet',
            style: access.getTextStyle(
              baseSize: 16.0,
              fontWeight: FontWeight.bold,
              color: _kTextSecond,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add medicines by scanning the package barcode or uploading an prescription photo scan.',
            textAlign: TextAlign.center,
            style: access.getTextStyle(baseSize: 13.0, color: _kIconMuted),
          ),
        ],
      ),
    );
  }

}
