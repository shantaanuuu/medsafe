import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_medicine_ocr.dart';
import 'models/medicine_model.dart';
import 'screens/camera_screen.dart';
import 'services/api_service.dart';

class PrescriptionScanScreen extends ConsumerStatefulWidget {
  const PrescriptionScanScreen({super.key});
  @override
  ConsumerState<PrescriptionScanScreen> createState() =>
      _PrescriptionScanScreenState();
}

class _PrescriptionScanScreenState
    extends ConsumerState<PrescriptionScanScreen> {
  List<MedicineModel> medicines = [];
  String notes = '';
  final Set<int> added = {};
  bool scanning = false;
  Future<void> scan() async {
    setState(() => scanning = true);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CameraScreen(prescriptionMode: true),
      ),
    );
    if (result is PrescriptionScanResult && mounted)
      setState(() {
        medicines = result.medicines;
        notes = result.notes;
      });
    if (mounted) setState(() => scanning = false);
  }

  Future<void> addOne(int index) async {
    final med = medicines[index];
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicineOcrScreen(prefilledMedicine: med),
      ),
    );
    if (ok == true && mounted) setState(() => added.add(index));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Scan prescription',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: medicines.isEmpty
        ? _empty()
        : Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xffeff6ff),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Review every medicine and dose against the original prescription before adding. $notes',
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: medicines.length,
                  itemBuilder: (_, i) {
                    final m = medicines[i];
                    final done = added.contains(i);
                    return Card(
                      margin: const EdgeInsets.fromLTRB(16, 5, 16, 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: done
                              ? const Color(0xffdcfce7)
                              : const Color(0xffdbeafe),
                          child: Icon(
                            done ? Icons.check : Icons.medication,
                            color: done
                                ? const Color(0xff15803d)
                                : const Color(0xff2563eb),
                          ),
                        ),
                        title: Text(
                          m.brandName ?? 'Medicine',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          [m.genericName, m.strength]
                              .whereType<String>()
                              .where((x) => x.isNotEmpty)
                              .join('\n'),
                        ),
                        trailing: done
                            ? const Text(
                                'Added',
                                style: TextStyle(
                                  color: Color(0xff15803d),
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : FilledButton(
                                onPressed: () => addOne(i),
                                child: const Text('Review & add'),
                              ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: scan,
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Scan another prescription'),
                ),
              ),
            ],
          ),
  );
  Widget _empty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 64,
            color: Color(0xff2563eb),
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan a doctor prescription',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Take a clear, full-page photo. You will review each detected medicine before it is added.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: scanning ? null : scan,
            icon: scanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.camera_alt),
            label: Text(
              scanning ? 'Reading prescription...' : 'Capture prescription',
            ),
          ),
        ],
      ),
    ),
  );
}
