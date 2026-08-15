import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'accessibility_config.dart';
import 'shared_states.dart';
import 'shared_widgets.dart';
import 'medicine_detail.dart';

// --- DATA STRUCTURE FOR INTERACTIONS ---
class InteractionLink {
  final Medicine medicineA;
  final Medicine medicineB;
  final String severity; // 'contraindicated', 'caution', 'monitor'
  final String description;

  InteractionLink({
    required this.medicineA,
    required this.medicineB,
    required this.severity,
    required this.description,
  });
}

class InteractionGraphScreen extends ConsumerStatefulWidget {
  const InteractionGraphScreen({super.key});

  @override
  ConsumerState<InteractionGraphScreen> createState() => _InteractionGraphScreenState();
}

class _InteractionGraphScreenState extends ConsumerState<InteractionGraphScreen> {
  // Generate active interaction links inside cabinet
  List<InteractionLink> _getInteractionLinks(List<Medicine> cabinet) {
    final List<InteractionLink> links = [];
    
    // Check all unique pairs
    for (int i = 0; i < cabinet.length; i++) {
      for (int j = i + 1; j < cabinet.length; j++) {
        final medA = cabinet[i];
        final medB = cabinet[j];

        if ((medA.name.contains('Paracetamol') && medB.name.contains('Metformin')) ||
            (medB.name.contains('Paracetamol') && medA.name.contains('Metformin'))) {
          links.add(
            InteractionLink(
              medicineA: medA,
              medicineB: medB,
              severity: 'monitor',
              description: 'Concomitant use may alter glycemic control. Monitor blood glucose closely.',
            ),
          );
        }
      }
    }
    return links;
  }

  @override
  Widget build(BuildContext context) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final cabinet = ref.watch(cabinetProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);
    
    final links = _getInteractionLinks(cabinet);

    return Scaffold(
      backgroundColor: access.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: access.textColor,
        elevation: 0,
        title: Text(
          'Interaction Graph',
          style: access.getTextStyle(
            baseSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Elderly Mode Switch
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: ElderlyModeToggle(
              access: access,
              value: isElderlyMode,
              onChanged: (val) {
                ref.read(elderlyModeProvider.notifier).toggle();
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Shared disclaimer banner at top
          DisclaimerBanner(access: access),

          // Core content: Network Graph vs Simple List depending on Mode
          Expanded(
            child: isElderlyMode
                ? _buildSimpleListMode(links, cabinet, access)
                : _buildGraphNetworkMode(links, cabinet, access),
          ),
        ],
      ),
    );
  }

  // --- ELDERLY MODE: HIGH-CONTRAST SIMPLIFIED LIST ---
  Widget _buildSimpleListMode(
    List<InteractionLink> links,
    List<Medicine> cabinet,
    AccessibilityConfig access,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(access.scaleSpacing(20.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safety Warning Summary',
            style: access.getTextStyle(
              baseSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'High-contrast safety checklist. Yellow indicates caution items to monitor.',
            style: access.getTextStyle(
              baseSize: 14.0,
              color: access.textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),

          if (links.isEmpty)
            Container(
              padding: EdgeInsets.all(access.scaleSpacing(20.0)),
              decoration: BoxDecoration(
                color: access.successGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: access.successGreen, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: access.successGreen, size: access.scaleText(28.0)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'All medicines in your cabinet are safe to take together.',
                      style: access.getTextStyle(
                        baseSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: access.successGreen,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: links.length,
              itemBuilder: (context, index) {
                final link = links[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(access.scaleSpacing(18.0)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: access.warmAmber, width: 2.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: access.warmAmber, size: access.scaleText(28.0)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${link.medicineA.name} + ${link.medicineB.name}',
                              style: access.getTextStyle(
                                baseSize: 18.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'SEVERITY: MONITOR',
                        style: access.getTextStyle(
                          baseSize: 14.0,
                          fontWeight: FontWeight.w900,
                          color: access.warmAmber,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        link.description,
                        style: access.getTextStyle(
                          baseSize: 15.0,
                          color: access.textColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- NORMAL MODE: CUSTOM CANVAS NETWORK GRAPH ---
  Widget _buildGraphNetworkMode(
    List<InteractionLink> links,
    List<Medicine> cabinet,
    AccessibilityConfig access,
  ) {
    if (cabinet.isEmpty) {
      return Center(
        child: Text(
          'Add medicines to visualize relationships.',
          style: access.getTextStyle(baseSize: 15.0, color: access.textColor.withOpacity(0.5)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Calculate circular node positions
        final center = Offset(width / 2, height / 2 - 20);
        final radius = min(width, height) / 3.5;

        final Map<String, Offset> nodePositions = {};
        for (int i = 0; i < cabinet.length; i++) {
          final angle = 2 * pi * i / cabinet.length - pi / 2;
          final x = center.dx + radius * cos(angle);
          final y = center.dy + radius * sin(angle);
          nodePositions[cabinet[i].id] = Offset(x, y);
        }

        return Stack(
          children: [
            // Background Canvas to draw connecting links
            CustomPaint(
              size: Size(width, height),
              painter: GraphLinkPainter(
                links: links,
                nodePositions: nodePositions,
                access: access,
              ),
            ),

            // Foreground: Positioned interactive node buttons
            ...cabinet.map((med) {
              final pos = nodePositions[med.id]!;
              final hasInteraction = links.any((l) => l.medicineA.id == med.id || l.medicineB.id == med.id);

              return Positioned(
                left: pos.dx - 45,
                top: pos.dy - 45,
                child: GestureDetector(
                  onTap: () {
                    // Navigate to detail view
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicineDetailScreen(medicine: med),
                      ),
                    );
                  },
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (hasInteraction ? access.warmAmber : access.primaryTeal).withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: hasInteraction ? access.warmAmber : access.primaryTeal,
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_rounded,
                            size: 20,
                            color: hasInteraction ? access.warmAmber : access.primaryTeal,
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              med.name.split(' ')[0],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: access.getTextStyle(
                                baseSize: 11.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Top Status Overlay
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: access.textColor.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cabinet Safety Graph',
                      style: access.getTextStyle(baseSize: 14.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      links.isEmpty ? 'All Safe' : '${links.length} Flagged',
                      style: access.getTextStyle(
                        baseSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: links.isEmpty ? access.successGreen : access.warmAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- CUSTOM PAINTER TO DRAW CONNECTIONS ---
class GraphLinkPainter extends CustomPainter {
  final List<InteractionLink> links;
  final Map<String, Offset> nodePositions;
  final AccessibilityConfig access;

  GraphLinkPainter({
    required this.links,
    required this.nodePositions,
    required this.access,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var link in links) {
      final posA = nodePositions[link.medicineA.id];
      final posB = nodePositions[link.medicineB.id];

      if (posA != null && posB != null) {
        Color strokeColor;
        switch (link.severity.toLowerCase()) {
          case 'contraindicated':
            strokeColor = access.alertRed;
            break;
          case 'caution':
          case 'monitor':
          default:
            strokeColor = access.warmAmber;
            break;
        }

        final paint = Paint()
          ..color = strokeColor
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke;

        // Draw line between nodes
        canvas.drawLine(posA, posB, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
