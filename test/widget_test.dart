import 'package:flutter_test/flutter_test.dart';
import 'package:etikket/core/utils/qr_code_parser.dart';
import 'package:etikket/data/models/ticket_model.dart';
import 'package:etikket/data/models/user_model.dart';

void main() {
  group('QrCodeParser Tests', () {
    test('extracts raw string code correctly', () {
      expect(QrCodeParser.extractTicketCode('TKT-1042'), 'TKT-1042');
    });

    test('extracts code from JSON payload format with codes array', () {
      const json = '{"codes":["TKT-1042","TKT-1043"]}';
      expect(QrCodeParser.extractTicketCode(json), 'TKT-1042');
    });

    test('extracts code from JSON payload format with single code key', () {
      const json = '{"code":"TKT-9999"}';
      expect(QrCodeParser.extractTicketCode(json), 'TKT-9999');
    });

    test('extracts code from URL path', () {
      const url = 'https://etikket.co.ke/tickets/TKT-5555';
      expect(QrCodeParser.extractTicketCode(url), 'TKT-5555');
    });

    test('returns null for null or empty input', () {
      expect(QrCodeParser.extractTicketCode(null), isNull);
      expect(QrCodeParser.extractTicketCode('   '), isNull);
    });
  });

  group('Data Model Tests', () {
    test('UserModel parses from JSON correctly', () {
      final json = {
        'user': {
          'id': 5,
          'name': 'Daniel Gate Admin',
          'email': 'gate@etikket.co.ke',
          'phone': '0712345678',
          'role': 'gate_staff',
        },
        'token': 'jwt_test_token_123'
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 5);
      expect(user.name, 'Daniel Gate Admin');
      expect(user.email, 'gate@etikket.co.ke');
      expect(user.role, 'gate_staff');
      expect(user.token, 'jwt_test_token_123');
      expect(user.isGateStaff, isTrue);
    });

    test('TicketModel parses from JSON correctly', () {
      final json = {
        'id': 101,
        'ticket_code': 'TKT-1042',
        'attendee_name': 'Grace W.',
        'event_title': 'Urban Fest Nairobi',
        'ticket_type': 'VIP',
        'status': 'checked_in',
        'scanned_by': '1',
        'scanned_at': '2026-09-04 14:30:00',
      };

      final ticket = TicketModel.fromJson(json);
      expect(ticket.id, 101);
      expect(ticket.code, 'TKT-1042');
      expect(ticket.attendeeName, 'Grace W.');
      expect(ticket.eventName, 'Urban Fest Nairobi');
      expect(ticket.ticketType, 'VIP');
      expect(ticket.isCheckedIn, isTrue);
    });
  });
}
