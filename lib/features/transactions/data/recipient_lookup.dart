class TransferRecipient {
  const TransferRecipient({
    required this.uid,
    required this.fullName,
    required this.accountNumber,
    this.phoneNumber = '',
  });

  final String uid;
  final String fullName;
  final String accountNumber;
  final String phoneNumber;

  String get initials => recipientInitials(fullName);
}

String recipientInitials(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

List<String> phoneIndexCandidates(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  final result = <String>[];
  void add(String value) {
    if (!result.contains(value)) result.add(value);
  }

  if (digits.length == 11 && digits.startsWith('8')) {
    add('+7${digits.substring(1)}');
  }
  if (digits.length == 10) {
    add('+7$digits');
    add('+$digits');
  }
  if (digits.length >= 10 && digits.length <= 15) {
    add('+$digits');
  }
  return result;
}
