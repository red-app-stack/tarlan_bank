import 'package:tarlan_bank/core/errors/app_failure.dart';

class ServiceUrls {
  const ServiceUrls({
    required this.bankApiUrl,
    required this.aiApiUrl,
    required this.updatedAt,
  });

  final String bankApiUrl;
  final String aiApiUrl;
  final DateTime updatedAt;

  factory ServiceUrls.fromMap(Map<String, dynamic> map) {
    final bank = map['bankApiUrl'];
    if (bank is! String || !bank.startsWith('https://')) {
      throw const ValidationFailure('Invalid bankApiUrl in config/urls');
    }
    final updated = map['updatedAt'];
    return ServiceUrls(
      bankApiUrl: bank.replaceAll(RegExp(r'/$'), ''),
      aiApiUrl: map['aiApiUrl'] is String ? map['aiApiUrl'] as String : '',
      updatedAt: updated is DateTime
          ? updated.toUtc()
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  Map<String, dynamic> toJson() => {
    'bankApiUrl': bankApiUrl,
    'aiApiUrl': aiApiUrl,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
