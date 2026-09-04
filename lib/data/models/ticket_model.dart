import '../../domain/entities/ticket_entity.dart';

class TicketModel extends TicketEntity {
  const TicketModel({
    required super.id,
    required super.code,
    required super.attendeeName,
    required super.eventName,
    required super.ticketType,
    required super.status,
    super.scannedBy,
    super.scannedAt,
    super.venue,
    super.eventDate,
    super.eventTime,
    super.coverImageUrl,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      code: (json['ticket_code'] ?? json['code'] ?? '').toString(),
      attendeeName: (json['attendee_name'] ?? json['attendeeName'] ?? json['buyer_name'] ?? 'Guest').toString(),
      eventName: (json['event_title'] ?? json['eventName'] ?? json['title'] ?? 'Event').toString(),
      ticketType: (json['ticket_type'] ?? json['ticketType'] ?? 'General').toString(),
      status: (json['status'] ?? 'Pending').toString(),
      scannedBy: json['scanned_by']?.toString() ?? json['scannedBy']?.toString(),
      scannedAt: json['scanned_at']?.toString() ?? json['scannedAt']?.toString(),
      venue: json['event_venue']?.toString() ?? json['venue']?.toString(),
      eventDate: json['event_date']?.toString() ?? json['eventDate']?.toString(),
      eventTime: json['event_time']?.toString() ?? json['eventTime']?.toString(),
      coverImageUrl: json['cover_image_url']?.toString() ?? json['coverImageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_code': code,
      'attendee_name': attendeeName,
      'event_title': eventName,
      'ticket_type': ticketType,
      'status': status,
      'scanned_by': scannedBy,
      'scanned_at': scannedAt,
      'event_venue': venue,
      'event_date': eventDate,
      'event_time': eventTime,
      'cover_image_url': coverImageUrl,
    };
  }

  TicketEntity toEntity() {
    return TicketEntity(
      id: id,
      code: code,
      attendeeName: attendeeName,
      eventName: eventName,
      ticketType: ticketType,
      status: status,
      scannedBy: scannedBy,
      scannedAt: scannedAt,
      venue: venue,
      eventDate: eventDate,
      eventTime: eventTime,
      coverImageUrl: coverImageUrl,
    );
  }

  factory TicketModel.fromEntity(TicketEntity entity) {
    return TicketModel(
      id: entity.id,
      code: entity.code,
      attendeeName: entity.attendeeName,
      eventName: entity.eventName,
      ticketType: entity.ticketType,
      status: entity.status,
      scannedBy: entity.scannedBy,
      scannedAt: entity.scannedAt,
      venue: entity.venue,
      eventDate: entity.eventDate,
      eventTime: entity.eventTime,
      coverImageUrl: entity.coverImageUrl,
    );
  }
}
