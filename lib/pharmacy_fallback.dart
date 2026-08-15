import 'package:flutter/material.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';

class PharmacyFallbackBottomSheet extends StatelessWidget {
  final AccessibilityConfig access;
  final Medicine medicine;

  const PharmacyFallbackBottomSheet({
    super.key,
    required this.access,
    required this.medicine,
  });

  // Mock nearby Indian pharmacies data based on Indian medical context
  List<Map<String, String>> _getMockPharmacies() {
    return [
      {
        'name': 'Apollo Pharmacy',
        'address': 'G-4, Market Pocket 1, Sector 12, Dwarka, New Delhi',
        'distance': '0.8 km',
        'phone': '+91 11 4567 8901',
      },
      {
        'name': 'MedPlus Pharmacy',
        'address': 'Shop 12, Central Plaza, Dwarka Sector 6, New Delhi',
        'distance': '1.4 km',
        'phone': '+91 11 4123 4567',
      },
      {
        'name': 'Max Hospital Pharmacy',
        'address': 'Institutional Area, Sector 19, Dwarka, New Delhi',
        'distance': '2.9 km',
        'phone': '+91 11 4987 6543',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pharmacies = _getMockPharmacies();

    return Container(
      padding: EdgeInsets.all(access.scaleSpacing(24.0)),
      decoration: BoxDecoration(
        color: access.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: access.textColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header title
          Row(
            children: [
              Icon(Icons.local_pharmacy_outlined, color: access.alertRed, size: access.scaleText(24.0)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Replacement Sourcing',
                  style: access.getTextStyle(
                    baseSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${medicine.name} is expired or recalled. Find nearby pharmacies to secure a fresh replacement.',
            style: access.getTextStyle(
              baseSize: 13.0,
              color: access.textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),

          // List of nearby pharmacies
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pharmacies.length,
              itemBuilder: (context, index) {
                final pharmacy = pharmacies[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(access.scaleSpacing(16.0)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: access.textColor.withOpacity(0.08), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            pharmacy['name']!,
                            style: access.getTextStyle(
                              baseSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            pharmacy['distance']!,
                            style: access.getTextStyle(
                              baseSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: access.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pharmacy['address']!,
                        style: access.getTextStyle(
                          baseSize: 12.0,
                          color: access.textColor.withOpacity(0.5),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Call Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Dialing ${pharmacy['name']}: ${pharmacy['phone']}'),
                                    backgroundColor: access.primaryTeal,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.phone_outlined, size: 16),
                              label: Text(
                                'Call Pharmacy',
                                style: access.getTextStyle(baseSize: 12.0, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: access.textColor.withOpacity(0.12)),
                                minimumSize: Size(0, access.minTapTargetSize),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Directions Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Launching Maps directions to ${pharmacy['name']}...'),
                                    backgroundColor: access.primaryTeal,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.directions_outlined, size: 16, color: Colors.white),
                              label: Text(
                                'Directions',
                                style: access.getTextStyle(
                                  baseSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: access.primaryTeal,
                                foregroundColor: Colors.white,
                                minimumSize: Size(0, access.minTapTargetSize),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
