import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

enum CardType {
  visa,
  mastercard,
  americanExpress,
  discover,
  dinersClub,
  jcb,
  unknown,
}

class PaymentCard {
  final String id;
  final String userId;
  final String cardHolderName;
  final String maskedNumber;
  final String lastFourDigits;
  final String expiryMonth;
  final String expiryYear;
  final CardType cardType;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? stripeCardId;
  final String? fingerprint;

  PaymentCard({
    required this.id,
    required this.userId,
    required this.cardHolderName,
    required this.maskedNumber,
    required this.lastFourDigits,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cardType,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
    this.stripeCardId,
    this.fingerprint,
  });

  factory PaymentCard.fromMap(Map<String, dynamic> map) {
    return PaymentCard(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      cardHolderName: map['cardHolderName'] ?? '',
      maskedNumber: map['maskedNumber'] ?? '',
      lastFourDigits: map['lastFourDigits'] ?? '',
      expiryMonth: map['expiryMonth'] ?? '',
      expiryYear: map['expiryYear'] ?? '',
      cardType: CardType.values.firstWhere(
        (type) => type.toString().split('.').last == map['cardType'],
        orElse: () => CardType.unknown,
      ),
      isDefault: map['isDefault'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      stripeCardId: map['stripeCardId'],
      fingerprint: map['fingerprint'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'cardHolderName': cardHolderName,
      'maskedNumber': maskedNumber,
      'lastFourDigits': lastFourDigits,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cardType': cardType.toString().split('.').last,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'stripeCardId': stripeCardId,
      'fingerprint': fingerprint,
    };
  }

  factory PaymentCard.fromJson(String source) =>
      PaymentCard.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  PaymentCard copyWith({
    String? id,
    String? userId,
    String? cardHolderName,
    String? maskedNumber,
    String? lastFourDigits,
    String? expiryMonth,
    String? expiryYear,
    CardType? cardType,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? stripeCardId,
    String? fingerprint,
  }) {
    return PaymentCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      maskedNumber: maskedNumber ?? this.maskedNumber,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cardType: cardType ?? this.cardType,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stripeCardId: stripeCardId ?? this.stripeCardId,
      fingerprint: fingerprint ?? this.fingerprint,
    );
  }

  bool get isExpired {
    final now = DateTime.now();
    final expiry = DateTime(
      int.parse(expiryYear),
      int.parse(expiryMonth),
    );
    return expiry.isBefore(now);
  }

  bool get isExpiringThisMonth {
    final now = DateTime.now();
    return int.parse(expiryYear) == now.year &&
           int.parse(expiryMonth) == now.month;
  }

  bool get isExpiringSoon {
    final now = DateTime.now();
    final expiry = DateTime(
      int.parse(expiryYear),
      int.parse(expiryMonth),
    );
    final difference = expiry.difference(now).inDays;
    return difference <= 30 && difference >= 0;
  }

  String get displayName {
    return '${cardType.displayName} •••• ${lastFourDigits}';
  }

  String get expiryDisplay {
    return '${expiryMonth.padLeft(2, '0')}/${expiryYear}';
  }

  static CardType getCardTypeFromNumber(String cardNumber) {
    cardNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (cardNumber.startsWith('4')) {
      return CardType.visa;
    } else if (cardNumber.startsWith('5') ||
               cardNumber.startsWith(RegExp(r'2[2-7]'))) {
      return CardType.mastercard;
    } else if (cardNumber.startsWith('34') ||
               cardNumber.startsWith('37')) {
      return CardType.americanExpress;
    } else if (cardNumber.startsWith('6011') ||
               cardNumber.startsWith('65') ||
               cardNumber.startsWith(RegExp(r'64[4-9]'))) {
      return CardType.discover;
    } else if (cardNumber.startsWith('30') ||
               cardNumber.startsWith('36') ||
               cardNumber.startsWith('38')) {
      return CardType.dinersClub;
    } else if (cardNumber.startsWith(RegExp(r'35[2-8][8-9]'))) {
      return CardType.jcb;
    }

    return CardType.unknown;
  }

  static String maskCardNumber(String cardNumber) {
    cardNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    if (cardNumber.length < 4) return cardNumber;

    final lastFour = cardNumber.substring(cardNumber.length - 4);
    final maskedLength = cardNumber.length - 4;
    final masked = '*' * maskedLength;

    return '$masked$lastFour';
  }

  static String generateFingerprint(String cardNumber) {
    final bytes = utf8.encode(cardNumber);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

extension CardTypeExtension on CardType {
  String get displayName {
    switch (this) {
      case CardType.visa:
        return 'Visa';
      case CardType.mastercard:
        return 'Mastercard';
      case CardType.americanExpress:
        return 'American Express';
      case CardType.discover:
        return 'Discover';
      case CardType.dinersClub:
        return 'Diners Club';
      case CardType.jcb:
        return 'JCB';
      case CardType.unknown:
        return 'Unknown';
    }
  }

  String get iconAsset {
    switch (this) {
      case CardType.visa:
        return 'assets/icons/visa.svg';
      case CardType.mastercard:
        return 'assets/icons/mastercard.svg';
      case CardType.americanExpress:
        return 'assets/icons/amex.svg';
      case CardType.discover:
        return 'assets/icons/discover.svg';
      case CardType.dinersClub:
        return 'assets/icons/diners.svg';
      case CardType.jcb:
        return 'assets/icons/jcb.svg';
      case CardType.unknown:
        return 'assets/icons/credit_card.svg';
    }
  }
}

class CardValidation {
  static bool isValidCardNumber(String cardNumber) {
    cardNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (cardNumber.length < 13 || cardNumber.length > 19) {
      return false;
    }

    return _luhnCheck(cardNumber);
  }

  static bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = digit ~/ 10 + digit % 10;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  static bool isValidExpiryMonth(String month) {
    if (month.isEmpty || month.length > 2) return false;

    final monthNum = int.tryParse(month);
    return monthNum != null && monthNum >= 1 && monthNum <= 12;
  }

  static bool isValidExpiryYear(String year) {
    if (year.isEmpty) return false;

    final yearNum = int.tryParse(year);
    if (yearNum == null) return false;

    final currentYear = DateTime.now().year;
    final fullYear = year.length == 2 ? 2000 + yearNum : yearNum;

    return fullYear >= currentYear && fullYear <= currentYear + 20;
  }

  static bool isValidCVC(String cvc, CardType cardType) {
    if (cvc.isEmpty) return false;

    final expectedLength = cardType == CardType.americanExpress ? 4 : 3;
    return cvc.length == expectedLength && int.tryParse(cvc) != null;
  }

  static bool isCardExpired(String month, String year) {
    final monthNum = int.tryParse(month);
    final yearNum = int.tryParse(year);

    if (monthNum == null || yearNum == null) return true;

    final now = DateTime.now();
    final fullYear = year.length == 2 ? 2000 + yearNum : yearNum;
    final expiryDate = DateTime(fullYear, monthNum + 1, 0);

    return expiryDate.isBefore(now);
  }
}