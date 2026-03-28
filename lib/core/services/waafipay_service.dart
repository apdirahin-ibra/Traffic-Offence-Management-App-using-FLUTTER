class WaafiPayRequest {
  final String wallet;
  final String phoneNumber;
  final String reference;
  final double amount;
  final String pin;

  const WaafiPayRequest({
    required this.wallet,
    required this.phoneNumber,
    required this.reference,
    required this.amount,
    required this.pin,
  });
}

class WaafiPayResult {
  final String transactionId;
  final String providerLabel;
  final String maskedPhone;

  const WaafiPayResult({
    required this.transactionId,
    required this.providerLabel,
    required this.maskedPhone,
  });
}

class WaafiPayService {
  static const supportedWallets = ['evc_plus', 'sahal', 'zaad'];

  String providerLabel(String wallet) {
    switch (wallet) {
      case 'evc_plus':
        return 'EVC Plus';
      case 'sahal':
        return 'Sahal';
      case 'zaad':
        return 'Zaad';
      default:
        return 'WaafiPay';
    }
  }

  String normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('252') && digits.length == 12) return digits;
    if (digits.startsWith('0') && digits.length == 10) return '252${digits.substring(1)}';
    if (digits.length == 9) return '252$digits';
    throw 'Enter a valid Somali mobile number.';
  }

  String maskPhone(String normalizedPhone) {
    if (normalizedPhone.length < 4) return normalizedPhone;
    final tail = normalizedPhone.substring(normalizedPhone.length - 4);
    return '****$tail';
  }

  Future<WaafiPayResult> processPayment(WaafiPayRequest request) async {
    if (!supportedWallets.contains(request.wallet)) {
      throw 'Unsupported wallet provider.';
    }
    if (request.amount <= 0) {
      throw 'Payment amount must be greater than zero.';
    }
    if (request.pin.length != 4 || int.tryParse(request.pin) == null) {
      throw 'PIN must be exactly 4 digits.';
    }

    final normalizedPhone = normalizePhone(request.phoneNumber);

    await Future.delayed(const Duration(seconds: 2));

    final txSeed = DateTime.now().millisecondsSinceEpoch.toString();
    return WaafiPayResult(
      transactionId: 'WAF-${txSeed.substring(txSeed.length - 8)}',
      providerLabel: providerLabel(request.wallet),
      maskedPhone: maskPhone(normalizedPhone),
    );
  }
}
