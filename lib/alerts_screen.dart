import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'pharmacy_fallback.dart';
import 'services/notification_service.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  @override
  Widget build(BuildContext context) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final cabinet = ref.watch(cabinetProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);

    final now = DateTime.now();
    final urgentAlerts = cabinet.where((med) {
      final diff = med.expiryDate.difference(now).inDays;
      return diff <= 7;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        iconTheme: IconThemeData(color: access.textColor),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: access.pastelRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: access.alertRed,
                size: access.scaleText(20.0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alerts & Notifications',
                    style: access.getTextStyle(
                      baseSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: access.textColor,
                    ),
                  ),
                  Text(
                    '${urgentAlerts.length} urgent notices',
                    style: access.getTextStyle(
                      baseSize: 13.0,
                      color: urgentAlerts.isEmpty ? access.secondaryTextColor : access.alertRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(access.scaleSpacing(16.0)),
          children: [
            _buildNotificationHubCard(context, access),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 20,
                  color: access.textColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cabinet Safety & Recalls',
                  style: access.getTextStyle(
                    baseSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: access.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (urgentAlerts.isEmpty)
              _buildEmptyState(access)
            else
              ...urgentAlerts.map((med) => _buildAlertCard(med, access)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationHubCard(BuildContext context, AccessibilityConfig access) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'MedSafe Alarm Hub',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(radius: 3, backgroundColor: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'High-priority daily dose alarms & cabinet expiry protection.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFFE0E7FF),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          const Text(
            'TEST NOTIFICATIONS ON THIS DEVICE:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFFBFDBFE),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final notif = ref.read(notificationServiceProvider);
                      await notif.showInstantNotification(
                        id: 777,
                        title: '💊 Dose Reminder: Amoxicillin 500mg',
                        body: "It's 08:00 AM. Please take 1 capsule after breakfast with water.",
                        subtext: 'Scheduled Morning Dose',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text('🔔 Dose Reminder sent! Swipe down status bar.'),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF2563EB),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Notification test failed: $e');
                    }
                  },
                  icon: const Icon(Icons.alarm_on_rounded, size: 18),
                  label: const Text('Test Dose Alarm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final notif = ref.read(notificationServiceProvider);
                      final testExpiry = DateTime.now().add(const Duration(days: 2));
                      await notif.checkAndScheduleExpiryAlert(
                        id: 888,
                        medicineName: 'Paracetamol 650mg',
                        expiryDate: testExpiry,
                        fireInstantIfUrgent: true,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.warning_amber, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text('⚠️ 2-Day Expiry Alert sent! Check status bar.'),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFFDC2626),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Notification test failed: $e');
                    }
                  },
                  icon: const Icon(Icons.warning_rounded, size: 18),
                  label: const Text('Test 2-Day Expiry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                final meds = ref.read(cabinetProvider);
                if (meds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cabinet is empty. Add a medicine first.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                final notif = ref.read(notificationServiceProvider);
                int triggered = 0;
                for (final m in meds) {
                  final diff = m.expiryDate.difference(DateTime.now()).inDays;
                  if (diff <= 7) triggered++;
                  final alertId = (m.id.hashCode + 8888).abs() % 100000;
                  await notif.checkAndScheduleExpiryAlert(
                    id: alertId,
                    medicineName: m.name,
                    expiryDate: m.expiryDate,
                    fireInstantIfUrgent: true,
                  );
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        triggered > 0
                          ? '🔍 Scanned ${meds.length} medicines: $triggered urgent alerts sent to status bar!'
                          : '✅ Scanned ${meds.length} medicines: All current items are safe.',
                      ),
                      backgroundColor: triggered > 0 ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Scan & Alert Cabinet Expiries Now',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AccessibilityConfig access) {
    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: access.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: access.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: access.pastelGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: access.successGreen,
              size: access.scaleText(56.0),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "Cabinet Is Safe\nNo Active Recalls or Expired Drugs",
            textAlign: TextAlign.center,
            style: access.getTextStyle(
              baseSize: 18.0,
              fontWeight: FontWeight.bold,
              color: access.textColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "MedSafe monitors batch safety and expiration in the background.",
            textAlign: TextAlign.center,
            style: access.getTextStyle(
              baseSize: 13.0,
              color: access.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(dynamic medicine, AccessibilityConfig access) {
    final diff = medicine.expiryDate.difference(DateTime.now()).inDays;
    final isExpired = diff <= 0;
    
    final statusText = isExpired ? 'Class I' : 'Class II';
    final statusColor = isExpired ? access.alertRed : access.warmAmber;
    final statusBg = isExpired ? access.pastelRed : access.pastelYellow;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: access.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: access.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpired ? Icons.cancel_rounded : Icons.info_rounded,
                        color: statusColor,
                        size: access.scaleText(14.0),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$statusText Active',
                        style: access.getTextStyle(
                          baseSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Exp: ${medicine.expiryDate.month}/${medicine.expiryDate.year}',
                  style: access.getTextStyle(
                    baseSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: access.secondaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              medicine.name,
              style: access.getTextStyle(
                baseSize: 18.0,
                fontWeight: FontWeight.bold,
                color: access.textColor,
              ),
            ),
            if (medicine.medicineDesc != null && medicine.medicineDesc!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                medicine.medicineDesc!,
                style: access.getTextStyle(
                  baseSize: 14.0,
                  color: access.secondaryTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(cabinetProvider.notifier).removeMedicine(medicine.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${medicine.name} removed.'),
                          backgroundColor: access.textColor,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: access.alertRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Dispose',
                      style: access.getTextStyle(
                        baseSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => PharmacyFallbackBottomSheet(access: access, medicine: medicine),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: access.pastelGray,
                      foregroundColor: access.textColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Learn More',
                      style: access.getTextStyle(
                        baseSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: access.textColor,
                      ),
                    ),
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
