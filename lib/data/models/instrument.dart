/// One row of the Instrument Master (for example "Vernier Caliper").
class Instrument {
  final int id;
  final String name;
  final String shortName;

  const Instrument({
    required this.id,
    required this.name,
    required this.shortName,
  });

  factory Instrument.fromJson(Map<String, dynamic> json) {
    return Instrument(
      id: int.tryParse('${json['instrument_id']}') ?? 0,
      name: (json['instrument_name'] ?? '').toString(),
      shortName: (json['instrument_short_name'] ?? '').toString(),
    );
  }
}