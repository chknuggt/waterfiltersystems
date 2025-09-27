import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waterfilternet/core/theme/app_theme.dart';
import 'package:waterfilternet/models/payment_card.dart';
import 'package:waterfilternet/services/payment_service.dart';
import 'package:waterfilternet/widgets/buttons/primary_button.dart';
import 'package:waterfilternet/widgets/forms/custom_text_field.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final PaymentService _paymentService = PaymentService();

  late final TextEditingController _cardNumberController;
  late final TextEditingController _expiryController;
  late final TextEditingController _cvcController;
  late final TextEditingController _cardHolderController;

  bool _setAsDefault = false;
  bool _isLoading = false;
  CardType _detectedCardType = CardType.unknown;

  @override
  void initState() {
    super.initState();
    _cardNumberController = TextEditingController();
    _expiryController = TextEditingController();
    _cvcController = TextEditingController();
    _cardHolderController = TextEditingController();

    // Add listeners for real-time formatting and validation
    _cardNumberController.addListener(_formatCardNumber);
    _expiryController.addListener(_formatExpiryDate);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  void _formatCardNumber() {
    final text = _cardNumberController.text;
    final formatted = PaymentService.formatCardNumber(text);

    if (formatted != text) {
      _cardNumberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // Detect card type
    final cardType = PaymentCard.getCardTypeFromNumber(text.replaceAll(' ', ''));
    if (cardType != _detectedCardType) {
      setState(() {
        _detectedCardType = cardType;
      });
    }
  }

  void _formatExpiryDate() {
    final text = _expiryController.text;
    final formatted = PaymentService.formatExpiryDate(text);

    if (formatted != text) {
      _expiryController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      final expiry = _expiryController.text.split('/');
      final expiryMonth = expiry[0];
      final expiryYear = expiry.length > 1 ? '20${expiry[1]}' : '';

      await _paymentService.saveCard(
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvc: _cvcController.text.trim(),
        cardHolderName: _cardHolderController.text.trim(),
        setAsDefault: _setAsDefault,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Payment Card'),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCardPreview(),
              const SizedBox(height: 32),
              _buildCardDetailsSection(),
              const SizedBox(height: 24),
              _buildOptionsSection(),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Add Card',
                onPressed: _isLoading ? null : _saveCard,
                isLoading: _isLoading,
                fullWidth: true,
              ),
              const SizedBox(height: 16),
              _buildSecurityNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: _getCardGradient(_detectedCardType),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _detectedCardType.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                _getCardIcon(_detectedCardType),
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
          const Spacer(),
          Text(
            _cardNumberController.text.isNotEmpty
                ? _cardNumberController.text
                : '•••• •••• •••• ••••',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CARDHOLDER NAME',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cardHolderController.text.isNotEmpty
                        ? _cardHolderController.text.toUpperCase()
                        : 'YOUR NAME',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXPIRES',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _expiryController.text.isNotEmpty
                        ? _expiryController.text
                        : 'MM/YY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _cardNumberController,
          label: 'Card Number',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Card number is required';
            }
            final cardNumber = value.replaceAll(' ', '');
            if (!CardValidation.isValidCardNumber(cardNumber)) {
              return 'Invalid card number';
            }
            return null;
          },
          suffixIcon: _detectedCardType != CardType.unknown
              ? Icon(
                  _getCardIcon(_detectedCardType),
                  color: AppTheme.primaryTeal,
                )
              : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _expiryController,
                label: 'MM/YY',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Expiry date is required';
                  }
                  final parts = value.split('/');
                  if (parts.length != 2) {
                    return 'Invalid format';
                  }
                  if (!CardValidation.isValidExpiryMonth(parts[0])) {
                    return 'Invalid month';
                  }
                  if (!CardValidation.isValidExpiryYear(parts[1])) {
                    return 'Invalid year';
                  }
                  if (CardValidation.isCardExpired(parts[0], parts[1])) {
                    return 'Card is expired';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _cvcController,
                label: 'CVC',
                keyboardType: TextInputType.number,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'CVC is required';
                  }
                  if (!CardValidation.isValidCVC(value.trim(), _detectedCardType)) {
                    return 'Invalid CVC';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => _showCvcHelp(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _cardHolderController,
          label: 'Cardholder Name',
          keyboardType: TextInputType.name,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Cardholder name is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Set as default payment method'),
          subtitle: const Text('Use this card as default for purchases'),
          value: _setAsDefault,
          onChanged: (value) {
            setState(() {
              _setAsDefault = value ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppTheme.primaryTeal,
        ),
      ],
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutralGray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: AppTheme.primaryTeal,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your card information is encrypted and stored securely using industry-standard security measures.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCvcHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What is CVC?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CVC (Card Verification Code) is a security feature for card transactions.',
            ),
            SizedBox(height: 16),
            Text('• Visa/Mastercard: 3 digits on the back'),
            Text('• American Express: 4 digits on the front'),
            SizedBox(height: 16),
            Text(
              'This code helps verify that you have the physical card.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  List<Color> _getCardGradient(CardType cardType) {
    switch (cardType) {
      case CardType.visa:
        return [const Color(0xFF1A1F71), const Color(0xFF0F3460)];
      case CardType.mastercard:
        return [const Color(0xFFEB001B), const Color(0xFFFF5F00)];
      case CardType.americanExpress:
        return [const Color(0xFF006FCF), const Color(0xFF0099CC)];
      case CardType.discover:
        return [const Color(0xFFFF6000), const Color(0xFFFF8C00)];
      default:
        return [const Color(0xFF6B73FF), const Color(0xFF9DD5EA)];
    }
  }

  IconData _getCardIcon(CardType cardType) {
    switch (cardType) {
      case CardType.visa:
      case CardType.mastercard:
      case CardType.americanExpress:
      case CardType.discover:
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }
}