import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../accessibility_config.dart';
import '../../shared_states.dart';
import '../../shared_widgets.dart';
import '../../models/user_health_profile.dart';
import '../../services/api_service.dart';
import 'onboarding_provider.dart';
import 'onboarding_state.dart';
import '../../main.dart';
import '../../services/onboarding_repository.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  final UserHealthProfile? prefilledDependent;
  final bool isAddingDependent;

  const OnboardingFlowScreen({
    super.key,
    this.prefilledDependent,
    this.isAddingDependent = false,
  });

  @override
  ConsumerState<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;

  // Screen 1 State
  String _selectedRole = 'Patient';
  final TextEditingController _nicknameController = TextEditingController();
  final List<String> _selectedConditions = [];
  final TextEditingController _conditionsSearchController = TextEditingController();
  final TextEditingController _customConditionController = TextEditingController();
  List<String> _conditionsSuggestions = [];

  final List<String> _predefinedConditions = [
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Thyroid Disorder',
    'Heart Disease',
    'Arthritis',
    'COPD',
    'Kidney Disease',
    'Liver Disease',
    'Depression',
    'Anxiety',
  ];

  // Screen 2 State
  List<MedicationEntry> _selectedMedications = [];
  final TextEditingController _medsSearchController = TextEditingController();
  List<SearchedMedicine> _medsSuggestions = [];
  bool _isLoadingMeds = false;

  // Screen 3 State
  final List<String> _selectedAllergies = [];
  final TextEditingController _allergyController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _selectedSex = 'Prefer not to say';

  final List<String> _sexOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(onboardingProfileProvider).value;
    int initialPage = 0;

    if (widget.isAddingDependent) {
      initialPage = 0;
      if (widget.prefilledDependent != null) {
        final dep = widget.prefilledDependent!;
        _selectedRole = 'Patient';
        _nicknameController.text = dep.nickname ?? '';
        _selectedConditions.addAll(dep.chronicConditions);
        _selectedMedications.addAll(dep.currentMedications);
        _selectedAllergies.addAll(dep.allergies);
        if (dep.age != null) {
          _ageController.text = dep.age.toString();
        }
        if (dep.weightKg != null) {
          _weightController.text = dep.weightKg.toString();
        }
        if (dep.sex != null && _sexOptions.contains(dep.sex)) {
          _selectedSex = dep.sex!;
        }
      }
    } else if (profile != null) {
      initialPage = profile.onboardingStep - 1;
      if (initialPage < 0) initialPage = 0;
      if (initialPage > 2) initialPage = 2;

      _selectedRole = profile.role;
      _selectedConditions.addAll(profile.chronicConditions);
      _selectedMedications.addAll(profile.currentMedications);
      _selectedAllergies.addAll(profile.allergies);

      if (profile.age != null) {
        _ageController.text = profile.age.toString();
      }
      if (profile.weightKg != null) {
        _weightController.text = profile.weightKg.toString();
      }
      if (profile.sex != null && _sexOptions.contains(profile.sex)) {
        _selectedSex = profile.sex!;
      }

      Future.microtask(() {
        if (mounted) {
          ref.read(onboardingProvider.notifier).initializeProfile(profile);
        }
      });
    }

    _currentPageIndex = initialPage;
    _pageController = PageController(initialPage: initialPage);

    _conditionsSearchController.addListener(_onConditionsSearchChanged);
    _medsSearchController.addListener(_onMedsSearchChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    _conditionsSearchController.dispose();
    _customConditionController.dispose();
    _medsSearchController.dispose();
    _allergyController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onConditionsSearchChanged() {
    final query = _conditionsSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _conditionsSuggestions = [];
      });
      return;
    }

    setState(() {
      _conditionsSuggestions = _predefinedConditions
          .where((condition) =>
              condition.toLowerCase().contains(query) &&
              !_selectedConditions.contains(condition))
          .toList();
    });
  }

  Future<void> _onMedsSearchChanged() async {
    final query = _medsSearchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _medsSuggestions = [];
      });
      return;
    }

    setState(() {
      _isLoadingMeds = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final results = await apiService.searchMedicines(query);
      
      // Filter out already selected medications
      final filteredResults = results
          .where((med) => !_selectedMedications.any((selected) => selected.medicineId == med.id))
          .toList();

      if (mounted) {
        setState(() {
          _medsSuggestions = filteredResults;
          _isLoadingMeds = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching medicines: $e');
      if (mounted) {
        setState(() {
          _isLoadingMeds = false;
        });
      }
    }
  }

  void _navigateToPage(int pageIndex, int nextStep) {
    setState(() {
      _currentPageIndex = pageIndex;
    });
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleStep1Submit({bool isSkip = false}) async {
    final conditions = isSkip ? <String>[] : _selectedConditions;
    
    if (widget.isAddingDependent) {
      if (_nicknameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a name or nickname for the dependent.')),
        );
        return;
      }
      _navigateToPage(1, 2);
      return;
    }

    await ref.read(onboardingProvider.notifier).updateStep(
      2,
      role: _selectedRole,
      chronicConditions: conditions,
    );

    final status = ref.read(onboardingProvider).status;
    if (status != OnboardingStatus.error) {
      _navigateToPage(1, 2);
    }
  }

  Future<void> _handleStep2Submit({bool isSkip = false}) async {
    if (widget.isAddingDependent) {
      _navigateToPage(2, 3);
      return;
    }

    final meds = isSkip ? <MedicationEntry>[] : _selectedMedications;

    await ref.read(onboardingProvider.notifier).updateStep(
      3,
      currentMedications: meds,
    );

    final status = ref.read(onboardingProvider).status;
    if (status != OnboardingStatus.error) {
      _navigateToPage(2, 3);
    }
  }

  Future<void> _handleStep3Submit({bool isSkip = false}) async {
    final allergies = isSkip ? <String>[] : _selectedAllergies;
    int? age;
    double? weight;

    if (!isSkip) {
      age = int.tryParse(_ageController.text.trim());
      weight = double.tryParse(_weightController.text.trim());
    }

    if (widget.isAddingDependent) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final repo = ref.read(onboardingRepositoryProvider);
      final depId = widget.prefilledDependent?.id ?? 'dep_${DateTime.now().millisecondsSinceEpoch}';

      final dependent = UserHealthProfile(
        id: depId,
        firebaseUid: user.uid,
        role: 'Patient',
        nickname: _nicknameController.text.trim(),
        age: age,
        weightKg: weight,
        sex: isSkip ? null : _selectedSex,
        chronicConditions: _selectedConditions,
        currentMedications: _selectedMedications,
        allergies: allergies,
        onboardingStep: 3,
        onboardingCompleted: true,
      );

      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E))),
        );

        await repo.saveDependent(dependent);

        if (mounted) {
          Navigator.pop(context); // Dismiss loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dependent profile saved successfully!'),
              backgroundColor: Color(0xFF0F766E),
            ),
          );
          ref.invalidate(allProfilesProvider);
          Navigator.pop(context); // Close flow
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Dismiss loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save dependent: $e'),
              backgroundColor: const Color(0xFFB91C1C),
            ),
          );
        }
      }
      return;
    }

    await ref.read(onboardingProvider.notifier).updateStep(
      3,
      allergies: allergies,
      age: age,
      weightKg: weight,
      sex: isSkip ? null : _selectedSex,
      completed: true,
    );

    ref.invalidate(onboardingProfileProvider);
    ref.invalidate(cabinetProvider);
  }

  Future<void> _handleBack(int targetPage, int prevStep) async {
    if (widget.isAddingDependent) {
      _navigateToPage(targetPage, prevStep);
      return;
    }

    // Save current states immediately on back navigation to prevent data loss
    if (_currentPageIndex == 1) {
      await ref.read(onboardingProvider.notifier).updateStep(
        1,
        currentMedications: _selectedMedications,
      );
    } else if (_currentPageIndex == 2) {
      final allergies = _selectedAllergies;
      final age = int.tryParse(_ageController.text.trim());
      final weight = double.tryParse(_weightController.text.trim());
      await ref.read(onboardingProvider.notifier).updateStep(
        2,
        allergies: allergies,
        age: age,
        weightKg: weight,
        sex: _selectedSex,
      );
    }

    _navigateToPage(targetPage, prevStep);
  }

  @override
  Widget build(BuildContext context) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: access.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: access.textColor,
        elevation: 0,
        title: Text(
          'Complete Onboarding',
          style: access.getTextStyle(baseSize: 18.0, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          ElderlyModeToggle(
            access: access,
            value: isElderlyMode,
            onChanged: (val) {
              ref.read(elderlyModeProvider.notifier).toggle();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              DisclaimerBanner(access: access),
              _buildProgressStepper(access),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1Screen(access),
                    _buildStep2Screen(access),
                    _buildStep3Screen(access),
                  ],
                ),
              ),
            ],
          ),
          if (state.status == OnboardingStatus.submitting || state.status == OnboardingStatus.loading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0F766E),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressStepper(AccessibilityConfig access) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: access.scaleSpacing(20.0),
        vertical: access.scaleSpacing(12.0),
      ),
      child: Row(
        children: [
          _buildStepCircle(1, 'Profile', _currentPageIndex >= 0, access),
          _buildStepLine(_currentPageIndex >= 1, access),
          _buildStepCircle(2, 'Medications', _currentPageIndex >= 1, access),
          _buildStepLine(_currentPageIndex >= 2, access),
          _buildStepCircle(3, 'Allergies & Vitals', _currentPageIndex >= 2, access),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, bool isActive, AccessibilityConfig access) {
    final activeColor = access.primaryTeal;
    final inactiveColor = access.textColor.withOpacity(0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: access.scaleSpacing(28.0),
          height: access.scaleSpacing(28.0),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? activeColor : inactiveColor,
              width: 2.0,
            ),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: access.getTextStyle(
                baseSize: 12.0,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : inactiveColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: access.getTextStyle(
            baseSize: 12.0,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? access.textColor : inactiveColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive, AccessibilityConfig access) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        height: 2.0,
        color: isActive ? access.primaryTeal : access.textColor.withOpacity(0.15),
      ),
    );
  }

  // --- SCREEN 1: Role & Chronic Conditions ---
  Widget _buildStep1Screen(AccessibilityConfig access) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(access.scaleSpacing(20.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isAddingDependent) ...[
            Text(
              'Dependent Nickname / Name',
              style: access.getTextStyle(baseSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            VoiceInputField(
              access: access,
              controller: _nicknameController,
              labelText: 'Dependent Name / Nickname',
              icon: Icons.person_rounded,
              mockTranscript: 'Grandpa',
            ),
            const SizedBox(height: 28),
          ],
          if (!widget.isAddingDependent) ...[
            Text(
              'Who is this account for?',
              style: access.getTextStyle(baseSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRoleCard('Patient', Icons.person_rounded, access),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRoleCard('Caregiver', Icons.family_restroom_rounded, access),
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],
          Text(
            'Chronic Conditions',
            style: access.getTextStyle(baseSize: 18.0, fontWeight: FontWeight.bold),
          ),
          Text(
            'Select any ongoing medical conditions.',
            style: access.getTextStyle(baseSize: 13.0, color: access.textColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _conditionsSearchController,
            decoration: InputDecoration(
              hintText: 'Search conditions (e.g. Diabetes)...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),

          // Suggestions List
          if (_conditionsSuggestions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: access.textColor.withOpacity(0.1)),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _conditionsSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _conditionsSuggestions[index];
                    return ListTile(
                      title: Text(suggestion),
                      onTap: () {
                        setState(() {
                          _selectedConditions.add(suggestion);
                          _conditionsSearchController.clear();
                          _conditionsSuggestions = [];
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Custom "Other" Condition Voice Field
          Row(
            children: [
              Expanded(
                child: VoiceInputField(
                  access: access,
                  controller: _customConditionController,
                  labelText: 'Other Chronic Condition',
                  icon: Icons.edit_note_rounded,
                  mockTranscript: 'Thyroid Disorder',
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  final text = _customConditionController.text.trim();
                  if (text.isNotEmpty && !_selectedConditions.contains(text)) {
                    setState(() {
                      _selectedConditions.add(text);
                      _customConditionController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: access.primaryTeal,
                  foregroundColor: Colors.white,
                  minimumSize: Size(access.minTapTargetSize, access.minTapTargetSize),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selected Conditions Chips
          if (_selectedConditions.isNotEmpty) ...[
            Text(
              'Selected Conditions:',
              style: access.getTextStyle(baseSize: 13.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _selectedConditions.map((condition) {
                return Chip(
                  label: Text(condition),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: () {
                    setState(() {
                      _selectedConditions.remove(condition);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Quick selection list of popular conditions
          Text(
            'Popular Conditions',
            style: access.getTextStyle(baseSize: 13.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _predefinedConditions
                .where((cond) => !_selectedConditions.contains(cond))
                .take(6)
                .map((condition) {
              return ChoiceChip(
                label: Text(condition),
                selected: false,
                onSelected: (selected) {
                  setState(() {
                    _selectedConditions.add(condition);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => _handleStep1Submit(isSkip: true),
                child: Text(
                  'Skip Conditions',
                  style: access.getTextStyle(
                    baseSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: access.textColor.withOpacity(0.6),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _handleStep1Submit(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: access.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Continue',
                  style: access.getTextStyle(
                    baseSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(String role, IconData icon, AccessibilityConfig access) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? access.primaryTeal.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? access.primaryTeal : access.textColor.withOpacity(0.1),
            width: 2.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? access.primaryTeal : access.textColor.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            Text(
              role,
              style: access.getTextStyle(
                baseSize: 15.0,
                fontWeight: FontWeight.bold,
                color: isSelected ? access.primaryTeal : access.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SCREEN 2: Current Medications ---
  Widget _buildStep2Screen(AccessibilityConfig access) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(access.scaleSpacing(20.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Medications',
            style: access.getTextStyle(baseSize: 18.0, fontWeight: FontWeight.bold),
          ),
          Text(
            'Search and add any regular medications you are currently taking from our database.',
            style: access.getTextStyle(baseSize: 13.0, color: access.textColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 20),

          // Search Autocomplete Field
          TextField(
            controller: _medsSearchController,
            decoration: InputDecoration(
              hintText: 'Type medicine brand name...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _isLoadingMeds
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),

          // Suggestions list
          if (_medsSuggestions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: access.textColor.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _medsSuggestions.length,
                  itemBuilder: (context, index) {
                    final med = _medsSuggestions[index];
                    return ListTile(
                      leading: Icon(Icons.medication_outlined, color: access.primaryTeal),
                      title: Text(
                        med.brandName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(med.genericName),
                      onTap: () {
                        setState(() {
                          _selectedMedications.add(
                            MedicationEntry(medicineId: med.id, medicineName: med.brandName),
                          );
                          _medsSearchController.clear();
                          _medsSuggestions = [];
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Selected Medications List
          if (_selectedMedications.isNotEmpty) ...[
            Text(
              'Selected Medications (${_selectedMedications.length}):',
              style: access.getTextStyle(baseSize: 13.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedMedications.length,
              itemBuilder: (context, index) {
                final med = _selectedMedications[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: access.textColor.withOpacity(0.1)),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: access.primaryTeal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.medication_rounded, color: access.primaryTeal),
                    ),
                    title: Text(
                      med.medicineName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: access.alertRed),
                      onPressed: () {
                        setState(() {
                          _selectedMedications.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => _handleBack(0, 1),
                child: Text(
                  'Back',
                  style: access.getTextStyle(
                    baseSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: access.textColor.withOpacity(0.6),
                  ),
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _handleStep2Submit(isSkip: true),
                    child: Text(
                      'Skip',
                      style: access.getTextStyle(
                        baseSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: access.textColor.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _handleStep2Submit(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: access.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Continue',
                      style: access.getTextStyle(
                        baseSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SCREEN 3: Allergies & Vitals ---
  Widget _buildStep3Screen(AccessibilityConfig access) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(access.scaleSpacing(20.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Allergies & Vitals',
            style: access.getTextStyle(baseSize: 18.0, fontWeight: FontWeight.bold),
          ),
          Text(
            'Add any known drug or food allergies, and your basic physiological vitals.',
            style: access.getTextStyle(baseSize: 13.0, color: access.textColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),

          // Allergies Entry Voice Field
          Row(
            children: [
              Expanded(
                child: VoiceInputField(
                  access: access,
                  controller: _allergyController,
                  labelText: 'Add Drug / Food Allergy',
                  icon: Icons.health_and_safety_outlined,
                  mockTranscript: 'Penicillin Allergy',
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  final text = _allergyController.text.trim();
                  if (text.isNotEmpty && !_selectedAllergies.contains(text)) {
                    setState(() {
                      _selectedAllergies.add(text);
                      _allergyController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: access.primaryTeal,
                  foregroundColor: Colors.white,
                  minimumSize: Size(access.minTapTargetSize, access.minTapTargetSize),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Selected Allergies Chips
          if (_selectedAllergies.isNotEmpty) ...[
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _selectedAllergies.map((allergy) {
                return Chip(
                  backgroundColor: access.alertRed.withOpacity(0.08),
                  side: BorderSide(color: access.alertRed.withOpacity(0.2)),
                  label: Text(
                    allergy,
                    style: TextStyle(color: access.alertRed, fontWeight: FontWeight.bold),
                  ),
                  deleteIcon: Icon(Icons.close_rounded, size: 16, color: access.alertRed),
                  onDeleted: () {
                    setState(() {
                      _selectedAllergies.remove(allergy);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],

          const Divider(),
          const SizedBox(height: 20),

          // Vitals Inputs
          Text(
            'Body Vitals',
            style: access.getTextStyle(baseSize: 15.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Age
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Age (years)',
              prefixIcon: const Icon(Icons.calendar_month_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // Weight
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              prefixIcon: const Icon(Icons.monitor_weight_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // Biological Sex
          DropdownButtonFormField<String>(
            value: _selectedSex,
            decoration: InputDecoration(
              labelText: 'Biological Sex',
              prefixIcon: const Icon(Icons.wc_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _sexOptions.map((sex) {
              return DropdownMenuItem(
                value: sex,
                child: Text(sex),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedSex = val;
                });
              }
            },
          ),
          const SizedBox(height: 40),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => _handleBack(1, 2),
                child: Text(
                  'Back',
                  style: access.getTextStyle(
                    baseSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: access.textColor.withOpacity(0.6),
                  ),
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _handleStep3Submit(isSkip: true),
                    child: Text(
                      'Skip Vitals',
                      style: access.getTextStyle(
                        baseSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: access.textColor.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _handleStep3Submit(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: access.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Complete',
                      style: access.getTextStyle(
                        baseSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
