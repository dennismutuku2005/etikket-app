import '../../domain/entities/ticket_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/ticket_remote_datasource.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource remoteDataSource;

  TicketRepositoryImpl({required this.remoteDataSource});

  @override
  Future<TicketEntity> lookupTicket({
    required String code,
    String? token,
  }) async {
    final model = await remoteDataSource.lookupTicket(code: code, token: token);
    return model.toEntity();
  }

  @override
  Future<void> verifyTicket({
    required String code,
    required int staffId,
    String? token,
  }) async {
    await remoteDataSource.verifyTicket(code: code, staffId: staffId, token: token);
  }
}
