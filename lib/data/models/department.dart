/// One row of the Department Master.
class Department {
  final int id;
  final String name;
  final String shortName;

  const Department({
    required this.id,
    required this.name,
    required this.shortName,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: int.tryParse('${json['department_id']}') ?? 0,
      name: (json['department_name'] ?? '').toString(),
      shortName: (json['department_short_name'] ?? '').toString(),
    );
  }
}