import '../../core/constants/api_endpoints.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../models/ticket_model.dart';

abstract class TicketRemoteDataSource {
  Future<TicketModel> lookupTicket({
    required String code,
    String? token,
  });

  Future<void> verifyTicket({
    required String code,
    required int staffId,
    String? token,
  });
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final ApiClient apiClient;

  TicketRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<TicketModel> lookupTicket({
    required String code,
    String? token,
  }) async {
    final cleanCode = Uri.encodeComponent(code.trim());
    final dynamic response = await apiClient.get(
      '${ApiEndpoints.tickets}/$cleanCode',
      token: token,
    );

    if (response is Map<String, dynamic>) {
      return TicketModel.fromJson(response);
    }

    throw ServerException(message: 'Ticket not found or unexpected response format.');
  }

  @override
  Future<void> verifyTicket({
    required String code,
    required int staffId,
    String? token,
  }) async {
    final dynamic response = await apiClient.post(
      ApiEndpoints.verifyTicket,
      token: token,
      body: {
        'code': code.trim(),
        'staff_id': staffId,
      },
    );

    if (response is Map<String, dynamic> && response['ok'] == true) {
      return;
    }

    if (response is Map<String, dynamic> && response.containsKey('message')) {
      return;
    }

    throw ServerException(message: 'Failed to verify ticket.');
  }
}
