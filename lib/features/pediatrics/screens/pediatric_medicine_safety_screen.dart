import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_service.dart';
import '../models/child_profile.dart';
import '../providers/pediatrics_provider.dart';

class PediatricMedicineSafetyScreen extends StatelessWidget {
  const PediatricMedicineSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pediatric Medicine Safety')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.health_and_safety,
                    size: 36,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Medicine Safety for Children',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Review age-related restrictions and verify the '
                    'ingredients and formulation of medicines before use.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              title: const Text('Age-related safety warnings'),
              subtitle: const Text(
                'Check product-specific age restrictions and precautions.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _FeaturePlaceholderScreen(
                      title: 'Age-related Safety Warnings',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.science_outlined, color: Colors.blue),
              title: const Text('Ingredient & formulation checks'),
              subtitle: const Text(
                'Review active ingredients and formulations, such as syrup '
                'or tablet.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _FeaturePlaceholderScreen(
                      title: 'Ingredient & Formulation Checks',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Important: This screen does not prescribe doses or confirm '
              'that a medicine is safe for a child. Verify the exact product '
              'with a pediatrician or pharmacist.',
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePlaceholderScreen extends ConsumerStatefulWidget {
  const _FeaturePlaceholderScreen({required this.title});

  final String title;

  @override
  ConsumerState<_FeaturePlaceholderScreen> createState() =>
      _FeaturePlaceholderScreenState();
}

class _FeaturePlaceholderScreenState
    extends ConsumerState<_FeaturePlaceholderScreen> {
  final TextEditingController _medicineController = TextEditingController();

  ChildProfile? _selectedChild;

  List<SearchedMedicine> _results = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  final Map<String, AllergyMedicineCheck> _allergyChecks = {};
  final Set<String> _checkingAllergies = {};

  bool get _isAgeFeature => widget.title == 'Age-related Safety Warnings';

  @override
  void dispose() {
    _medicineController.dispose();
    super.dispose();
  }

  Future<void> _checkMedicineAllergy(
    ChildProfile child,
    SearchedMedicine medicine,
  ) async {
    if (child.allergies.isEmpty) return;

    setState(() {
      _checkingAllergies.add(medicine.id);
      _allergyChecks.remove(medicine.id);
    });

    try {
      final result = await ref
          .read(apiServiceProvider)
          .checkMedicineAllergy(
            allergies: child.allergies,
            medicineName: medicine.brandName,
            genericName: medicine.genericName,
          );

      debugPrint(
        'ALLERGY CHECK SUCCESS: ${medicine.brandName} '
        'ID=${medicine.id}',
      );
      debugPrint(
        'ALLERGY RESULT: status=${result.status}, '
        'conflict=${result.potentialConflict}, '
        'matches=${result.matchedAllergies}, '
        'message=${result.message}',
      );

      if (!mounted) return;

      setState(() {
        _allergyChecks[medicine.id] = result;
        _checkingAllergies.remove(medicine.id);
      });
    } catch (e, stackTrace) {
      debugPrint('ALLERGY CHECK FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _checkingAllergies.remove(medicine.id);
      });
    }
  }

  Future<void> _searchMedicine() async {
    final query = _medicineController.text.trim();

    if (_isAgeFeature && _selectedChild == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a child first.')),
      );
      return;
    }

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a medicine name.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _searched = true;
      _error = null;
      _results = [];
      _allergyChecks.clear();
      _checkingAllergies.clear();
    });

    try {
      final results = await ref.read(apiServiceProvider).searchMedicines(query);

      if (!mounted) return;

      setState(() {
        _results = results;
        _loading = false;
      });

      final child = _selectedChild;

      if (_isAgeFeature && child != null && child.allergies.isNotEmpty) {
        for (final medicine in results) {
          _checkMedicineAllergy(child, medicine);
        }
      }
    } catch (e) {
      debugPrint('MEDICINE SEARCH FAILED: $e');

      if (!mounted) return;

      setState(() {
        _error =
            'Could not search medicines. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  List<String> _buildProfileWarnings(ChildProfile child) {
    final warnings = <String>[];

    if (child.allergies.isNotEmpty) {
      warnings.add(
        'Allergy check required: ${child.allergies.join(', ')}. '
        'Verify the medicine ingredients against these recorded allergies.',
      );
    } else {
      warnings.add(
        'No allergies are recorded. Confirm the child’s allergy history '
        'before using a medicine.',
      );
    }

    if (child.medicalConditions.isNotEmpty) {
      warnings.add(
        'Medical history review required: '
        '${child.medicalConditions.join(', ')}. '
        'Check the product precautions with a pediatrician or pharmacist.',
      );
    } else {
      warnings.add(
        'No medical conditions are recorded. Confirm the child’s medical '
        'history before using a medicine.',
      );
    }

    if (child.currentMedications.isNotEmpty) {
      warnings.add(
        'Medication review required: '
        '${child.currentMedications.join(', ')}. '
        'Check for interactions and duplicate active ingredients.',
      );
    } else {
      warnings.add(
        'No current medications are recorded. Confirm the child’s '
        'medication list before using a medicine.',
      );
    }

    return warnings;
  }

  Widget _buildAllergyResult(SearchedMedicine medicine) {
    if (_selectedChild == null) {
      return const SizedBox.shrink();
    }

    if (_selectedChild!.allergies.isEmpty) {
      return const Text(
        'No allergies are recorded for this child. '
        'Confirm their allergy history before use.',
      );
    }

    if (_checkingAllergies.contains(medicine.id)) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Expanded(child: Text('Checking potential allergy concerns...')),
        ],
      );
    }

    final check = _allergyChecks[medicine.id];

    if (check == null) {
      return const Text(
        'Allergy check could not be completed. '
        'Consult a pharmacist or pediatrician before use.',
      );
    }

    final hasPotentialConflict =
        check.potentialConflict || check.status == 'potential_conflict';

    final isInconclusive = check.status == 'inconclusive';

    final warningColor = hasPotentialConflict ? Colors.red : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: warningColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPotentialConflict
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
                color: warningColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasPotentialConflict
                      ? 'Potential Allergy Concern'
                      : isInconclusive
                      ? 'Allergy Check Inconclusive'
                      : 'Allergy Check Result',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(check.message),
          if (check.matchedAllergies.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Potential matches: ${check.matchedAllergies.join(', ')}'),
          ],
          const SizedBox(height: 6),
          const Text(
            'This result is not a verified ingredient-level assessment. '
            'A result without a detected conflict does not establish safety. '
            'Consult a pharmacist or pediatrician before use.',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isAgeFeature)
            Consumer(
              builder: (context, ref, child) {
                final childrenAsync = ref.watch(pediatricsChildrenProvider);

                return childrenAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('Could not load child profiles.'),
                  data: (children) {
                    if (children.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No child profiles with a valid date of birth '
                            'found. Please add a dependent profile first.',
                          ),
                        ),
                      );
                    }

                    final selected =
                        children.any((child) => child.id == _selectedChild?.id)
                        ? _selectedChild
                        : null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<ChildProfile>(
                          initialValue: selected,
                          decoration: const InputDecoration(
                            labelText: 'Select child',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.child_care),
                          ),
                          items: children.map((child) {
                            return DropdownMenuItem<ChildProfile>(
                              value: child,
                              child: Text(child.name),
                            );
                          }).toList(),
                          onChanged: (child) {
                            setState(() {
                              _selectedChild = child;
                              _results = [];
                              _searched = false;
                              _error = null;
                              _allergyChecks.clear();
                              _checkingAllergies.clear();
                            });
                          },
                        ),
                        if (selected != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Age: ${selected.ageInYears} '
                            '${selected.ageInYears == 1 ? 'year' : 'years'}',
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: _medicineController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchMedicine(),
                          decoration: const InputDecoration(
                            labelText: 'Medicine name',
                            hintText: 'Enter brand or generic name',
                            prefixIcon: Icon(Icons.medication_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _loading ? null : _searchMedicine,
                          icon: const Icon(Icons.search),
                          label: const Text('Search medicines'),
                        ),
                        const SizedBox(height: 16),
                        if (_loading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        if (_error != null)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(_error!),
                            ),
                          ),
                        if (_searched &&
                            !_loading &&
                            _error == null &&
                            _results.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No matching medicines found. Try another name.',
                              ),
                            ),
                          ),
                        for (final medicine in _results)
                          Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    medicine.brandName.isNotEmpty
                                        ? medicine.brandName
                                        : medicine.genericName,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  if (medicine.genericName.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Generic name: ${medicine.genericName}',
                                    ),
                                  ],
                                  if (medicine.manufacturer?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Manufacturer: ${medicine.manufacturer}',
                                    ),
                                  ],
                                  if (medicine.price?.isNotEmpty == true) ...[
                                    const SizedBox(height: 4),
                                    Text('Price: ${medicine.price}'),
                                  ],
                                  if (medicine.sideEffects?.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Reported side effects: '
                                      '${medicine.sideEffects}',
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  _buildAllergyResult(medicine),
                                  const Divider(height: 24),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Age-specific safety for '
                                          '${_selectedChild?.name ?? 'this child'} '
                                          '(${_selectedChild?.ageInYears ?? 'unknown'} years) '
                                          'has not been verified. Check the exact '
                                          'product label with a pediatrician '
                                          'or pharmacist.',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (selected != null) ...[
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Health Profile Summary',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Allergies: '
                                    '${selected.allergies.isEmpty ? 'None recorded' : selected.allergies.join(', ')}',
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Medical Conditions: '
                                    '${selected.medicalConditions.isEmpty ? 'None recorded' : selected.medicalConditions.join(', ')}',
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Current Medications: '
                                    '${selected.currentMedications.isEmpty ? 'None recorded' : selected.currentMedications.join(', ')}',
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'These details help personalize safety '
                                    'reminders. This summary does not confirm '
                                    'that a medicine is safe.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Personalized Safety Reminders',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  ..._buildProfileWarnings(selected).map(
                                    (warning) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(warning)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          if (!_isAgeFeature) ...[
            TextField(
              controller: _medicineController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchMedicine(),
              decoration: const InputDecoration(
                labelText: 'Medicine name',
                hintText: 'Enter brand or generic name',
                prefixIcon: Icon(Icons.medication_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _searchMedicine,
              icon: const Icon(Icons.search),
              label: const Text('Search medicines'),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_error != null) Text(_error!),
            for (final medicine in _results)
              Card(
                child: ListTile(
                  title: Text(
                    medicine.brandName.isNotEmpty
                        ? medicine.brandName
                        : medicine.genericName,
                  ),
                  subtitle: Text(
                    'Active ingredients and formulation are not verified '
                    'by this search. Check the exact product packaging.',
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Important: Search results do not confirm that a medicine is '
            'safe for a child. This feature does not recommend doses. '
            'Consult a pediatrician or pharmacist before giving medicine '
            'to a child.',
          ),
        ],
      ),
    );
  }
}
