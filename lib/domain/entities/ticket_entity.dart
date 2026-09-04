class TicketEntity {
  final int id;
  final String code;
  final String attendeeName;
  final String eventName;
  final String ticketType;
  final String status; // 'checked_in' or 'unused' / 'pending'
  final String? scannedBy;
  final String? scannedAt;
  final String? venue;
  final String? eventDate;
  final String? eventTime;
  final String? coverImageUrl;

  const TicketEntity({
    required this.id,
    required this.code,
    required this.attendeeName,
    required this.eventName,
    required this.ticketType,
    required this.status,
    this.scannedBy,
    this.scannedAt,
    this.venue,
    this.eventDate,
    this.eventTime,
    this.coverImageUrl,
  });

  bool get isCheckedIn => status.toLowerCase() == 'checked_in' || status.toLowerCase() == 'verified' || status.toLowerCase() == 'used';

  TicketEntity copyWith({
    int? id,
    String? code,
    String? attendeeName,
    String? eventName,
    String? ticketType,
    String? status,
    String? scannedBy,
    String? scannedAt,
    String? venue,
    String? eventDate,
    String? eventTime,
    String? coverImageUrl,
  }) {
    return TicketEntity(
      id: id ?? this.id,
      code: code ?? this.code,
      attendeeName: attendeeName ?? this.attendeeName,
      eventName: eventName ?? this.eventName,
      ticketType: ticketType ?? this.ticketType,
      status: status ?? this.status,
      scannedBy: scannedBy ?? this.scannedBy,
      scannedAt: scannedAt ?? this.scannedAt,
      venue: venue ?? this.venue,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }
}
