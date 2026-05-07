import 'dart:math';
import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/incident.dart';
import '../../models/user.dart';

class ReportIncidentScreen extends StatefulWidget {
  final User user;
  const ReportIncidentScreen({super.key, required this.user});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _db = DatabaseHelper();

  String _selectedType = 'Theft';
  double? _latitude;
  double? _longitude;
  bool _loadingGps = false;
  bool _submitting = false;

  static const List<String> _incidentTypes = [
    'Theft',
    'Harassment',
    'Assault',
    'Suspicious Activity',
    'Vandalism',
    'Road Accident',
    'Other',
  ];

  static const double _klCenterLat = 3.1390;
  static const double _klCenterLng = 101.6869;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _loadingGps = true);
    await Future.delayed(const Duration(seconds: 1));
    final rng = Random();
    setState(() {
      _latitude = _klCenterLat + (rng.nextDouble() - 0.5) * 0.05;
      _longitude = _klCenterLng + (rng.nextDouble() - 0.5) * 0.05;
      _loadingGps = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please get your location first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final incident = Incident(
      userId: widget.user.id!,
      incidentType: _selectedType,
      description: _descCtrl.text.trim(),
      latitude: _latitude!,
      longitude: _longitude!,
      timestamp: DateTime.now().toIso8601String(),
      status: 'Pending',
    );

    await _db.insertIncident(incident);

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Incident reported successfully. Thank you!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Incident'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(children: [
                  Icon(Icons.verified_user_outlined,
                      color: Colors.green.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reporting as: ${widget.user.randomUsername}\n'
                      'Your real identity is hidden from the public.',
                      style: TextStyle(
                          color: Colors.green.shade800, fontSize: 13),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              const Text('Incident Type',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _incidentTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 20),

              const Text('Location',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: _loadingGps ? null : _getLocation,
                icon: _loadingGps
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded),
                label: Text(_loadingGps
                    ? 'Acquiring GPS...'
                    : 'Get Current Location (GPS)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 8),

              if (_latitude != null && _longitude != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(children: [
                    Icon(Icons.location_on_rounded,
                        color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Lat: ${_latitude!.toStringAsFixed(5)},  '
                      'Lng: ${_longitude!.toStringAsFixed(5)}',
                      style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                          fontSize: 13),
                    ),
                  ]),
                ),

              const SizedBox(height: 20),

              const Text('Description',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Describe what happened — include time, direction of suspect, vehicle plate, etc.',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Please provide at least 10 characters'
                    : null,
              ),
              const SizedBox(height: 28),

              _submitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Submit Report',
                          style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
              const SizedBox(height: 12),
              const Text(
                'False reports are a punishable offence. Admins can verify your real identity.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
