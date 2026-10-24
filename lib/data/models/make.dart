/// One row of the Make Master (a make belongs to one instrument).
class Make {
  final int id;
  final int instrumentId;
  final String instrumentName;
  final String makeName;

  const Make({
    required this.id,
    required this.instrumentId,
    required this.instrumentName,
    required this.makeName,
  });

  factory Make.fromJson(Map<String, dynamic> json) {
    return Make(
      id: int.tryParse('${json['make_id']}') ?? 0,
      instrumentId: int.tryParse('${json['instrument_id']}') ?? 0,
      instrumentName: (json['instrument_name'] ?? '').toString(),
      makeName: (json['makename'] ?? '').toString(),
    );
  }
}