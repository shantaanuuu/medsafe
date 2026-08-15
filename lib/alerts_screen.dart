import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'pharmacy_fallback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                    'Drug Recall Alerts',
                    style: access.getTextStyle(
                      baseSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: access.textColor,
                    ),
                  ),
                  Text(
                    '${urgentAlerts.length} active recalls',
                    style: access.getTextStyle(
                      baseSize: 14.0,
                      color: access.alertRed,
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
        child: urgentAlerts.isEmpty
            ? _buildEmptyState(access)
            : ListView.builder(
                padding: EdgeInsets.all(access.scaleSpacing(20.0)),
                itemCount: urgentAlerts.length,
                itemBuilder: (context, index) {
                  return _buildAlertCard(urgentAlerts[index], access);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(AccessibilityConfig access) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: access.pastelGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                color: access.successGreen,
                size: access.scaleText(64.0),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No active recalls.\nYou're all caught up.",
              textAlign: TextAlign.center,
              style: access.getTextStyle(
                baseSize: 20.0,
                fontWeight: FontWeight.bold,
                color: access.textColor,
                height: 1.3,
              ),
            ),
          ],
        ),
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
            color: Colors.black.withOpacity(0.03),
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
