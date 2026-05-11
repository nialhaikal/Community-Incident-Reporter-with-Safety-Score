import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../database/database_helper.dart';
import '../../models/incident.dart';
import '../../models/user.dart';
import '../../services/notification_service.dart';
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
  bool _locationBased = false;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _load();
    _startLocationStream();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // Try to get a one-shot GPS fix for location-aware score
    Position? pos;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 6),
          ),
        );
      }
    } catch (_) {}

    final scoreFuture = pos != null
        ? _db.calculateSafetyScoreNear(pos.latitude, pos.longitude)
        : _db.calculateSafetyScore();

    final (incidents, score) =
        await (_db.getPublicIncidents(), scoreFuture).wait;

    setState(() {
      _incidents = incidents;
      _safetyScore = score;
      _locationBased = pos != null;
      _loading = false;
    });

    if (score < 60) await NotificationService().showSafetyAlert(score);
  }

  /// Recalculates the safety score in real-time as the user moves.
  void _startLocationStream() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm != LocationPermission.always &&
        perm != LocationPermission.whileInUse) return;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 100, // recalculate every 100 m
      ),
    ).listen((pos) async {
      final score =
          await _db.calculateSafetyScoreNear(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _safetyScore = score;
          _locationBased = true;
        });
      }
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
                          _SafetyScoreCard(score: _safetyScore, locationBased: _locationBased),
                          const SizedBox(height: 16),
                          _GoogleMapCard(incidents: _incidents),
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
  final bool locationBased;
  const _SafetyScoreCard({required this.score, this.locationBased = false});

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
          Text(
            locationBased
                ? 'Score based on incidents within 3 km of your location.'
                : 'Score based on all incidents in the last 30 days.',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ]),
      ),
    );
  }
}

class _GoogleMapCard extends StatefulWidget {
  final List<Incident> incidents;
  const _GoogleMapCard({required this.incidents});

  @override
  State<_GoogleMapCard> createState() => _GoogleMapCardState();
}

class _GoogleMapCardState extends State<_GoogleMapCard> {
  static const LatLng _klDefault = LatLng(3.1390, 101.6869);
  GoogleMapController? _controller;
  LatLng _center = _klDefault;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  @override
  void didUpdateWidget(_GoogleMapCard old) {
    super.didUpdateWidget(old);
    if (old.incidents != widget.incidents) _buildMarkers();
  }

  Future<void> _centerOnUser() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      // Request permission if not yet decided
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 8),
          ),
        );
        if (!mounted) return;
        final latlng = LatLng(pos.latitude, pos.longitude);
        setState(() => _center = latlng);
        _controller?.animateCamera(CameraUpdate.newLatLng(latlng));
      }
    } catch (_) {}
  }

  void _buildMarkers() {
    final markers = <Marker>{};
    for (final inc in widget.incidents) {
      markers.add(Marker(
        markerId: MarkerId(inc.id ?? inc.timestamp),
        position: LatLng(inc.latitude, inc.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(inc.incidentType)),
        infoWindow: InfoWindow(
          title: inc.incidentType,
          snippet: '${inc.reporterUsername ?? "Anonymous"} • ${inc.status}',
        ),
      ));
    }
    if (mounted) setState(() => _markers = markers);
  }

  static double _markerHue(String type) {
    switch (type) {
      case 'Theft':               return BitmapDescriptor.hueRed;
      case 'Assault':             return BitmapDescriptor.hueViolet;
      case 'Harassment':          return BitmapDescriptor.hueMagenta;
      case 'Vandalism':           return BitmapDescriptor.hueOrange;
      case 'Suspicious Activity': return BitmapDescriptor.hueYellow;
      case 'Road Accident':       return BitmapDescriptor.hueCyan;
      default:                    return BitmapDescriptor.hueAzure;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
            child: Row(children: [
              const Icon(Icons.map_rounded, size: 18, color: Colors.blueGrey),
              const SizedBox(width: 6),
              const Text('Incident Map',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Text('${widget.incidents.length} active reports',
                  style: const TextStyle(fontSize: 11, color: Colors.blue)),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.fullscreen_rounded,
                    size: 20, color: Colors.blueGrey),
                tooltip: 'Full screen',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _FullScreenMapScreen(
                      incidents: widget.incidents,
                    ),
                  ),
                ),
              ),
            ]),
          ),
          SizedBox(
            height: 260,
            child: GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _center, zoom: 14),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              onMapCreated: (c) {
                _controller = c;
                _centerOnUser();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                _MapDot(color: Colors.red, label: 'Theft'),
                _MapDot(color: Colors.purple, label: 'Assault'),
                _MapDot(color: Colors.pink, label: 'Harassment'),
                _MapDot(color: Colors.orange, label: 'Vandalism'),
                _MapDot(color: Colors.amber.shade700, label: 'Suspicious'),
                _MapDot(color: Colors.cyan, label: 'Road Accident'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapDot extends StatelessWidget {
  final Color color;
  final String label;
  const _MapDot({required this.color, required this.label});

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

class _FullScreenMapScreen extends StatefulWidget {
  final List<Incident> incidents;
  const _FullScreenMapScreen({required this.incidents});

  @override
  State<_FullScreenMapScreen> createState() => _FullScreenMapScreenState();
}

class _FullScreenMapScreenState extends State<_FullScreenMapScreen> {
  static const LatLng _klDefault = LatLng(3.1390, 101.6869);
  GoogleMapController? _controller;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _buildMarkers();
  }

  void _buildMarkers() {
    final markers = <Marker>{};
    for (final inc in widget.incidents) {
      markers.add(Marker(
        markerId: MarkerId(inc.id ?? inc.timestamp),
        position: LatLng(inc.latitude, inc.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            _GoogleMapCardState._markerHue(inc.incidentType)),
        infoWindow: InfoWindow(
          title: inc.incidentType,
          snippet: '${inc.reporterUsername ?? "Anonymous"} • ${inc.status}',
        ),
      ));
    }
    setState(() => _markers = markers);
  }

  Future<void> _centerOnUser() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 8),
          ),
        );
        if (!mounted) return;
        _controller?.animateCamera(
            CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Incident Map (${widget.incidents.length} reports)'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'My location',
            onPressed: _centerOnUser,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                const CameraPosition(target: _klDefault, zoom: 14),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: true,
            onMapCreated: (c) {
              _controller = c;
              _centerOnUser();
            },
          ),
          Positioned(
            bottom: 16,
            left: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _MapDot(color: Colors.red, label: 'Theft'),
                    _MapDot(color: Colors.purple, label: 'Assault'),
                    _MapDot(color: Colors.pink, label: 'Harassment'),
                    _MapDot(color: Colors.orange, label: 'Vandalism'),
                    _MapDot(color: Colors.amber.shade700, label: 'Suspicious'),
                    _MapDot(color: Colors.cyan, label: 'Road Accident'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
