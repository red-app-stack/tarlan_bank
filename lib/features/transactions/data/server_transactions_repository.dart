import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/services/dio_manager.dart';

import 'firestore_transactions_repository.dart';
import 'transaction_model.dart';
import 'transactions_repository.dart';

class ServerTransactionsRepository implements TransactionsRepository {
  ServerTransactionsRepository({
    required this.dioManager,
    TransactionsRepository? readRepository,
    Uuid? uuid,
  }) : _read = readRepository ?? FirestoreTransactionsRepository(),
       _uuid = uuid ?? const Uuid();

  final DioManager dioManager;
  final TransactionsRepository _read;
  final Uuid _uuid;

  @override
  Future<BankTransaction> createTransaction({
    String? fromAccountId,
    String? toAccountId,
    required double amount,
    required String currency,
    required TransactionType type,
    String? message,
  }) async {
    try {
      final response = await dioManager.post<Map<String, dynamic>>(
        '/transfers/execute',
        data: {
          'fromAccountId': fromAccountId,
          'toAccountId': toAccountId,
          'amount': amount,
          'currency': currency,
          'type': type.wireName,
          if (message != null && message.isNotEmpty) 'message': message,
          'idempotencyKey': _uuid.v4(),
        },
      );
      final data = response.data;
      if (data == null)
        throw const ServerFailure(200, 'Empty transfer response');
      return BankTransaction.fromApiMap(data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  AppFailure _mapError(DioException e) {
    final status = e.response?.statusCode;
    final code = e.response?.data is Map
        ? (e.response!.data as Map)['error'] as String?
        : null;
    if (status == null) return NetworkFailure('Transfer server unreachable', e);
    if (status == 401 || status == 403) {
      return AuthFailure('Transfer authorization failed');
    }
    if (status == 429) return const ValidationFailure('rate_limited');
    if (status == 400) {
      return ValidationFailure(code ?? 'Transfer rejected');
    }
    if (status == 404) return NotFoundFailure('Account not found');
    return ServerFailure(status, code ?? 'Transfer failed');
  }

  @override
  Future<List<BankTransaction>> fetchHistory({
    String? accountNumber,
    String? startDate,
    String? endDate,
  }) => _read.fetchHistory(
    accountNumber: accountNumber,
    startDate: startDate,
    endDate: endDate,
  );

  @override
  Future<void> cancelTransaction(String transactionId) =>
      _read.cancelTransaction(transactionId);
}
