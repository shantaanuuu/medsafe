import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'medicine_detail.dart';
import 'services/api_service.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';

class InteractionGraphScreen extends ConsumerStatefulWidget {
  const InteractionGraphScreen({super.key});
  @override
  ConsumerState<InteractionGraphScreen> createState() =>
      _InteractionGraphScreenState();
}

class _InteractionGraphScreenState
    extends ConsumerState<InteractionGraphScreen> {
  Future<InteractionAnalysis>? _analysis;
  String _fingerprint = '';
  String _filter = 'all';
  Future<InteractionAnalysis> _load(List<Medicine> m) => ref
      .read(apiServiceProvider)
      .analyzeInteractions(
        m
            .map(
              (x) => {
                'id': x.id,
                'name': x.name,
                'genericName': x.genericName,
                'drugInteractions': x.drugInteractions,
              },
            )
            .toList(),
      );
  void _ensure(List<Medicine> m) {
    final f = m.map((x) => '${x.id}:${x.drugInteractions}').join('|');
    if (_analysis == null || f != _fingerprint) {
      _fingerprint = f;
      _analysis = _load(m);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meds = ref.watch(cabinetProvider);
    final elderly = ref.watch(elderlyModeProvider);
    final access = AccessibilityConfig(isElderlyMode: elderly);
    _ensure(meds);
    return Scaffold(
      backgroundColor: const Color(0xfff6f8fc),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff172033),
        title: const Text(
          'Medicine interactions',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElderlyModeToggle(
              access: access,
              value: elderly,
              onChanged: (_) => ref.read(elderlyModeProvider.notifier).toggle(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          DisclaimerBanner(access: access),
          Expanded(
            child: FutureBuilder<InteractionAnalysis>(
              future: _analysis,
              builder: (_, s) {
                if (meds.isEmpty) return _empty();
                if (s.connectionState != ConnectionState.done)
                  return const Center(child: CircularProgressIndicator());
                if (s.hasError)
                  return Center(
                    child: FilledButton.icon(
                      onPressed: () => setState(() => _analysis = _load(meds)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry interaction check'),
                    ),
                  );
                return elderly ? _list(meds, s.data!) : _graph(meds, s.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined, size: 62, color: Color(0xff2563eb)),
          SizedBox(height: 16),
          Text(
            'Your interaction map is ready',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            'Add medicines to your cabinet to check documented interactions.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
  List<InteractionRuleLink> _visible(InteractionAnalysis a) =>
      a.links.where((x) => _filter == 'all' || x.severity == _filter).toList();
  Color _color(String s) => s == 'major'
      ? const Color(0xffdc2626)
      : s == 'caution'
      ? const Color(0xffd97706)
      : const Color(0xff2563eb);
  String _label(String s) => s == 'major'
      ? 'Major'
      : s == 'caution'
      ? 'Caution'
      : 'Monitor';
  Widget _graph(List<Medicine> meds, InteractionAnalysis a) {
    final links = _visible(a);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff172554), Color(0xff2563eb)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(Icons.hub_rounded, color: Colors.white, size: 34),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cabinet safety map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${meds.length} medicines - ${a.links.length} documented connections',
                        style: const TextStyle(color: Color(0xffdbeafe)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _metric(
                'Major',
                a.links.where((x) => x.severity == 'major').length,
                const Color(0xffdc2626),
              ),
              const SizedBox(width: 8),
              _metric(
                'Caution',
                a.links.where((x) => x.severity == 'caution').length,
                const Color(0xffd97706),
              ),
              const SizedBox(width: 8),
              _metric(
                'Monitor',
                a.links.where((x) => x.severity == 'monitor').length,
                const Color(0xff2563eb),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: ['all', 'major', 'caution', 'monitor']
                .map(
                  (f) => ChoiceChip(
                    label: Text(f == 'all' ? 'All links' : _label(f)),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          _network(meds, links),
          const SizedBox(height: 14),
          _coverage(a),
          const SizedBox(height: 20),
          Text(
            links.isEmpty
                ? 'No documented links in this view'
                : 'Documented interaction details',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (links.isEmpty)
            const Text(
              'This does not confirm that medicines are safe together. Ask a pharmacist or clinician before combining medicines.',
            )
          else
            ...links.map((x) => _card(meds, x)),
        ],
      ),
    );
  }

  Widget _metric(String t, int n, Color c) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: c.withOpacity(.22)),
      ),
      child: Column(
        children: [
          Text(
            '$n',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: c,
            ),
          ),
          Text(
            t,
            style: const TextStyle(fontSize: 12, color: Color(0xff64748b)),
          ),
        ],
      ),
    ),
  );
  Widget _coverage(InteractionAnalysis a) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xffeff6ff),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: Color(0xff2563eb)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            '${a.coveredMedicines} cabinet medicine(s) have database interaction records. ${a.coverageNote}',
            style: const TextStyle(fontSize: 12.5, height: 1.35),
          ),
        ),
      ],
    ),
  );
  Widget _network(List<Medicine> meds, List<InteractionRuleLink> links) {
    // Keep generous whitespace around the network: this makes panning and
    // zooming feel natural, especially on a narrow phone screen.
    const size = Size(640, 470);
    final positions = <String, Offset>{};
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * .33;
    for (var i = 0; i < meds.length; i++) {
      final angle = 2 * pi * i / meds.length - pi / 2;
      positions[meds[i].id] = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
    }
    final highest = <String, String>{};
    const ranks = {'major': 3, 'caution': 2, 'monitor': 1};
    for (final link in links) {
      for (final id in [link.medicineAId, link.medicineBId]) {
        if ((ranks[link.severity] ?? 0) > (ranks[highest[id]] ?? 0))
          highest[id] = link.severity;
      }
    }
    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: InteractiveViewer(
          constrained: false,
          alignment: Alignment.center,
          boundaryMargin: const EdgeInsets.all(180),
          minScale: .45,
          maxScale: 2.8,
          child: Padding(
            padding: const EdgeInsets.all(88),
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  CustomPaint(
                    size: size,
                    painter: _LinkPainter(links, positions, _color),
                  ),
                  ...meds.map((m) {
                    final p = positions[m.id]!;
                    final color = highest[m.id] == null
                        ? const Color(0xff64748b)
                        : _color(highest[m.id]!);
                    return Positioned(
                      left: p.dx - 43,
                      top: p.dy - 43,
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MedicineDetailScreen(medicine: m),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(44),
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: color, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(.2),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.medication_rounded, color: color),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                ),
                                child: Text(
                                  m.name.split(' ').first,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(List<Medicine> meds, InteractionRuleLink link) {
    final a = meds.where((m) => m.id == link.medicineAId).firstOrNull;
    final b = meds.where((m) => m.id == link.medicineBId).firstOrNull;
    if (a == null || b == null) return const SizedBox();
    final c = _color(link.severity);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.withOpacity(.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showModalBottomSheet(
          context: context,
          showDragHandle: true,
          builder: (_) => Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${a.name} + ${b.name}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(link.description),
                const SizedBox(height: 8),
                Text(
                  'Matched database term: ${link.matchedTerm}',
                  style: const TextStyle(color: Color(0xff64748b)),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Do not change medicines based only on this screen. Confirm with a pharmacist or treating clinician.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 52,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a.name} + ${b.name}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      link.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xff475569)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(_label(link.severity)),
                labelStyle: TextStyle(color: c, fontWeight: FontWeight.w700),
                backgroundColor: c.withOpacity(.1),
                side: BorderSide.none,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(List<Medicine> meds, InteractionAnalysis a) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      _coverage(a),
      const SizedBox(height: 18),
      const Text(
        'Interaction checklist',
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      if (a.links.isEmpty)
        const Text(
          'No documented conflict was found in available database records. This does not guarantee medicines are safe to combine.',
        )
      else
        ...a.links.map((l) => _card(meds, l)),
    ],
  );
}

class _LinkPainter extends CustomPainter {
  const _LinkPainter(this.links, this.positions, this.color);
  final List<InteractionRuleLink> links;
  final Map<String, Offset> positions;
  final Color Function(String) color;
  @override
  void paint(Canvas c, Size s) {
    for (final l in links) {
      final a = positions[l.medicineAId], b = positions[l.medicineBId];
      if (a == null || b == null) continue;
      final p = Paint()
        ..color = color(l.severity)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 - 34);
      c.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LinkPainter old) => true;
}
