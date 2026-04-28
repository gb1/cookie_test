import 'package:intl/intl.dart';

final NumberFormat _eur =
    NumberFormat.currency(locale: 'en_IE', symbol: '€', decimalDigits: 2);

String formatEur(double value) => _eur.format(value);

String formatKm(double km) => '${km.toStringAsFixed(1)} km';

String formatDuration(Duration d) {
  final mins = d.inMinutes;
  if (mins < 1) return '<1 min';
  if (mins < 60) return '$mins min';
  final h = d.inHours;
  final m = mins - h * 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

final DateFormat _date = DateFormat('d MMM, HH:mm');
String formatDateTime(DateTime dt) => _date.format(dt.toLocal());
