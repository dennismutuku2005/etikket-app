import '../entities/ticket_entity.dart';
import '../repositories/ticket_repository.dart';

class LookupTicketUseCase {
  final TicketRepository repository;

  LookupTicketUseCase(this.repository);

  Future<TicketEntity> call({
    required String code,
    String? token,
  }) {
    return repository.lookupTicket(code: code, token: token);
  }
}
