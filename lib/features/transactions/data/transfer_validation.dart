import 'package:tarlan_bank/core/errors/app_failure.dart';
import 'package:tarlan_bank/features/accounts/data/account_model.dart';

import 'transaction_model.dart';

/// Result of validating a transfer: the exact new balances to write.
/// Null side = party absent (deposit has no sender, withdrawal no recipient).
class TransferPlan {
  const TransferPlan({this.fromBalance, this.toBalance});

  final double? fromBalance;
  final double? toBalance;
}

/// Money rounding: 2 decimal places, applied to every balance write so
/// floating-point drift never accumulates in the ledger.
double roundMoney(double value) => (value * 100).roundToDouble() / 100;

/// THE validation seam (MIGRATION_PLAN.md §4). Pure — no Firestore, no auth —
/// so the whole money-logic surface is unit-testable and can be lifted verbatim
/// into a trusted callable later. Throws a sealed [AppFailure]; never returns
/// a partial plan.
///
/// Demo scope: same-currency movements only. `currency_conversion` needs the
/// exchange-rate seam (amount in two currencies) and is rejected here until
/// that interface lands.
TransferPlan planTransfer({
  required TransactionType type,
  required double amount,
  required String currency,
  Account? from,
  Account? to,
}) {
  if (!amount.isFinite || amount <= 0) {
    throw const ValidationFailure('Amount must be greater than zero');
  }
  final rounded = roundMoney(amount);
  if (rounded <= 0) {
    throw const ValidationFailure('Amount is below the minimum (0.01)');
  }
  if (!const ['USD', 'EUR', 'KZT'].contains(currency)) {
    throw ValidationFailure('Unsupported currency: $currency');
  }
  if (type == TransactionType.currencyConversion) {
    throw const ValidationFailure(
      'Currency conversion is not available yet (exchange seam pending)',
    );
  }

  // Party shape per type — mirrors the rules' validParties().
  switch (type) {
    case TransactionType.deposit:
      if (from != null || to == null) {
        throw const ValidationFailure('Deposit requires a recipient only');
      }
    case TransactionType.withdrawal:
      if (from == null || to != null) {
        throw const ValidationFailure('Withdrawal requires a sender only');
      }
    default:
      if (from == null || to == null) {
        throw const ValidationFailure('Transfer requires both accounts');
      }
  }
  if (from != null && to != null && from.number == to.number) {
    throw const ValidationFailure('Cannot transfer to the same account');
  }
  if (type == TransactionType.internalTransfer &&
      from!.ownerId != to!.ownerId) {
    throw const ValidationFailure(
      'Internal transfers must stay within one owner',
    );
  }

  double? newFrom;
  if (from != null) {
    if (from.status != AccountStatus.active) {
      throw const ValidationFailure('Sender account is not active');
    }
    if (!from.isSpendable) {
      // Credit balance is debt — drawing a loan is a disbursement, not a
      // transfer (D8). Deposit sources are allowed by the model; the UI
      // restricts sources to debit accounts.
      throw const ValidationFailure(
        'Credit accounts cannot be a transfer source',
      );
    }
    if (from.currency != currency) {
      throw const ValidationFailure('Currency does not match sender account');
    }
    if (from.balance < rounded) {
      throw const ValidationFailure('Insufficient balance');
    }
    newFrom = roundMoney(from.balance - rounded);
  }

  double? newTo;
  if (to != null) {
    if (to.status != AccountStatus.active) {
      throw const ValidationFailure('Recipient account is not active');
    }
    if (to.currency != currency) {
      throw const ValidationFailure(
        'Currency does not match recipient account',
      );
    }
    if (to.type == AccountType.credit) {
      // debit -> credit is a REPAYMENT: it decreases the outstanding debt.
      // Overpaying would push balance (debt) below zero — rules forbid it.
      if (rounded > to.balance) {
        throw const ValidationFailure('Repayment exceeds the outstanding debt');
      }
      newTo = roundMoney(to.balance - rounded);
    } else {
      newTo = roundMoney(to.balance + rounded);
    }
  }

  return TransferPlan(fromBalance: newFrom, toBalance: newTo);
}
