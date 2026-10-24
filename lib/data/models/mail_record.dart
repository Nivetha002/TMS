/// One row exactly as the backend stores it: one email under one description.
class MailRecord {
  final int id;
  final String description;
  final String mail;

  const MailRecord({
    required this.id,
    required this.description,
    required this.mail,
  });

  factory MailRecord.fromJson(Map<String, dynamic> json) {
    return MailRecord(
      id: int.tryParse('${json['id']}') ?? 0,
      description: (json['description'] ?? '').toString(),
      mail: (json['mail'] ?? '').toString(),
    );
  }
}