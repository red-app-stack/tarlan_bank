import 'package:dio/dio.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/services/dio_manager.dart';

import 'recipient_lookup.dart';

class ServerRecipientRepository {
  const ServerRecipientRepository({required this.dioManager});

  final DioManager dioManager;

  Future<TransferRecipient?> lookupRecipient({
    String? phoneNumber,
    String? accountNumber,
  }) async {
    try {
      final response = await dioManager.post<Map<String, dynamic>>(
        '/recipients/lookup',
        data: {
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          if (accountNumber != null) 'accountNumber': accountNumber,
        },
      );
      final data = response.data;
      if (data == null || data.isEmpty) return null;
      return TransferRecipient(
        uid: data['uid'] as String? ?? '',
        fullName: data['fullName'] as String? ?? '',
        accountNumber: data['accountNumber'] as String? ?? '',
        phoneNumber: data['phoneNumber'] as String? ?? '',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == null)
        throw NetworkFailure('Recipient lookup unavailable', e);
      if (status == 401 || status == 403) {
        throw AuthFailure('Recipient lookup authorization failed');
      }
      if (status == 429) throw const ValidationFailure('rate_limited');
      if (status == 400)
        throw const ValidationFailure('Invalid lookup request');
      throw ServerFailure(status, 'Recipient lookup failed');
    }
  }
}
