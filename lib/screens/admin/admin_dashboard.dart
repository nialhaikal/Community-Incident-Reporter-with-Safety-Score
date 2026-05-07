import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/incident.dart';
import '../../models/user.dart';
import '../../utils/ui_helpers.dart';
import '../info_screen.dart';

class AdminDashboard extends StatefulWidget {
  final User admin;
  const AdminDashboard({super.key, required this.admin});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _db = DatabaseHelper();
  List<Incident> _incidents = [];
  bool _loading = true;
  String _filterStatus = 'All';

  static const List<String> _statusOptions = [
    'Pending', 'Verified', 'Resolved', 'False Report'
  ];

  static const List<String> _statusFilters = ['All', ..._statusOptions];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final incidents = await _db.getAllIncidentsWithUser();
    setState(() {
      _incidents = incidents;
      _loading = false;
    });
  }

  List<Incident> get _filtered => _filterStatus == 'All'
      ? _incidents
      : _incidents.where((i) => i.status == _filterStatus).toList();

  void _showStatusDialog(Incident incident) {
    String selected = incident.status;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.edit_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Update Status'),
          ]),
          content: RadioGroup<String>(
            groupValue: selected,
            onChanged: (v) => setDlg(() => selected = v ?? selected),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _statusOptions
                  .map((s) => RadioListTile<String>(
                        title: Text(s),
                        value: s,
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _db.updateIncidentStatus(incident.id!, selected);
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Incident incident) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.delete_forever_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete Incident'),
        ]),
        content: Text(
          'Permanently delete this ${incident.incidentType} report by '
          '${incident.reporterRealName}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _db.deleteIncident(incident.id!);
              if (mounted) Navigator.pop(context);
              _load();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const InfoScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Admin Dashboard',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          Text(widget.admin.randomUsername,
              style: const TextStyle(color: Colors.amber, fontSize: 12)),
        ]),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(children: [
        Container(
          color: const Color(0xFF0D1B2A),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _StatsRow(incidents: _incidents),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.amber.shade900.withValues(alpha: 0.3),
          child: const Row(children: [
            Icon(Icons.security_rounded, color: Colors.amber, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'ADMIN VIEW: Real identities are visible. '
                'Handle all personal data in accordance with PDPA.',
                style: TextStyle(
                    color: Colors.amber, fontSize: 11.5, height: 1.3),
              ),
            ),
          ]),
        ),

        Container(
          color: const Color(0xFF112233),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(s),
                          selected: _filterStatus == s,
                          onSelected: (_) =>
                              setState(() => _filterStatus = s),
                          selectedColor: Colors.amber.shade700,
                          labelStyle: TextStyle(
                            color: _filterStatus == s
                                ? Colors.black
                                : Colors.white70,
                            fontSize: 12,
                          ),
                          backgroundColor: const Color(0xFF1A2E45),
                          side: BorderSide.none,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.amber))
              : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 60, color: Colors.white24),
                          const SizedBox(height: 12),
                          Text(
                            _filterStatus == 'All'
                                ? 'No incidents in database.'
                                : 'No "$_filterStatus" incidents.',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: Colors.amber,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _AdminIncidentCard(
                          incident: filtered[i],
                          onUpdateStatus: () =>
                              _showStatusDialog(filtered[i]),
                          onDelete: () => _confirmDelete(filtered[i]),
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<Incident> incidents;
  const _StatsRow({required this.incidents});

  int _count(String status) =>
      incidents.where((i) => i.status == status).length;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _StatChip(label: 'Total', value: incidents.length, color: Colors.white70),
      const SizedBox(width: 8),
      _StatChip(label: 'Pending', value: _count('Pending'), color: Colors.orange),
      const SizedBox(width: 8),
      _StatChip(label: 'Verified', value: _count('Verified'), color: Colors.blue),
      const SizedBox(width: 8),
      _StatChip(label: 'Resolved', value: _count('Resolved'), color: Colors.green),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(value.toString(),
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10)),
        ]),
      ),
    );
  }
}

class _AdminIncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback onUpdateStatus;
  final VoidCallback onDelete;

  const _AdminIncidentCard({
    required this.incident,
    required this.onUpdateStatus,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (incident.status) {
      case 'Pending': return Colors.orange;
      case 'Verified': return Colors.blue;
      case 'Resolved': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = incidentTypeColor(incident.incidentType, dark: true);
    return Card(
      color: const Color(0xFF112233),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: _statusColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(incident.incidentType,
                      style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor),
                  ),
                  child: Text(incident.status,
                      style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.red.shade800.withValues(alpha: 0.5)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.admin_panel_settings_rounded,
                            color: Colors.redAccent, size: 14),
                        SizedBox(width: 6),
                        Text('Verified Reporter Identity',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.person_rounded,
                            color: Colors.white60, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          incident.reporterRealName ?? 'Unknown',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.credit_card_rounded,
                            color: Colors.white60, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'IC: ${incident.reporterIcNumber ?? 'N/A'}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.badge_outlined,
                            color: Colors.white38, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          incident.reporterUsername ?? '',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                      ]),
                    ]),
              ),
              const SizedBox(height: 10),

              Text(incident.description,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13.5, height: 1.4)),
              const SizedBox(height: 10),

              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: Colors.white38),
                const SizedBox(width: 4),
                Text(
                  '${incident.latitude.toStringAsFixed(4)}, '
                  '${incident.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11.5),
                ),
                const Spacer(),
                const Icon(Icons.access_time_rounded,
                    size: 13, color: Colors.white38),
                const SizedBox(width: 4),
                Text(incident.formattedTime,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11.5)),
              ]),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onUpdateStatus,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Update Status',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber,
                      side: BorderSide(
                          color: Colors.amber.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Delete',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      side: BorderSide(
                          color: Colors.red.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ]),
            ]),
      ),
    );
  }
}
