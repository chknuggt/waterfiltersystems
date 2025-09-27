import 'package:flutter/material.dart';
import 'package:waterfilternet/core/theme/app_theme.dart';
import 'package:waterfilternet/models/payment_card.dart';
import 'package:waterfilternet/services/payment_service.dart';
import 'package:waterfilternet/widgets/buttons/primary_button.dart';
import 'add_card_screen.dart';

class CardManagementScreen extends StatefulWidget {
  final bool allowSelection;
  final Function(PaymentCard)? onCardSelected;

  const CardManagementScreen({
    super.key,
    this.allowSelection = false,
    this.onCardSelected,
  });

  @override
  State<CardManagementScreen> createState() => _CardManagementScreenState();
}

class _CardManagementScreenState extends State<CardManagementScreen> {
  final PaymentService _paymentService = PaymentService();
  List<PaymentCard> cards = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedCards = await _paymentService.getUserCards();

      if (mounted) {
        setState(() {
          cards = loadedCards;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading cards: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddCard() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCardScreen(),
      ),
    );

    if (result == true) {
      _loadCards();
    }
  }

  Future<void> _setDefaultCard(PaymentCard card) async {
    try {
      await _paymentService.setDefaultCard(card.id);
      _loadCards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting default card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCard(PaymentCard card) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text('Are you sure you want to delete the card ending in ${card.lastFourDigits}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _paymentService.deleteCard(card.id);
        _loadCards();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Card deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting card: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.allowSelection ? 'Select Payment Card' : 'Payment Cards',
        ),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cards.isEmpty
              ? _buildEmptyState()
              : _buildCardsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddCard,
        backgroundColor: AppTheme.primaryTeal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_off,
            size: 80,
            color: AppTheme.neutralGray400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No payment cards found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first payment card to get started',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Add Card',
            onPressed: _navigateToAddCard,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList() {
    return Column(
      children: [
        if (!widget.allowSelection) ...[
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryTeal.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryTeal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tap a card to select it, or use the menu for more options',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCards,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cards.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final card = cards[index];
                return _buildCardItem(card);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(PaymentCard card) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: card.isDefault
            ? BorderSide(color: AppTheme.primaryTeal, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.allowSelection
            ? () {
                widget.onCardSelected?.call(card);
                Navigator.of(context).pop();
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: _getCardGradient(card.cardType),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getCardIcon(card.cardType),
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        card.cardType.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (!widget.allowSelection)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) async {
                        switch (value) {
                          case 'default':
                            _setDefaultCard(card);
                            break;
                          case 'delete':
                            _deleteCard(card);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (!card.isDefault)
                          const PopupMenuItem(
                            value: 'default',
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 20),
                                SizedBox(width: 8),
                                Text('Set as Default'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '•••• •••• •••• ${card.lastFourDigits}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
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
                        card.cardHolderName.toUpperCase(),
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
                      Row(
                        children: [
                          Text(
                            card.expiryDisplay,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (card.isExpiringSoon) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.warning,
                              color: Colors.orange[300],
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (card.isDefault) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DEFAULT CARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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