
import 'package:flutter/material.dart';

import '../models/child_profile.dart';

class ChildDetailsScreen extends StatelessWidget {
  const ChildDetailsScreen({
    super.key,
    required this.child,
  });

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final dateOfBirth =
        '${child.dateOfBirth.day.toString().padLeft(2, '0')}/'
        '${child.dateOfBirth.month.toString().padLeft(2, '0')}/'
        '${child.dateOfBirth.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(child.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    child: Icon(
                      Icons.child_care_rounded,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    child.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text('Age: ${child.ageInYears} years'),
                  Text('Date of birth: $dateOfBirth'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'Allergies',
            icon: Icons.warning_amber_rounded,
            items: child.allergies,
            emptyMessage: 'No allergies recorded.',
          ),
          _buildSection(
            context,
            title: 'Medical Conditions',
            icon: Icons.medical_information_outlined,
            items: child.medicalConditions,
            emptyMessage: 'No medical conditions recorded.',
          ),
          _buildSection(
            context,
            title: 'Current Medications',
            icon: Icons.medication_outlined,
            items: child.currentMedications,
            emptyMessage: 'No current medications recorded.',
          ),
          const SizedBox(height: 12),
          Card(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This profile displays recorded health '
                      'information. It does not provide medicine '
                      'dosage recommendations. Confirm medication '
                      'decisions with a qualified healthcare '
                      'professional.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> items,
    required String emptyMessage,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                emptyMessage,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text('•  '),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
