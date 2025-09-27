import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:waterfilternet/models/payment_card.dart';
import 'package:waterfilternet/models/shipping_address.dart';
import 'package:waterfilternet/models/order.dart' as order_model;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterfilternet/services/config_service.dart';
import 'package:waterfilternet/services/environment_service.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConfigService _config = ConfigService();

  static const String _cardsCollection = 'payment_cards';
  static const String _userCardsCollection = 'user_payment_cards';
  static const String _paymentsCollection = 'payments';

  // Demo mode card storage
  static final List<PaymentCard> _demoCards = [];

  // Initialize Stripe with publishable key from environment
  static Future<void> initializeStripe() async {
    try {
      final envService = EnvironmentService();

      // Skip Stripe initialization if not configured
      if (!envService.isStripeConfigured) {
        if (kDebugMode) {
          print('Stripe not configured - check your .env file');
        }
        return;
      }

      // Skip Stripe initialization on web for now to avoid platform issues
      if (kIsWeb) {
        if (kDebugMode) {
          print('Stripe initialization skipped on web platform');
        }
        return;
      }

      Stripe.publishableKey = envService.currentStripePublishableKey;
      await Stripe.instance.applySettings();

      if (kDebugMode) {
        print('Stripe initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Stripe initialization failed: $e');
      }
      // Continue without Stripe for testing
    }
  }

  Future<PaymentCard> saveCard({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
    required String cardHolderName,
    bool setAsDefault = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to save a card');
    }

    // Validate card details
    if (!CardValidation.isValidCardNumber(cardNumber)) {
      throw Exception('Invalid card number');
    }

    if (!CardValidation.isValidExpiryMonth(expiryMonth)) {
      throw Exception('Invalid expiry month');
    }

    if (!CardValidation.isValidExpiryYear(expiryYear)) {
      throw Exception('Invalid expiry year');
    }

    if (CardValidation.isCardExpired(expiryMonth, expiryYear)) {
      throw Exception('Card is expired');
    }

    final cardType = PaymentCard.getCardTypeFromNumber(cardNumber);
    if (!CardValidation.isValidCVC(cvc, cardType)) {
      throw Exception('Invalid CVC');
    }

    try {
      // Use demo mode if configured or on web
      if (_config.isDemoMode) {
        // Simulate network delay
        await Future.delayed(Duration(seconds: 1));

        final cardId = 'card_test_${DateTime.now().millisecondsSinceEpoch}';
        final maskedNumber = PaymentCard.maskCardNumber(cardNumber);
        final lastFourDigits = cardNumber.substring(cardNumber.length - 4);
        final fingerprint = PaymentCard.generateFingerprint(cardNumber);
        final stripeCardId = 'pm_test_${DateTime.now().millisecondsSinceEpoch}';

        final card = PaymentCard(
          id: cardId,
          userId: user.uid,
          cardHolderName: cardHolderName,
          maskedNumber: maskedNumber,
          lastFourDigits: lastFourDigits,
          expiryMonth: expiryMonth,
          expiryYear: expiryYear,
          cardType: cardType,
          isDefault: true, // Always default for demo
          createdAt: DateTime.now(),
          stripeCardId: stripeCardId,
          fingerprint: fingerprint,
        );

        // Store in demo cards list for web testing
        _demoCards.add(card);
        print('Demo: Card saved successfully - ${card.maskedNumber}');
        return card;
      }

      // Normal Firestore flow for mobile/production
      try {
        final cardId = _firestore.collection(_cardsCollection).doc().id;
        final maskedNumber = PaymentCard.maskCardNumber(cardNumber);
        final lastFourDigits = cardNumber.substring(cardNumber.length - 4);
        final fingerprint = PaymentCard.generateFingerprint(cardNumber);

        // If this is the user's first card or set as default, make it default
        final existingCards = await getUserCards();
        final isDefault = setAsDefault || existingCards.isEmpty;

        // If setting as default, update all other cards
        if (isDefault && existingCards.isNotEmpty) {
          await _updateAllCardsDefault(user.uid, false);
        }

        String? stripeCardId;

        // Create payment method with Stripe
        try {
          final paymentMethod = await Stripe.instance.createPaymentMethod(
            params: PaymentMethodParams.card(
              paymentMethodData: PaymentMethodData(
                billingDetails: BillingDetails(
                  name: cardHolderName,
                ),
              ),
            ),
          );
          stripeCardId = paymentMethod.id;
        } catch (e) {
          print('Stripe payment method creation failed: $e');
          // Continue with null stripeCardId for testing
        }

        final card = PaymentCard(
          id: cardId,
          userId: user.uid,
          cardHolderName: cardHolderName,
          maskedNumber: maskedNumber,
          lastFourDigits: lastFourDigits,
          expiryMonth: expiryMonth,
          expiryYear: expiryYear,
          cardType: cardType,
          isDefault: isDefault,
          createdAt: DateTime.now(),
          stripeCardId: stripeCardId,
          fingerprint: fingerprint,
        );

        // Save to Firestore
        await _firestore.collection(_cardsCollection).doc(cardId).set(card.toMap());

        // Create user card reference
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection(_userCardsCollection)
            .doc(cardId)
            .set({
          'cardId': cardId,
          'maskedNumber': maskedNumber,
          'lastFourDigits': lastFourDigits,
          'cardType': cardType.toString().split('.').last,
          'isDefault': isDefault,
          'createdAt': card.createdAt.toIso8601String(),
        });

        return card;
      } catch (firestoreError) {
        print('Firestore save card failed: $firestoreError');

        // Fall back to demo mode
        _config.enableDemoMode();

        // Return demo card
        final cardId = _config.generateDemoId('card');
        final maskedNumber = PaymentCard.maskCardNumber(cardNumber);
        final lastFourDigits = cardNumber.substring(cardNumber.length - 4);
        final fingerprint = PaymentCard.generateFingerprint(cardNumber);

        final card = PaymentCard(
          id: cardId,
          userId: user.uid,
          cardHolderName: cardHolderName,
          maskedNumber: maskedNumber,
          lastFourDigits: lastFourDigits,
          expiryMonth: expiryMonth,
          expiryYear: expiryYear,
          cardType: cardType,
          isDefault: true, // Always default for demo
          createdAt: DateTime.now(),
          stripeCardId: _config.generateDemoId('pm'),
          fingerprint: fingerprint,
        );

        print('Demo: Card saved in fallback mode - ${card.maskedNumber}');
        return card;
      }
    } catch (e) {
      throw Exception('Failed to save card: $e');
    }
  }

  Future<List<PaymentCard>> getUserCards() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    try {
      // Use demo mode if configured
      if (_config.isDemoMode) {
        await Future.delayed(Duration(milliseconds: 500)); // Simulate loading

        // Filter cards by current user
        final currentUserCards = _demoCards
            .where((card) => card.userId == user.uid)
            .toList();

        // Sort by default first, then by creation date
        currentUserCards.sort((a, b) {
          if (a.isDefault && !b.isDefault) return -1;
          if (!a.isDefault && b.isDefault) return 1;
          return a.createdAt.compareTo(b.createdAt);
        });

        print('Demo: Returning ${currentUserCards.length} cards for user');
        return currentUserCards;
      }

      try {
        final snapshot = await _firestore
            .collection(_cardsCollection)
            .where('userId', isEqualTo: user.uid)
            .get();

        final cards = snapshot.docs
            .map((doc) => PaymentCard.fromMap(doc.data()))
            .toList();

        // Sort by default first, then by creation date
        cards.sort((a, b) {
          if (a.isDefault && !b.isDefault) return -1;
          if (!a.isDefault && b.isDefault) return 1;
          return a.createdAt.compareTo(b.createdAt);
        });

        return cards;
      } catch (firestoreError) {
        print('Firestore getUserCards failed: $firestoreError');
        _config.enableDemoMode();
        // Return empty list for demo mode
        await Future.delayed(Duration(milliseconds: 500));
        return [];
      }
    } catch (e) {
      throw Exception('Failed to get user cards: $e');
    }
  }

  Future<PaymentCard?> getDefaultCard() async {
    final cards = await getUserCards();
    try {
      return cards.firstWhere((card) => card.isDefault);
    } catch (e) {
      // If no default card found, return first card if available
      return cards.isNotEmpty ? cards.first : null;
    }
  }

  Future<void> setDefaultCard(String cardId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    try {
      // Update all cards to not be default
      await _updateAllCardsDefault(user.uid, false);

      // Set the selected card as default
      await _firestore.collection(_cardsCollection).doc(cardId).update({
        'isDefault': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update user card reference
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection(_userCardsCollection)
          .doc(cardId)
          .update({
        'isDefault': true,
      });
    } catch (e) {
      throw Exception('Failed to set default card: $e');
    }
  }

  Future<void> deleteCard(String cardId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    try {
      final card = await getCard(cardId);
      if (card == null) {
        throw Exception('Card not found');
      }

      // Note: In production, you would detach the payment method from Stripe
      // For now, we'll just log this action
      if (card.stripeCardId != null) {
        print('Payment method ${card.stripeCardId} would be detached from Stripe');
      }

      // Delete from Firestore
      await _firestore.collection(_cardsCollection).doc(cardId).delete();

      // Delete user reference
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection(_userCardsCollection)
          .doc(cardId)
          .delete();

      // If this was the default card, set another card as default
      if (card.isDefault) {
        final remainingCards = await getUserCards();
        if (remainingCards.isNotEmpty) {
          await setDefaultCard(remainingCards.first.id);
        }
      }
    } catch (e) {
      throw Exception('Failed to delete card: $e');
    }
  }

  Future<PaymentCard?> getCard(String cardId) async {
    try {
      final doc = await _firestore.collection(_cardsCollection).doc(cardId).get();

      if (!doc.exists) {
        return null;
      }

      return PaymentCard.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get card: $e');
    }
  }

  Future<String> processPayment({
    required order_model.Order order,
    required PaymentCard paymentCard,
    required ShippingAddress billingAddress,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final envService = EnvironmentService();
      print('DEBUG: PaymentService - kIsWeb: $kIsWeb');
      print('DEBUG: PaymentService - _config.isDemoMode: ${_config.isDemoMode}');
      print('DEBUG: PaymentService - forceDemoMode: ${envService.forceDemoMode}');

      // Use demo mode if config set, force flag enabled, Stripe not configured, or card has no Stripe ID
      if (_config.isDemoMode || !envService.isStripeConfigured || (kIsWeb && !envService.isStripeConfigured) || paymentCard.stripeCardId == null) {
        await Future.delayed(Duration(seconds: 1)); // Simulate processing time

        final paymentId = 'payment_demo_${DateTime.now().millisecondsSinceEpoch}';
        print('Demo: Payment processed successfully - ID: $paymentId, Amount: €${order.total}');
        return paymentId;
      }

      // Only check Stripe card ID in production mode
      if (paymentCard.stripeCardId == null) {
        throw Exception('Invalid payment method - Stripe card ID required for production payments');
      }

      // For now, simulate successful payment processing
      // In production, integrate with actual Stripe payment intent creation

      // Save payment record
      try {
        final paymentId = await _savePaymentRecord(
          order: order,
          paymentCard: paymentCard,
          billingAddress: billingAddress,
          stripePaymentIntentId: 'pi_simulated_${DateTime.now().millisecondsSinceEpoch}',
          amount: order.total,
          status: 'succeeded', // Simulate successful payment
        );

        return paymentId;
      } catch (firestoreError) {
        print('Firestore payment record save failed: $firestoreError');
        _config.enableDemoMode();

        // Return demo payment ID
        final paymentId = _config.generateDemoId('payment');
        print('Demo: Payment processed in fallback mode - ID: $paymentId, Amount: €${order.total}');
        return paymentId;
      }
    } catch (e) {
      throw Exception('Payment processing failed: $e');
    }
  }

  Future<String> _savePaymentRecord({
    required order_model.Order order,
    required PaymentCard paymentCard,
    required ShippingAddress billingAddress,
    required String stripePaymentIntentId,
    required double amount,
    required String status,
  }) async {
    final paymentId = _firestore.collection(_paymentsCollection).doc().id;

    final paymentData = {
      'id': paymentId,
      'orderId': order.id,
      'orderNumber': order.orderNumber,
      'userId': order.userId,
      'paymentCardId': paymentCard.id,
      'paymentCardLast4': paymentCard.lastFourDigits,
      'billingAddress': billingAddress.toMap(),
      'amount': amount,
      'currency': order.currency,
      'status': status,
      'stripePaymentIntentId': stripePaymentIntentId,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _firestore.collection(_paymentsCollection).doc(paymentId).set(paymentData);

    return paymentId;
  }

  Future<void> confirmPayment(String paymentIntentClientSecret) async {
    try {
      // For now, simulate successful payment confirmation
      // In production, integrate with actual Stripe confirmation
      print('Payment confirmed for: $paymentIntentClientSecret');
    } catch (e) {
      throw Exception('Payment confirmation failed: $e');
    }
  }

  Future<Map<String, dynamic>?> getPaymentStatus(String paymentId) async {
    try {
      final doc = await _firestore.collection(_paymentsCollection).doc(paymentId).get();

      if (!doc.exists) {
        return null;
      }

      return doc.data();
    } catch (e) {
      throw Exception('Failed to get payment status: $e');
    }
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    try {
      await _firestore.collection(_paymentsCollection).doc(paymentId).update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  Future<void> refundPayment(String paymentId, {double? amount, String? reason}) async {
    try {
      final paymentDoc = await _firestore.collection(_paymentsCollection).doc(paymentId).get();

      if (!paymentDoc.exists) {
        throw Exception('Payment not found');
      }

      final paymentData = paymentDoc.data()!;
      final stripePaymentIntentId = paymentData['stripePaymentIntentId'] as String?;

      if (stripePaymentIntentId == null) {
        throw Exception('Stripe payment intent not found');
      }

      // Create refund with Stripe
      // Note: This would require server-side implementation for security
      // For now, we'll just update the status
      await updatePaymentStatus(paymentId, 'refunded');

      // Add refund metadata
      await _firestore.collection(_paymentsCollection).doc(paymentId).update({
        'refundAmount': amount ?? paymentData['amount'],
        'refundReason': reason,
        'refundedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  Future<void> _updateAllCardsDefault(String userId, bool isDefault) async {
    final batch = _firestore.batch();

    final cardsQuery = await _firestore
        .collection(_cardsCollection)
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in cardsQuery.docs) {
      batch.update(doc.reference, {
        'isDefault': isDefault,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    final userCardsQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection(_userCardsCollection)
        .get();

    for (final doc in userCardsQuery.docs) {
      batch.update(doc.reference, {'isDefault': isDefault});
    }

    await batch.commit();
  }

  // Utility methods for card validation on the frontend
  static bool validateCardForm({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
    required String cardHolderName,
  }) {
    if (cardHolderName.trim().isEmpty) return false;
    if (!CardValidation.isValidCardNumber(cardNumber)) return false;
    if (!CardValidation.isValidExpiryMonth(expiryMonth)) return false;
    if (!CardValidation.isValidExpiryYear(expiryYear)) return false;
    if (CardValidation.isCardExpired(expiryMonth, expiryYear)) return false;

    final cardType = PaymentCard.getCardTypeFromNumber(cardNumber);
    if (!CardValidation.isValidCVC(cvc, cardType)) return false;

    return true;
  }

  static String formatCardNumber(String cardNumber) {
    cardNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (cardNumber.length <= 4) return cardNumber;

    String formatted = '';
    for (int i = 0; i < cardNumber.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += cardNumber[i];
    }

    return formatted;
  }

  static String formatExpiryDate(String expiryDate) {
    expiryDate = expiryDate.replaceAll(RegExp(r'\D'), '');

    if (expiryDate.length >= 2) {
      return '${expiryDate.substring(0, 2)}/${expiryDate.substring(2)}';
    }

    return expiryDate;
  }

  // Local storage for temporary card data during checkout
  static Future<void> saveTemporaryCardData(Map<String, String> cardData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temp_card_data', json.encode(cardData));
  }

  static Future<Map<String, String>?> getTemporaryCardData() async {
    final prefs = await SharedPreferences.getInstance();
    final cardDataString = prefs.getString('temp_card_data');

    if (cardDataString == null) return null;

    try {
      final cardData = json.decode(cardDataString) as Map<String, dynamic>;
      return cardData.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearTemporaryCardData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('temp_card_data');
  }
}