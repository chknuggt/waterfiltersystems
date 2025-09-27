import 'package:flutter/material.dart';
import 'package:waterfilternet/core/theme/app_theme.dart';
import 'package:waterfilternet/models/order.dart' as order_model;
import 'package:waterfilternet/services/order_service.dart';
import 'package:waterfilternet/widgets/buttons/primary_button.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with TickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  order_model.Order? order;
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _checkmarkAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadOrder();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _checkmarkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    try {
      final loadedOrder = await _orderService.getOrder(widget.orderId);
      if (mounted) {
        setState(() {
          order = loadedOrder;
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
            content: Text('Error loading order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : order == null
                ? _buildErrorState()
                : _buildSuccessContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load order details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Continue Shopping',
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          _buildSuccessAnimation(),
          const SizedBox(height: 32),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildSuccessMessage(),
                const SizedBox(height: 32),
                _buildOrderSummary(),
                const SizedBox(height: 32),
                _buildDeliveryInfo(),
                const SizedBox(height: 40),
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return ScaleTransition(
      scale: _checkmarkAnimation,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.shade50,
          border: Border.all(
            color: Colors.green,
            width: 3,
          ),
        ),
        child: Icon(
          Icons.check,
          size: 60,
          color: Colors.green.shade600,
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        const Text(
          'Order Placed Successfully!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.neutralGray900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Thank you for your order. We\'ll send you a confirmation email shortly.',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.neutralGray600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryTeal.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: AppTheme.primaryTeal,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Order Number', '#${order!.orderNumber}'),
          _buildSummaryRow('Items', '${order!.items.length}'),
          _buildSummaryRow('Total', '€${order!.total.toStringAsFixed(2)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: AppTheme.neutralGray700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? AppTheme.primaryTeal : AppTheme.neutralGray900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Delivery Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Shipping to:',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutralGray600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order!.shippingAddress.fullAddress,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: AppTheme.neutralGray600,
              ),
              const SizedBox(width: 4),
              Text(
                'Estimated delivery: ${order!.shippingMethod.estimatedDays} business days',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutralGray600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          text: 'Track Your Order',
          onPressed: () {
            // TODO: Navigate to order tracking screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order tracking coming soon!'),
              ),
            );
          },
          icon: Icons.track_changes,
          fullWidth: true,
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          text: 'Continue Shopping',
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          ),
          variant: ButtonVariant.outline,
          fullWidth: true,
        ),
        const SizedBox(height: 20),
        _buildSupportInfo(),
      ],
    );
  }

  Widget _buildSupportInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutralGray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent,
            color: AppTheme.neutralGray600,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Need Help?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.neutralGray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Contact our customer support team if you have any questions about your order.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.neutralGray600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}