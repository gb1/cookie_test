import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/pier.dart';
import '../../services/ride_service.dart';
import '../../theme.dart';
import '../../util/cork_harbour.dart';
import '../../widgets/cork_harbour_map.dart';
import '../../widgets/fare_card.dart';
import '../../widgets/pier_picker.dart';
import 'ride_status_screen.dart';

class RequestRideScreen extends StatefulWidget {
  const RequestRideScreen({
    super.key,
    required this.passenger,
    required this.defaultPickup,
  });

  final AppUser passenger;
  final Pier defaultPickup;

  @override
  State<RequestRideScreen> createState() => _RequestRideScreenState();
}

class _RequestRideScreenState extends State<RequestRideScreen> {
  late LatLng _pickup = widget.defaultPickup.location;
  late String _pickupLabel = widget.defaultPickup.name;

  LatLng? _dropoff;
  String? _dropoffLabel;

  /// Which point the next map tap will set.
  _Edit _editing = _Edit.dropoff;

  bool _busy = false;

  Future<void> _pickPickup() async {
    final pier = await PierPicker.show(context, title: 'Choose pickup');
    if (pier != null) {
      setState(() {
        _pickup = pier.location;
        _pickupLabel = pier.name;
      });
    }
  }

  Future<void> _pickDropoff() async {
    final pier = await PierPicker.show(context, title: 'Choose drop-off');
    if (pier != null) {
      setState(() {
        _dropoff = pier.location;
        _dropoffLabel = pier.name;
      });
    }
  }

  void _onMapTap(LatLng tapped) {
    if (!CorkHarbour.contains(tapped)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap inside Cork Harbour to set the location.'),
        ),
      );
      return;
    }
    setState(() {
      if (_editing == _Edit.pickup) {
        _pickup = tapped;
        _pickupLabel = 'Pin (${tapped.latitude.toStringAsFixed(3)}, '
            '${tapped.longitude.toStringAsFixed(3)})';
      } else {
        _dropoff = tapped;
        _dropoffLabel = 'Pin (${tapped.latitude.toStringAsFixed(3)}, '
            '${tapped.longitude.toStringAsFixed(3)})';
      }
    });
  }

  Future<void> _submit() async {
    if (_dropoff == null) return;
    setState(() => _busy = true);
    try {
      final ride = await context.read<RideService>().requestRide(
            passenger: widget.passenger,
            pickup: _pickup,
            pickupLabel: _pickupLabel,
            dropoff: _dropoff!,
            dropoffLabel: _dropoffLabel!,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RideStatusScreen(rideId: ride.id),
        ),
      );
    } on RideException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDropoff = _dropoff != null;
    final km = hasDropoff ? CorkHarbour.distanceKm(_pickup, _dropoff!) : 0.0;
    final eta = hasDropoff
        ? CorkHarbour.estimatedDuration(_pickup, _dropoff!)
        : Duration.zero;
    final fare =
        hasDropoff ? CorkHarbour.estimateFare(_pickup, _dropoff!) : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Plan your trip')),
      body: Column(
        children: [
          Expanded(
            child: CorkHarbourMap(
              center: _pickup,
              onTap: _onMapTap,
              routeFrom: hasDropoff ? _pickup : null,
              routeTo: _dropoff,
              markers: [
                MapMarkerSpec(
                  point: _pickup,
                  icon: Icons.flag,
                  color: AppTheme.harbourNavy,
                  tooltip: 'Pickup',
                ),
                if (hasDropoff)
                  MapMarkerSpec(
                    point: _dropoff!,
                    icon: Icons.location_on,
                    color: AppTheme.buoyAmber,
                    tooltip: 'Drop-off',
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LocationRow(
                  icon: Icons.flag,
                  label: 'Pickup',
                  value: _pickupLabel,
                  active: _editing == _Edit.pickup,
                  onTap: () => setState(() => _editing = _Edit.pickup),
                  onChange: _pickPickup,
                ),
                const SizedBox(height: 8),
                _LocationRow(
                  icon: Icons.location_on,
                  label: 'Drop-off',
                  value: _dropoffLabel ?? 'Tap a pier or the map',
                  active: _editing == _Edit.dropoff,
                  onTap: () => setState(() => _editing = _Edit.dropoff),
                  onChange: _pickDropoff,
                ),
                const SizedBox(height: 12),
                if (hasDropoff)
                  FareCard(
                    distanceKm: km,
                    duration: eta,
                    fareEur: fare,
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: hasDropoff && !_busy ? _submit : null,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Request boat'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Edit { pickup, dropoff }

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
    required this.onChange,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppTheme.harbourTeal : Colors.black12,
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.harbourTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.labelSmall),
                  Text(value, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            TextButton(onPressed: onChange, child: const Text('Change')),
          ],
        ),
      ),
    );
  }
}
