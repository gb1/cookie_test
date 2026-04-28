# Cork Harbour Boats

A Flutter app modelled on Uber, but for booking small-boat trips between
piers in Cork Harbour. Users can sign in as either a **passenger** (book a
boat) or a **driver** (accept requests with their vessel).

## Features

- Email/password sign-up + sign-in (mock, in-memory + persisted).
- Role selection on first sign-up; switchable later from Profile.
- Nautical map of Cork Harbour rendered with `flutter_map` over
  OpenStreetMap tiles - no API key required.
- Passenger flow: choose pickup & drop-off (from pier list or by tapping
  the map), see distance / ETA / fare estimate, request a boat, watch the
  status update in real time, chat with the driver, cancel.
- Driver flow: go online/offline, see incoming requests, accept, walk
  through `en-route -> arrived -> in-trip -> completed`.
- Ride history per user.
- Simple in-app chat between matched passenger and driver.
- A shared in-memory `RideService` lets two browser tabs (or two devices
  on the same backend) play passenger and driver simultaneously.

## Run

Requires Flutter (stable, >= 3.22).

```bash
flutter pub get
flutter run -d chrome        # easiest - works without device emulators
# or
flutter run -d <device-id>
```

For a two-tab demo on web, sign up as a driver in one tab and a
passenger in another (use different incognito windows so
`shared_preferences` doesn't collide).

## Tests

```bash
flutter analyze
flutter test
```
