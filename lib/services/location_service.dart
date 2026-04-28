import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../util/cork_harbour.dart';

/// We don't use `geolocator` for this demo - the harbour is small enough
/// that "your location" can default to Cobh and be overridden by tapping
/// the map or picking a pier. Keeping a service here makes it easy to swap
/// in a real GPS source later.
class LocationService extends ChangeNotifier {
  LatLng _current = CorkHarbour.center;

  LatLng get current => _current;

  void setCurrent(LatLng point) {
    _current = point;
    notifyListeners();
  }
}
