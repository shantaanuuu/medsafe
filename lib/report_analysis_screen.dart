import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';

class ReportAnalysisScreen extends StatefulWidget {
  const ReportAnalysisScreen({super.key});
  @override
  State<ReportAnalysisScreen> createState() => _ReportAnalysisScreenState();
}

class _ReportAnalysisScreenState extends State<ReportAnalysisScreen> {
  List<Map<String, dynamic>> reports = [];
  bool loading = false;
  String? error;
  String get key =>
      'report_history_${FirebaseAuth.instance.currentUser?.uid ?? 'guest'}';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted)
      setState(
        () => reports = (jsonDecode(p.getString(key) ?? '[]') as List)
            .whereType<Map>()
            .map((x) => Map<String, dynamic>.from(x))
            .toList(),
      );
  }

  Future<void> pick() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (picked?.files.single.path == null) return;
    setState(() => loading = true);
    try {
      final source = File(picked!.files.single.path!);
      final a = await ApiService(
        baseUrl: const String.fromEnvironment(
          'BACKEND_BASE_URL',
          defaultValue: 'http://10.0.2.2:5000',
        ),
      ).analyseReport(source);
      final dir = await getApplicationDocumentsDirectory();
      final target = File(
        '${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await source.copy(target.path);
      final item = {
        'name': picked.files.single.name,
        'path': target.path,
        'createdAt': DateTime.now().toIso8601String(),
        'type': a.type,
        'summary': a.summary,
        'urgent': a.urgent,
        'urgentReason': a.urgentReason,
        'highlights': a.highlights,
        'questions': a.questions,
      };
      reports.insert(0, item);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(reports));
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted)
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> deleteReport(Map<String, dynamic> report) async {
    final path = report['path']?.toString();
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    reports.remove(report);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(reports));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Report analysis',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: loading ? null : pick,
      icon: const Icon(Icons.upload_file),
      label: const Text('Add PDF'),
    ),
    body: reports.isEmpty
        ? _empty()
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
              ...reports.map(_card),
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
            Icons.query_stats_rounded,
            size: 64,
            color: Color(0xff2563eb),
          ),
          const SizedBox(height: 16),
          const Text(
            'Understand your health report',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a blood test or other text-based PDF. Review the original report and discuss findings with your clinician.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: loading ? null : pick,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.upload_file),
            label: Text(loading ? 'Reading report...' : 'Upload PDF report'),
          ),
        ],
      ),
    ),
  );
  Widget _card(Map<String, dynamic> r) {
    final highlights = r['highlights'] is List
        ? r['highlights'] as List
        : const [];
    final questions = r['questions'] is List
        ? r['questions'] as List
        : const [];
    return Card(
      child: ListTile(
        onTap: () => showModalBottomSheet(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (_) => DraggableScrollableSheet(
            expand: false,
            builder: (_, c) => ListView(
              controller: c,
              padding: const EdgeInsets.all(22),
              children: [
                Text(
                  r['name'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  r['type'],
                  style: const TextStyle(color: Color(0xff2563eb)),
                ),
                if (r['urgent'] == true)
                  Text(
                    r['urgentReason'],
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 14),
                Text(r['summary']),
                const SizedBox(height: 16),
                const Text(
                  'Highlights',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                ...highlights.map(
                  (x) => ListTile(
                    title: Text('${x['label']}: ${x['value']}'),
                    subtitle: Text(x['note']?.toString() ?? ''),
                    trailing: Text(x['status']?.toString() ?? ''),
                  ),
                ),
                const Text(
                  'Questions for your doctor',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                ...questions.map(
                  (x) => ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: Text(x.toString()),
                  ),
                ),
              ],
            ),
          ),
        ),
        leading: const CircleAvatar(child: Icon(Icons.description_outlined)),
        title: Text(r['name']),
        subtitle: Text(
          r['summary'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (r['urgent'] == true)
              const Icon(Icons.priority_high, color: Colors.red),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete report',
              onPressed: () => deleteReport(r),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

Future<void> clearLocalReports() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  final p = await SharedPreferences.getInstance();
  final history =
      jsonDecode(p.getString('report_history_$uid') ?? '[]') as List;
  for (final item in history.whereType<Map>()) {
    final path = item['path']?.toString();
    if (path != null) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
  }
  await p.remove('report_history_$uid');
}
