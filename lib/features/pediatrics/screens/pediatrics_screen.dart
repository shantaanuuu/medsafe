
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/pediatrics_provider.dart';
import 'child_details_screen.dart';
import 'pediatric_medicine_safety_screen.dart';

class PediatricsScreen extends ConsumerWidget {
  const PediatricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(pediatricsChildrenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pediatrics'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.health_and_safety),
                ),
                title: const Text('Pediatric Medicine Safety'),
                subtitle: const Text(
                  'Age warnings and ingredient checks',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const PediatricMedicineSafetyScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: childrenAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load child profiles.\n$error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (children) {
                if (children.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No eligible child profiles found.\n'
                        'Add a dependent with a valid date of birth '
                        'to continue.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final child = children[index];

                    final dateOfBirth =
                        '${child.dateOfBirth.day.toString().padLeft(2, '0')}/'
                        '${child.dateOfBirth.month.toString().padLeft(2, '0')}/'
                        '${child.dateOfBirth.year}';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.child_care),
                        ),
                        title: Text(child.name),
                        subtitle: Text(
                          'Age: ${child.ageInYears} years\n'
                          'Date of birth: $dateOfBirth',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChildDetailsScreen(child: child),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
