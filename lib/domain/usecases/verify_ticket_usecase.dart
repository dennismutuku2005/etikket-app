import '../repositories/ticket_repository.dart';

class VerifyTicketUseCase {
  final TicketRepository repository;

  VerifyTicketUseCase(this.repository);

  Future<void> call({
    required String code,
    required int staffId,
    String? token,
  }) {
    return repository.verifyTicket(code: code, staffId: staffId, token: token);
  }
}
