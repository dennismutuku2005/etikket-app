import '../entities/ticket_entity.dart';

abstract class TicketRepository {
  Future<TicketEntity> lookupTicket({
    required String code,
    String? token,
  });

  Future<void> verifyTicket({
    required String code,
    required int staffId,
    String? token,
  });
}
