import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/incident.dart';
import '../../models/user.dart';
import '../../utils/ui_helpers.dart';
import '../info_screen.dart';
import 'report_incident_screen.dart';

class UserDashboard extends StatefulWidget {
  final User user;
  const UserDashboard({super.key, required this.user});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final _db = DatabaseHelper();
  List<Incident> _incidents = [];
  double _safetyScore = 100;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final (incidents, score) = await (
      _db.getPublicIncidents(),
      _db.calculateSafetyScore(),
    ).wait;
    setState(() {
      _incidents = incidents;
      _safetyScore = score;
      _loading = false;
    });
  }

  Future<void> _openReport() async {
    final refreshed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => ReportIncidentScreen(user: widget.user)),
    );
    if (refreshed == true) _load();
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SafeZone', style: TextStyle(fontSize: 18)),
            Text(widget.user.randomUsername,
                style:
                    const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openReport,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Report Incident'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        children: [
                          _SafetyScoreCard(score: _safetyScore),
                          const SizedBox(height: 16),
                          _SimulatedMapCard(incidents: _incidents),
                          const SizedBox(height: 16),
                          Row(children: [
                            const Icon(Icons.feed_rounded,
                                size: 18, color: Colors.black54),
                            const SizedBox(width: 6),
                            Text(
                              'Community Feed (${_incidents.length} reports)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ]),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  if (_incidents.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                size: 64, color: Colors.green),
                            SizedBox(height: 12),
                            Text('No active incidents reported.',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList.builder(
                        itemCount: _incidents.length,
                        itemBuilder: (_, i) =>
                            _IncidentCard(incident: _incidents[i]),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _SafetyScoreCard extends StatelessWidget {
  final double score;
  const _SafetyScoreCard({required this.score});

  Color get _color {
    if (score >= 80) return Colors.green.shade600;
    if (score >= 60) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  String get _label {
    if (score >= 80) return 'SAFE ZONE';
    if (score >= 60) return 'MODERATE RISK';
    return 'HIGH RISK';
  }

  String get _advice {
    if (score >= 80) return 'Area is generally safe. Stay alert.';
    if (score >= 60) return 'Some incidents reported. Exercise caution.';
    return 'High incident rate. Avoid travelling alone.';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Icon(Icons.analytics_rounded, color: _color, size: 20),
            const SizedBox(width: 8),
            const Text('Area Safety Score',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _color),
              ),
              child: Text(_label,
                  style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  score.toInt().toString(),
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _color),
                ),
              ]),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score: ${score.toInt()} / 100',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(_advice,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: score / 100,
                      color: _color,
                      backgroundColor: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                  ]),
            ),
          ]),
          const SizedBox(height: 8),
          const Text(
            'Score based on incidents in the last 30 days.',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ]),
      ),
    );
  }
}

class _SimulatedMapCard extends StatelessWidget {
  final List<Incident> incidents;
  const _SimulatedMapCard({required this.incidents});

  static const double _minLat = 3.10;
  static const double _maxLat = 3.18;
  static const double _minLng = 101.65;
  static const double _maxLng = 101.73;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(children: [
              const Icon(Icons.map_rounded, size: 18, color: Colors.blueGrey),
              const SizedBox(width: 6),
              const Text('Incident Map (Simulated)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('KL Area',
                    style: TextStyle(fontSize: 11, color: Colors.blue)),
              ),
            ]),
          ),
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            const h = 170.0;
            return Container(
              width: w,
              height: h,
              color: const Color(0xFFE8F4F8),
              child: Stack(children: [
                CustomPaint(painter: _GridPainter(), size: Size(w, h)),
                CustomPaint(painter: _RoadPainter(), size: Size(w, h)),
                ...incidents.take(15).map((inc) {
                  final x = ((inc.longitude - _minLng) /
                          (_maxLng - _minLng)) *
                      w;
                  final y = ((_maxLat - inc.latitude) /
                          (_maxLat - _minLat)) *
                      h;
                  final color = incidentTypeColor(inc.incidentType);
                  return Positioned(
                    left: x.clamp(8.0, w - 20),
                    top: y.clamp(8.0, h - 20),
                    child: Tooltip(
                      message: inc.incidentType,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const Positioned(
                  bottom: 4,
                  right: 6,
                  child: Text('© Simulated — SafeZone',
                      style: TextStyle(
                          fontSize: 9, color: Colors.black38)),
                ),
              ]),
            );
          }),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                _LegendDot(color: Colors.red, label: 'Theft'),
                _LegendDot(color: Colors.purple, label: 'Harassment'),
                _LegendDot(color: Colors.orange, label: 'Vandalism'),
                _LegendDot(color: Colors.amber.shade700, label: 'Suspicious'),
                _LegendDot(color: Colors.blue, label: 'Road Accident'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
    ]);
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCFE2EC)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB0C4D8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), paint);
    canvas.drawLine(
        Offset(size.width * 0.4, 0), Offset(size.width * 0.4, size.height), paint);
    paint.strokeWidth = 3;
    canvas.drawLine(
        Offset(size.width * 0.6, 0), Offset(size.width, size.height * 0.6), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IncidentCard extends StatelessWidget {
  final Incident incident;
  const _IncidentCard({required this.incident});

  Color get _statusColor {
    switch (incident.status) {
      case 'Pending': return Colors.orange;
      case 'Verified': return Colors.blue;
      case 'Resolved': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData get _typeIcon {
    switch (incident.incidentType) {
      case 'Theft': return Icons.money_off_rounded;
      case 'Assault': return Icons.personal_injury_rounded;
      case 'Harassment': return Icons.record_voice_over_rounded;
      case 'Vandalism': return Icons.broken_image_rounded;
      case 'Suspicious Activity': return Icons.visibility_rounded;
      case 'Road Accident': return Icons.car_crash_rounded;
      default: return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = incidentTypeColor(incident.incidentType);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_typeIcon, color: typeColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(incident.incidentType,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: typeColor)),
                    Text(
                      'Reported by ${incident.reporterUsername ?? 'Anonymous'}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor),
              ),
              child: Text(incident.status,
                  style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(incident.description,
              style: const TextStyle(fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.location_on_outlined,
                size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${incident.latitude.toStringAsFixed(4)}, '
              '${incident.longitude.toStringAsFixed(4)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Spacer(),
            const Icon(Icons.access_time_rounded,
                size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(incident.formattedTime,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}
