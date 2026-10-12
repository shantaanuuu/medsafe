import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'main.dart';
import 'services/api_service.dart';
import 'services/onboarding_repository.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';
import 'widgets/voice_transcribe_button.dart';

class AllergyCenterScreen extends ConsumerStatefulWidget {
  const AllergyCenterScreen({super.key});
  @override
  ConsumerState<AllergyCenterScreen> createState() =>
      _AllergyCenterScreenState();
}

class _AllergyCenterScreenState extends ConsumerState<AllergyCenterScreen> {
  final _controller = TextEditingController();
  final _knownAllergyController = TextEditingController();
  AllergyAnalysis? _analysis;
  Future<List<AllergyRecord>>? _recordsFuture;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _knownAllergyController.dispose();
    super.dispose();
  }

  void _loadRecords(String uid) =>
      _recordsFuture = ref.read(apiServiceProvider).getAllergyRecords(uid);

  Future<void> _check() async {
    if (_controller.text.trim().length < 3) return;
    setState(() {
      _loading = true;
      _error = null;
      _analysis = null;
    });
    try {
      final value = await ref
          .read(apiServiceProvider)
          .analyzeAllergy(_controller.text.trim());
      if (mounted) setState(() => _analysis = value);
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(User user) async {
    final analysis = _analysis;
    final profile = ref.read(onboardingProfileProvider).value;
    if (analysis == null ||
        profile == null ||
        analysis.trigger.toLowerCase() == 'unknown')
      return;
    try {
      await ref
          .read(apiServiceProvider)
          .saveAllergyRecord(
            AllergyRecord(
              userUid: user.uid,
              triggerName: analysis.trigger,
              reactions: analysis.reactions,
              severity: analysis.severity,
              notes: _controller.text.trim(),
            ),
          );
      final alreadySaved = profile.allergies.any(
        (item) => item.toLowerCase() == analysis.trigger.toLowerCase(),
      );
      if (!alreadySaved)
        await ref
            .read(onboardingRepositoryProvider)
            .updateProfile(
              profile.copyWith(
                allergies: [...profile.allergies, analysis.trigger],
              ),
            );
      ref.invalidate(onboardingProfileProvider);
      setState(() {
        _loadRecords(user.uid);
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Allergy record saved securely.')),
        );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save: $error')));
    }
  }

  Future<void> _addKnownAllergy(User user) async {
    final name = _knownAllergyController.text.trim();
    final profile = ref.read(onboardingProfileProvider).value;
    if (name.isEmpty || profile == null) return;
    if (profile.allergies.any(
      (item) => item.toLowerCase() == name.toLowerCase(),
    )) {
      setState(() => _error = 'This allergy is already saved.');
      return;
    }
    try {
      await ref
          .read(onboardingRepositoryProvider)
          .updateProfile(
            profile.copyWith(allergies: [...profile.allergies, name]),
          );
      _knownAllergyController.clear();
      ref.invalidate(onboardingProfileProvider);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Known allergy added.')));
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not add allergy: $error');
    }
  }

  Future<void> _removeKnownAllergy(User user, String name) async {
    final profile = ref.read(onboardingProfileProvider).value;
    if (profile == null) return;
    try {
      await ref
          .read(onboardingRepositoryProvider)
          .updateProfile(
            profile.copyWith(
              allergies: profile.allergies
                  .where((item) => item.toLowerCase() != name.toLowerCase())
                  .toList(),
            ),
          );
      ref.invalidate(onboardingProfileProvider);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Allergy removed.')));
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not remove allergy: $error');
    }
  }

  Future<void> _deleteRecord(User user, AllergyRecord record) async {
    try {
      await ref
          .read(apiServiceProvider)
          .deleteAllergyRecord(user.uid, record.id!);
      await _removeKnownAllergy(user, record.triggerName);
      if (mounted) setState(() => _loadRecords(user.uid));
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not delete record: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = AccessibilityConfig(
      isElderlyMode: ref.watch(elderlyModeProvider),
    );
    final user = FirebaseAuth.instance.currentUser;
    final profile = ref.watch(onboardingProfileProvider).value;
    if (user != null && _recordsFuture == null) _loadRecords(user.uid);
    return Scaffold(
      backgroundColor: access.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Allergy Center',
          style: access.getTextStyle(baseSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(access.scaleSpacing(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DisclaimerBanner(access: access),
            const SizedBox(height: 18),
            _header(access),
            const SizedBox(height: 20),
            Text(
              'Known allergies',
              style: access.getTextStyle(
                baseSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _knownAllergies(profile?.allergies ?? const [], access, user),
            if (user != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _knownAllergyController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Add known allergy',
                        hintText: 'e.g. Penicillin',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _addKnownAllergy(user),
                    icon: const Icon(Icons.add),
                    tooltip: 'Add allergy',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Check a reaction',
              style: access.getTextStyle(
                baseSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Describe what caused the reaction and what happened. English and Hinglish both work.',
              style: access.getTextStyle(
                baseSize: 13,
                color: access.textColor.withOpacity(.65),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Reaction details',
                hintText: 'e.g. Ibuprofen lene ke baad rashes aur khujli hui.',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                suffixIcon: VoiceTranscribeButton(controller: _controller),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loading ? null : _check,
              icon: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.fact_check_outlined),
              label: Text(_loading ? 'Checking...' : 'Check reaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: access.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _notice(_error!, access, access.alertRed, Icons.error_outline),
            ],
            if (_analysis != null) ...[
              const SizedBox(height: 20),
              if (_analysis!.emergency)
                _notice(
                  '${_analysis!.emergencyReason ?? 'Severe reaction symptoms detected'}. Seek emergency medical help now.',
                  access,
                  access.alertRed,
                  Icons.emergency,
                ),
              if (_analysis!.emergency) const SizedBox(height: 12),
              _resultCard(_analysis!, access),
              const SizedBox(height: 10),
              if (user != null && !_analysis!.emergency)
                OutlinedButton.icon(
                  onPressed: () => _save(user),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save to my allergy history'),
                ),
            ],
            const SizedBox(height: 24),
            Text(
              'Saved reaction history',
              style: access.getTextStyle(
                baseSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (user != null)
              FutureBuilder<List<AllergyRecord>>(
                future: _recordsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  final records = snapshot.data ?? const <AllergyRecord>[];
                  if (records.isEmpty)
                    return _notice(
                      'No reaction history saved yet.',
                      access,
                      access.secondaryTextColor,
                      Icons.history_toggle_off,
                    );
                  return Column(
                    children: records
                        .map((record) => _recordCard(record, user, access))
                        .toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(AccessibilityConfig access) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFED7AA)),
    ),
    child: Row(
      children: [
        const Icon(Icons.health_and_safety_outlined, color: Color(0xFFEA580C)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Keep possible reactions in one place. These records help check your medicine cabinet for potential conflicts.',
            style: access.getTextStyle(
              baseSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _knownAllergies(
    List<String> values,
    AccessibilityConfig access,
    User? user,
  ) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: access.borderColor),
    ),
    child: values.isEmpty
        ? Text(
            'No known allergies saved. Add a reaction below after discussing it with a clinician.',
            style: access.getTextStyle(
              baseSize: 13,
              color: access.secondaryTextColor,
            ),
          )
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map(
                  (item) => Chip(
                    avatar: const Icon(Icons.warning_amber_rounded, size: 17),
                    label: Text(item),
                    onDeleted: user == null
                        ? null
                        : () => _removeKnownAllergy(user, item),
                  ),
                )
                .toList(),
          ),
  );
  Widget _resultCard(
    AllergyAnalysis item,
    AccessibilityConfig access,
  ) {
    Color statusColor = const Color(0xFFEA580C);
    Color statusBg = const Color(0xFFFFF7ED);
    if (item.emergency ||
        item.severity.toLowerCase().contains('high') ||
        item.severity.toLowerCase().contains('severe')) {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEF2F2);
    } else if (item.severity.toLowerCase().contains('mild') ||
        item.severity.toLowerCase().contains('low')) {
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFF0FDF4);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'IMMUNOLOGICAL TRIAGE EVALUATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  item.triageLevel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.trigger,
            style: access.getTextStyle(
              baseSize: 18,
              fontWeight: FontWeight.bold,
              color: access.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.allergenCategory,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.summary,
            style: access.getTextStyle(baseSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          Text(
            'PHYSIOLOGICAL MANIFESTATIONS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: access.textColor.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: item.reactions
                .map(
                  (value) => Chip(
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    label: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'CLINICAL ACTION PROTOCOL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: access.textColor.withOpacity(0.5),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...item.guidance.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 9,
                    backgroundColor: statusBg,
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: access.getTextStyle(baseSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.disclaimer,
            style: access.getTextStyle(
              baseSize: 11,
              color: access.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
  Widget _recordCard(
    AllergyRecord record,
    User user,
    AccessibilityConfig access,
  ) => Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.warning_amber_rounded)),
      title: Text(record.triggerName),
      subtitle: Text('${record.reactions.join(', ')} • ${record.severity}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _deleteRecord(user, record),
      ),
    ),
  );
  Widget _notice(
    String text,
    AccessibilityConfig access,
    Color color,
    IconData icon,
  ) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: access.getTextStyle(
              baseSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
