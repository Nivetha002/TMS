/// One row of the Machine Master.
class Machine {
  final int id;
  final String name;
  final String shortName;

  const Machine({
    required this.id,
    required this.name,
    required this.shortName,
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: int.tryParse('${json['machine_id']}') ?? 0,
      name: (json['machine_name'] ?? '').toString(),
      shortName: (json['machine_short_name'] ?? '').toString(),
    );
  }
}