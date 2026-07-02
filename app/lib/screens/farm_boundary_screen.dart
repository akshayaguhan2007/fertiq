import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../services/app_strings.dart';
import '../services/mock_data.dart';
import '../theme.dart';

class FarmBoundaryScreen extends StatefulWidget {
  const FarmBoundaryScreen({super.key});
  @override
  State<FarmBoundaryScreen> createState() => _FarmBoundaryScreenState();
}

class _FarmBoundaryScreenState extends State<FarmBoundaryScreen> {
  final _mapCtrl = MapController();
  final _points  = <LatLng>[];

  final _defaultCenter = LatLng(
    MockData.farm.location.latitude,
    MockData.farm.location.longitude,
  );

  void _addPoint(LatLng point) => setState(() => _points.add(point));

  void _removeLastPoint() {
    if (_points.isNotEmpty) setState(() => _points.removeLast());
  }

  void _clear() => setState(() => _points.clear());

  double get _areaHa {
    if (_points.length < 3) return 0;
    // Shoelace formula on spherical coords (approximate)
    double area = 0;
    final n = _points.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final lat1 = _points[i].latitude * math.pi / 180;
      final lat2 = _points[j].latitude * math.pi / 180;
      final lng1 = _points[i].longitude * math.pi / 180;
      final lng2 = _points[j].longitude * math.pi / 180;
      area += (lng2 - lng1) * (2 + math.sin(lat1) + math.sin(lat2));
    }
    area = (area * 6378137 * 6378137 / 2).abs();
    return area / 10000; // m² → hectares
  }

  void _save() {
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.of(context).minPointsWarning,
            style: GoogleFonts.plusJakartaSans(fontSize: 13)),
      ));
      return;
    }
    // GeoJSON polygon — wire up to FirestoreService once Firebase is configured:
    // final geoJson = {
    //   'type': 'Polygon',
    //   'coordinates': [_points.map((p) => [p.longitude, p.latitude]).toList()]
    // };
    // await FirestoreService().saveBoundary(MockData.farm.id, geoJson);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Boundary saved! Area: ${_areaHa.toStringAsFixed(2)} ha',
          style: GoogleFonts.plusJakartaSans(fontSize: 13)),
      backgroundColor: kPrimary,
    ));
    Navigator.of(context).pop(_areaHa);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final hasEnough = _points.length >= 3;

    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t.drawFarmBoundary,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark)),
        actions: [
          if (_points.isNotEmpty)
            TextButton.icon(
              onPressed: _removeLastPoint,
              icon: const Icon(Icons.undo_rounded, size: 16, color: kAccentGold),
              label: Text('Undo', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kAccentGold)),
            ),
          if (_points.isNotEmpty)
            TextButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: kRed),
              label: Text(t.clearBoundary,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kRed)),
            ),
        ],
      ),
      body: Stack(children: [
        // ── Map ────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: 15,
            onTap: (_, latLng) => _addPoint(latLng),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.carbontech.app',
            ),

            // Filled polygon
            if (_points.length >= 3)
              PolygonLayer(polygons: [
                Polygon(
                  points: _points,
                  color: kPrimary.withValues(alpha: 0.2),
                  borderColor: kPrimary,
                  borderStrokeWidth: 2.5,
                ),
              ]),

            // Lines connecting points
            if (_points.length >= 2)
              PolylineLayer(polylines: [
                Polyline(
                  points: [..._points, _points.first],
                  color: kPrimary,
                  strokeWidth: 2.0,
                ),
              ]),

            // Corner markers
            MarkerLayer(
              markers: _points.asMap().entries.map((e) => Marker(
                point: e.value,
                width: 28, height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: e.key == 0 ? kPrimary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: kPrimary, width: 2),
                    boxShadow: kShadowSm,
                  ),
                  child: Center(
                    child: Text('${e.key + 1}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: e.key == 0 ? Colors.white : kPrimary)),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),

        // ── Instruction banner ──────────────────────────────────
        Positioned(
          top: 12, left: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: kShadowSm,
            ),
            child: Row(children: [
              const Icon(Icons.touch_app_rounded, color: kPrimary, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(t.tapToAddPoints,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w600, color: kTextDark))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: kPrimaryLight, borderRadius: BorderRadius.circular(8)),
                child: Text('${_points.length} pts',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, fontWeight: FontWeight.w700, color: kPrimary)),
              ),
            ]),
          ),
        ),

        // ── Area pill ───────────────────────────────────────────
        if (hasEnough)
          Positioned(
            bottom: 90, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: kGlowGreen,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.straighten_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text('${_areaHa.toStringAsFixed(2)} ha',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ),

        // ── Save button ─────────────────────────────────────────
        Positioned(
          bottom: 24, left: 20, right: 20,
          child: SafeArea(
            child: AnimatedOpacity(
              opacity: hasEnough ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton.icon(
                onPressed: hasEnough ? _save : null,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text('${t.saveBoundary}  (${_areaHa.toStringAsFixed(2)} ha)'),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
