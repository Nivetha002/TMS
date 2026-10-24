import 'mail_record.dart';

/// The 6 fixed mail groups. Must match the DB values exactly
/// (same list the React Mail page uses).
const mailDescriptions = [
  '15 Days Once To',
  '15 Days Once CC',
  'Last 5 Days To',
  'Last 5 Days CC',
  'NABL Reminder To',
  'NABL Reminder CC',
];

/// One email row inside the edit form.
///   id == null -> a new email, not saved yet
///   id != null -> an email that already exists on the server
class MailEntry {
  final int? id;
  final String mail;

  const MailEntry({this.id, required this.mail});
}

/// One group (description) with all its emails.
class MailBucket {
  final String description;
  final List<MailRecord> records;

  const MailBucket({required this.description, required this.records});

  List<String> get mails => records.map((r) => r.mail).toList();

  /// Turns the flat list from the server into the 6 groups.
  static List<MailBucket> fromRecords(List<MailRecord> all) {
    return mailDescriptions.map((description) {
      final matching = all
          .where((r) =>
              r.description.trim().toLowerCase() == description.toLowerCase())
          .toList();
      return MailBucket(description: description, records: matching);
    }).toList();
  }
}