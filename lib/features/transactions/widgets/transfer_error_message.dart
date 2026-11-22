import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/generated/app_localizations.dart';

String transferErrorMessage(AppFailure failure, AppLocalizations l) {
  return switch (failure) {
    NetworkFailure() => l.transferNetworkError,
    AuthFailure() => l.transferAuthError,
    ServerFailure() => l.transferServerError,
    NotFoundFailure() => l.recipientNotFound,
    ValidationFailure() => switch (failure.message) {
      'insufficient_funds' => l.transferInsufficientFunds,
      'rate_unavailable' => l.transferRateUnavailable,
      'account_inactive' => l.transferAccountInactive,
      'overpayment' => l.transferOverpayment,
      'rate_limited' => l.transferTooManyRequests,
      'invalid_amount' => l.errorEnterAmount,
      _ => l.transferValidationError,
    },
    _ => l.transferFailed,
  };
}
