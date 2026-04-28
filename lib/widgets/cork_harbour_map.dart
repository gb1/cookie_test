import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme.dart';
import '../util/cork_harbour.dart';

class MapMarkerSpec {
  const MapMarkerSpec({
    required this.point,
    required this.icon,
    this.color,
    this.tooltip,
    this.onTap,
  });

  final LatLng point;
  final IconData icon;
  final Color? color;
  final String? tooltip;
  final VoidCallback? onTap;
}

/// Reusable map widget. Renders OSM tiles, all known piers as small dots,
/// any caller-provided markers, and an optional pickup/drop-off polyline.
class CorkHarbourMap extends StatelessWidget {
  const CorkHarbourMap({
    super.key,
    this.center,
    this.zoom = 11.0,
    this.markers = const <MapMarkerSpec>[],
    this.routeFrom,
    this.routeTo,
    this.onTap,
    this.showPiers = true,
    this.controller,
  });

  final LatLng? center;
  final double zoom;
  final List<MapMarkerSpec> markers;
  final LatLng? routeFrom;
  final LatLng? routeTo;
  final void Function(LatLng tappedPoint)? onTap;
  final bool showPiers;
  final MapController? controller;

  @override
  Widget build(BuildContext context) {
    final pierMarkers = showPiers
        ? CorkHarbour.piers
            .map(
              (p) => Marker(
                point: p.location,
                width: 18,
                height: 18,
                child: Tooltip(
                  message: p.name,
                  child: const _PierDot(),
                ),
              ),
            )
            .toList()
        : <Marker>[];

    final extraMarkers = markers
        .map(
          (m) => Marker(
            point: m.point,
            width: 44,
            height: 44,
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTap: m.onTap,
              child: Tooltip(
                message: m.tooltip ?? '',
                child: Icon(
                  m.icon,
                  size: 36,
                  color: m.color ?? AppTheme.harbourNavy,
                ),
              ),
            ),
          ),
        )
        .toList();

    final routeLayer = (routeFrom != null && routeTo != null)
        ? PolylineLayer(
            polylines: [
              Polyline(
                points: [routeFrom!, routeTo!],
                color: AppTheme.harbourTeal,
                strokeWidth: 4,
              ),
            ],
          )
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: center ?? CorkHarbour.center,
          initialZoom: zoom,
          minZoom: 9,
          maxZoom: 17,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          onTap: onTap == null ? null : (_, point) => onTap!(point),
          cameraConstraint: CameraConstraint.contain(
            bounds: CorkHarbour.bounds,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'ie.corkharbour.boats',
            maxZoom: 19,
          ),
          if (routeLayer != null) routeLayer,
          MarkerLayer(markers: [...pierMarkers, ...extraMarkers]),
          const _AttributionLayer(),
        ],
      ),
    );
  }
}

class _PierDot extends StatelessWidget {
  const _PierDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.buoyAmber,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _AttributionLayer extends StatelessWidget {
  const _AttributionLayer();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(color: Color(0xCCFFFFFF)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              '© OpenStreetMap',
              style: TextStyle(fontSize: 10, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
