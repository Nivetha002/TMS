/// Dashboard numbers. Counted from the rows in `data`, exactly like the
/// React Dashboard does (see "computedCounts" in Dashboard.jsx).
class DashboardSummary {
  final int planned; // status PLAN or LIVE
  final int calibrated; // status CALIBRATION
  final int scrap; // status SCRAP
  final int removed; // status REPLACE (web calls it "Removed")
  final int totalInstruments; // unique instrument_code

  const DashboardSummary({
    required this.planned,
    required this.calibrated,
    required this.scrap,
    required this.removed,
    required this.totalInstruments,
  });

  /// All scheduled calibration work = still planned + already calibrated.
  int get workTotal => planned + calibrated;

  /// 0.0 to 1.0, used by the progress bar.
  double get progress => workTotal == 0 ? 0.0 : calibrated / workTotal;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    var planned = 0;
    var calibrated = 0;
    var scrap = 0;
    var removed = 0;
    final instrumentCodes = <String>{}; // a Set keeps each code only once

    final rows = json['data'];
    if (rows is List) {
      for (final row in rows) {
        if (row is! Map) continue;

        final code = row['instrument_code']?.toString() ?? '';
        if (code.isNotEmpty) instrumentCodes.add(code);

        final entries = row['entries'];
        if (entries is! List) continue;

        for (final entry in entries) {
          if (entry is! Map) continue;

          final status = (entry['status'] ?? '').toString().toUpperCase();
          if (status == 'PLAN' || status == 'LIVE') {
            planned++;
          } else if (status == 'CALIBRATION') {
            calibrated++;
          } else if (status == 'SCRAP') {
            scrap++;
          } else if (status == 'REPLACE') {
            removed++;
          }
          // any other status (like "INSTRUMENT") is ignored
        }
      }
    }

    return DashboardSummary(
      planned: planned,
      calibrated: calibrated,
      scrap: scrap,
      removed: removed,
      totalInstruments: instrumentCodes.length,
    );
  }
}