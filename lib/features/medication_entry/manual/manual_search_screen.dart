import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../accessibility_config.dart';
import '../../../shared_states.dart';
import '../../../shared_widgets.dart';
import '../../../services/api_service.dart';
import '../../../models/medicine_model.dart';
import '../../../add_medicine_ocr.dart';
import '../../../screens/camera_screen.dart';

class ManualSearchScreen extends ConsumerStatefulWidget {
  const ManualSearchScreen({super.key});

  @override
  ConsumerState<ManualSearchScreen> createState() => _ManualSearchScreenState();
}

class _ManualSearchScreenState extends ConsumerState<ManualSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchedMedicine> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final results = await apiService.searchMedicines(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
      }
    }
  }

  Future<void> _openCameraScan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );

    if (result != null && result is MedicineModel && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AddMedicineOcrScreen(prefilledMedicine: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isElderlyMode = ref.watch(elderlyModeProvider);
    final access = AccessibilityConfig(isElderlyMode: isElderlyMode);

    return Scaffold(
      backgroundColor: access.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: access.textColor,
        elevation: 0,
        title: Text(
          'Add Medicine Manually',
          style: access.getTextStyle(
            baseSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          DisclaimerBanner(access: access),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: access.getTextStyle(baseSize: 16.0),
              decoration: InputDecoration(
                labelText: 'Search Medicine Database',
                hintText: 'Enter brand name or generic name...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: access.textColor.withOpacity(0.08), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: access.primaryTeal, width: 2.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0F766E),
                    ),
                  )
                : _results.isEmpty && _hasSearched
                    ? _buildZeroResultsView(access)
                    : _buildResultsList(access),
          ),
        ],
      ),
    );
  }

  Widget _buildZeroResultsView(AccessibilityConfig access) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: access.scaleText(64.0),
            color: access.textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Not found — try scanning the package instead',
            textAlign: TextAlign.center,
            style: access.getTextStyle(
              baseSize: 16.0,
              fontWeight: FontWeight.bold,
              color: access.textColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openCameraScan,
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
            label: Text(
              'Scan Package',
              style: access.getTextStyle(
                baseSize: 15.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: access.primaryTeal,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, access.minTapTargetSize),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(AccessibilityConfig access) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final med = _results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: access.textColor.withOpacity(0.08), width: 1.5),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            leading: CircleAvatar(
              backgroundColor: access.primaryTeal.withOpacity(0.1),
              child: Icon(Icons.medication_rounded, color: access.primaryTeal),
            ),
            title: Text(
              med.brandName,
              style: access.getTextStyle(baseSize: 16.0, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              med.genericName,
              style: access.getTextStyle(baseSize: 14.0, color: access.textColor.withOpacity(0.6)),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              final prefilledModel = MedicineModel(
                id: med.id,
                brandName: med.brandName,
                genericName: med.genericName,
                mrp: med.price,
                manufacturer: med.manufacturer,
                substitutes: med.substitutes,
                sideEffects: med.sideEffects,
                verifiedSource: 2, // Manual
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMedicineOcrScreen(prefilledMedicine: prefilledModel),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
