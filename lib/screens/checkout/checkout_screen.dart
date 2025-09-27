import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waterfilternet/core/theme/app_theme.dart';
import 'package:waterfilternet/models/shipping_address.dart';
import 'package:waterfilternet/models/payment_card.dart';
import 'package:waterfilternet/models/order.dart';
import 'package:waterfilternet/providers/cart_provider.dart';
import 'package:waterfilternet/services/order_service.dart';
import 'package:waterfilternet/services/payment_service.dart';
import 'package:waterfilternet/services/invoice_service.dart';
import 'package:waterfilternet/services/address_service.dart';
import 'package:waterfilternet/widgets/buttons/primary_button.dart';
import 'package:waterfilternet/widgets/common/section_header.dart';
import 'package:waterfilternet/screens/address/address_management_screen.dart';
import 'package:waterfilternet/screens/payment/card_management_screen.dart';

enum CheckoutStep {
  shipping,
  payment,
  review,
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  CheckoutStep currentStep = CheckoutStep.shipping;
  final PageController _pageController = PageController();

  ShippingAddress? selectedShippingAddress;
  ShippingAddress? selectedBillingAddress;
  bool useSameAsBilling = true;
  ShippingMethod? selectedShippingMethod;
  PaymentCard? selectedPaymentCard;

  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();
  final InvoiceService _invoiceService = InvoiceService();
  final AddressService _addressService = AddressService();

  bool isProcessing = false;
  String? orderNote;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Load default shipping address
      final defaultShippingAddress = await _addressService.getDefaultAddress(
        type: AddressType.shipping,
      );

      // Load default billing address
      final defaultBillingAddress = await _addressService.getDefaultAddress(
        type: AddressType.billing,
      );

      // Load default payment card
      final defaultCard = await _paymentService.getDefaultCard();

      if (mounted) {
        setState(() {
          selectedShippingAddress = defaultShippingAddress;
          selectedBillingAddress = defaultBillingAddress ?? defaultShippingAddress;
          selectedPaymentCard = defaultCard;
        });

        // Load available shipping methods if we have an address
        if (selectedShippingAddress != null) {
          final cart = Provider.of<CartProvider>(context, listen: false);
          if (cart.isNotEmpty) {
            final methods = await _orderService.getShippingMethods(
              address: selectedShippingAddress!,
              orderValue: cart.totalAmount,
            );

            if (methods.isNotEmpty && mounted) {
              setState(() {
                selectedShippingMethod = methods.first;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralGray50,
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.neutralGray900,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppSizing.paddingLarge),
            child: _buildProgressIndicator(),
          ),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentStep = CheckoutStep.values[index];
                });
              },
              children: [
                _buildShippingStep(),
                _buildPaymentStep(),
                _buildReviewStep(),
              ],
            ),
          ),

          // Bottom action button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppSizing.paddingLarge),
            child: SafeArea(
              child: _buildActionButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: CheckoutStep.values.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = currentStep.index >= index;
        final isCurrent = currentStep == step;

        return Expanded(
          child: Row(
            children: [
              // Step circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryTeal : AppTheme.neutralGray200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isActive
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppTheme.neutralGray500,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              // Step label
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStepLabel(step),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: isCurrent ? AppTheme.primaryTeal : AppTheme.neutralGray600,
                  ),
                ),
              ),

              // Connector line
              if (index < CheckoutStep.values.length - 1)
                Container(
                  height: 2,
                  width: 40,
                  color: isActive ? AppTheme.primaryTeal : AppTheme.neutralGray200,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getStepLabel(CheckoutStep step) {
    switch (step) {
      case CheckoutStep.shipping:
        return 'Shipping';
      case CheckoutStep.payment:
        return 'Payment';
      case CheckoutStep.review:
        return 'Review';
    }
  }

  Widget _buildShippingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizing.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Shipping Address'),
          const SizedBox(height: AppSizing.paddingMedium),

          // Shipping address selector/form
          Container(
            padding: const EdgeInsets.all(AppSizing.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
              border: Border.all(color: AppTheme.neutralGray200),
            ),
            child: Column(
              children: [
                if (selectedShippingAddress == null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.add_location,
                        color: AppTheme.primaryTeal,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Shipping Address',
                        style: AppTextStyles.sectionHeader.copyWith(
                          color: AppTheme.primaryTeal,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please add a shipping address to continue',
                    style: AppTextStyles.productDescription,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Add Address',
                    onPressed: () => _navigateToAddressManagement(isShipping: true),
                    variant: ButtonVariant.secondary,
                    fullWidth: true,
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppTheme.primaryTeal,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedShippingAddress!.displayName,
                          style: AppTextStyles.sectionHeader.copyWith(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _navigateToAddressManagement(isShipping: true),
                        icon: const Icon(Icons.edit, size: 20),
                        color: AppTheme.neutralGray600,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedShippingAddress!.shortAddress,
                    style: AppTextStyles.productDescription,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSizing.paddingLarge),

          // Billing address
          const SectionHeader(title: 'Billing Address'),
          const SizedBox(height: AppSizing.paddingMedium),

          Container(
            padding: const EdgeInsets.all(AppSizing.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
              border: Border.all(color: AppTheme.neutralGray200),
            ),
            child: Column(
              children: [
                CheckboxListTile(
                  title: const Text('Same as shipping address'),
                  value: useSameAsBilling,
                  onChanged: (value) {
                    setState(() {
                      useSameAsBilling = value ?? true;
                      if (useSameAsBilling) {
                        selectedBillingAddress = selectedShippingAddress;
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                if (!useSameAsBilling) ...[
                  const Divider(),
                  if (selectedBillingAddress == null) ...[
                    PrimaryButton(
                      text: 'Add Billing Address',
                      onPressed: () => _navigateToAddressManagement(isShipping: false),
                      variant: ButtonVariant.secondary,
                      fullWidth: true,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(
                          Icons.payment,
                          color: AppTheme.primaryTeal,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedBillingAddress!.displayName,
                            style: AppTextStyles.sectionHeader.copyWith(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _navigateToAddressManagement(isShipping: false),
                          icon: const Icon(Icons.edit, size: 20),
                          color: AppTheme.neutralGray600,
                        ),
                      ],
                    ),
                    Text(
                      selectedBillingAddress!.shortAddress,
                      style: AppTextStyles.productDescription,
                    ),
                  ],
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSizing.paddingLarge),

          // Shipping methods
          if (selectedShippingAddress != null) ...[
            const SectionHeader(title: 'Shipping Method'),
            const SizedBox(height: AppSizing.paddingMedium),
            _buildShippingMethods(),
          ],
        ],
      ),
    );
  }

  Widget _buildShippingMethods() {
    final methods = OrderService.getAvailableShippingMethods();
    final cart = Provider.of<CartProvider>(context);

    return Column(
      children: methods.where((method) {
        return method.id != 'free' || cart.totalAmount >= 75.0;
      }).map((method) {
        final isSelected = selectedShippingMethod?.id == method.id;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSizing.paddingSmall),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizing.radiusMedium),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedShippingMethod = method;
                });
              },
              borderRadius: BorderRadius.circular(AppSizing.radiusMedium),
              child: Container(
                padding: const EdgeInsets.all(AppSizing.paddingLarge),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryTeal : AppTheme.neutralGray200,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(AppSizing.radiusMedium),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: method.id,
                      groupValue: selectedShippingMethod?.id,
                      onChanged: (value) {
                        setState(() {
                          selectedShippingMethod = method;
                        });
                      },
                      activeColor: AppTheme.primaryTeal,
                    ),
                    const SizedBox(width: AppSizing.paddingSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.name,
                            style: AppTextStyles.productTitle.copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            method.description,
                            style: AppTextStyles.productDescription.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      method.cost == 0 ? 'Free' : '€${method.cost.toStringAsFixed(2)}',
                      style: AppTextStyles.priceText.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizing.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Payment Method'),
          const SizedBox(height: AppSizing.paddingMedium),

          Container(
            padding: const EdgeInsets.all(AppSizing.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
              border: Border.all(color: AppTheme.neutralGray200),
            ),
            child: Column(
              children: [
                if (selectedPaymentCard == null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.credit_card,
                        color: AppTheme.primaryTeal,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Payment Method',
                        style: AppTextStyles.sectionHeader.copyWith(
                          color: AppTheme.primaryTeal,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please add a payment method to continue',
                    style: AppTextStyles.productDescription,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Add Card',
                    onPressed: () => _navigateToCardManagement(),
                    variant: ButtonVariant.secondary,
                    fullWidth: true,
                  ),
                ] else ...[
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.neutralGray100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.credit_card,
                          size: 16,
                          color: AppTheme.neutralGray600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedPaymentCard!.displayName,
                              style: AppTextStyles.sectionHeader.copyWith(fontSize: 16),
                            ),
                            Text(
                              'Expires ${selectedPaymentCard!.expiryDisplay}',
                              style: AppTextStyles.productDescription,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _navigateToCardManagement(),
                        icon: const Icon(Icons.edit, size: 20),
                        color: AppTheme.neutralGray600,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSizing.paddingLarge),

          // Order notes
          const SectionHeader(title: 'Order Notes (Optional)'),
          const SizedBox(height: AppSizing.paddingMedium),

          Container(
            padding: const EdgeInsets.all(AppSizing.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
              border: Border.all(color: AppTheme.neutralGray200),
            ),
            child: TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any special instructions for your order...',
                border: InputBorder.none,
                hintStyle: AppTextStyles.productDescription,
              ),
              style: AppTextStyles.productTitle.copyWith(fontSize: 14),
              onChanged: (value) {
                orderNote = value;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final cart = Provider.of<CartProvider>(context);
    final subtotal = cart.totalAmount; // Already tax-inclusive
    final shippingCost = selectedShippingMethod?.cost ?? 0.0;
    final tax = 0.0; // Tax already included in product prices
    final total = subtotal + shippingCost; // No additional tax

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizing.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order items
          const SectionHeader(title: 'Order Summary'),
          const SizedBox(height: AppSizing.paddingMedium),

          Container(
            padding: const EdgeInsets.all(AppSizing.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
              border: Border.all(color: AppTheme.neutralGray200),
            ),
            child: Column(
              children: cart.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizing.paddingMedium),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSizing.radiusSmall),
                          color: AppTheme.neutralGray100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppSizing.radiusSmall),
                          child: item.product.imageUrl.isNotEmpty
                              ? Image.network(
                                  item.product.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.water_drop_outlined,
                                      color: AppTheme.neutralGray400,
                                      size: 20,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.water_drop_outlined,
                                  color: AppTheme.neutralGray400,
                                  size: 20,
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSizing.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: AppTextStyles.productTitle.copyWith(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Qty: ${item.quantity}',
                              style: AppTextStyles.productDescription,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '€${item.totalPrice.toStringAsFixed(2)}',
                        style: AppTextStyles.priceText.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSizing.paddingLarge),

          // Totals
          Container(
            padding: const EdgeInsets.all(AppSizing.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
              border: Border.all(color: AppTheme.neutralGray200),
            ),
            child: Column(
              children: [
                _buildTotalRow('Subtotal', '€${subtotal.toStringAsFixed(2)}'),
                _buildTotalRow('Shipping', shippingCost == 0 ? 'Free' : '€${shippingCost.toStringAsFixed(2)}'),
                _buildTotalRow('Tax', '€${tax.toStringAsFixed(2)}'),
                const Divider(),
                _buildTotalRow(
                  'Total',
                  '€${total.toStringAsFixed(2)}',
                  isTotal: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizing.paddingLarge),

          // Shipping and payment info
          if (selectedShippingAddress != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSizing.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
                border: Border.all(color: AppTheme.neutralGray200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping, color: AppTheme.primaryTeal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Shipping to:',
                        style: AppTextStyles.productTitle.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedShippingAddress!.fullAddress,
                    style: AppTextStyles.productDescription,
                  ),
                  if (selectedShippingMethod != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'via ${selectedShippingMethod!.name}',
                      style: AppTextStyles.productDescription,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSizing.paddingMedium),
          ],

          if (selectedPaymentCard != null)
            Container(
              padding: const EdgeInsets.all(AppSizing.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
                border: Border.all(color: AppTheme.neutralGray200),
              ),
              child: Row(
                children: [
                  Icon(Icons.payment, color: AppTheme.primaryTeal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Paying with:',
                    style: AppTextStyles.productTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedPaymentCard!.displayName,
                    style: AppTextStyles.productDescription,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? AppTextStyles.sectionHeader.copyWith(fontSize: 16)
                : AppTextStyles.productDescription,
          ),
          Text(
            amount,
            style: isTotal
                ? AppTextStyles.priceText.copyWith(fontSize: 18)
                : AppTextStyles.priceText.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final cart = Provider.of<CartProvider>(context);

    if (isProcessing) {
      return Container(
        height: 48,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
          ),
        ),
      );
    }

    String buttonText;
    bool isEnabled = false;

    switch (currentStep) {
      case CheckoutStep.shipping:
        buttonText = 'Continue to Payment';
        isEnabled = selectedShippingAddress != null && selectedShippingMethod != null;
        break;
      case CheckoutStep.payment:
        buttonText = 'Review Order';
        isEnabled = selectedPaymentCard != null;
        break;
      case CheckoutStep.review:
        buttonText = 'Place Order - €${_calculateTotal().toStringAsFixed(2)}';
        isEnabled = true;
        break;
    }

    return PrimaryButton(
      text: buttonText,
      onPressed: isEnabled ? _handleActionButtonPress : null,
      fullWidth: true,
    );
  }

  double _calculateTotal() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final subtotal = cart.totalAmount; // Already tax-inclusive
    final shippingCost = selectedShippingMethod?.cost ?? 0.0;
    // No additional tax - prices already include 19% Cyprus VAT
    return subtotal + shippingCost;
  }

  Future<void> _handleActionButtonPress() async {
    switch (currentStep) {
      case CheckoutStep.shipping:
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      case CheckoutStep.payment:
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        break;
      case CheckoutStep.review:
        await _processOrder();
        break;
    }
  }

  Future<void> _processOrder() async {
    if (selectedShippingAddress == null ||
        selectedPaymentCard == null ||
        selectedShippingMethod == null) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);

      print('DEBUG: Starting order creation...');

      // Create order
      final orderId = await _orderService.createOrder(
        cartItems: cart.items,
        shippingAddress: selectedShippingAddress!,
        billingAddress: useSameAsBilling ? selectedShippingAddress! : selectedBillingAddress!,
        shippingMethod: selectedShippingMethod!,
        paymentCard: selectedPaymentCard!,
        paymentMethodId: selectedPaymentCard!.stripeCardId ?? '',
        notes: orderNote,
      );

      print('DEBUG: Order created with ID: $orderId');

      // Get the created order
      final order = await _orderService.getOrder(orderId);
      if (order == null) {
        throw Exception('Order creation failed');
      }

      print('DEBUG: Order retrieved successfully');

      // Process payment
      await _paymentService.processPayment(
        order: order,
        paymentCard: selectedPaymentCard!,
        billingAddress: useSameAsBilling ? selectedShippingAddress! : selectedBillingAddress!,
      );

      print('DEBUG: Payment processed successfully');

      // Generate invoice
      await _invoiceService.createInvoice(order);

      print('DEBUG: Invoice created successfully');

      // Clear cart
      cart.clearCart();

      print('DEBUG: Cart cleared, navigating to success screen...');

      // Navigate to success screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/order_success',
          arguments: orderId,
        );
        print('DEBUG: Navigation to success screen initiated');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order processing failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  void _navigateToAddressManagement({required bool isShipping}) async {
    final selectedAddress = await Navigator.push<ShippingAddress>(
      context,
      MaterialPageRoute(
        builder: (context) => AddressManagementScreen(
          filterType: isShipping ? AddressType.shipping : AddressType.billing,
          allowSelection: true,
          onAddressSelected: (address) {
            if (mounted) {
              setState(() {
                if (isShipping) {
                  selectedShippingAddress = address;
                } else {
                  selectedBillingAddress = address;
                }
              });
            }
          },
        ),
      ),
    );

    // Reload addresses after returning if needed
    if (selectedAddress != null) {
      _loadInitialData();
    }
  }

  void _navigateToCardManagement() async {
    final selectedCard = await Navigator.push<PaymentCard>(
      context,
      MaterialPageRoute(
        builder: (context) => CardManagementScreen(
          allowSelection: true,
          onCardSelected: (card) {
            if (mounted) {
              setState(() {
                selectedPaymentCard = card;
              });
            }
          },
        ),
      ),
    );

    // Reload cards after returning if needed
    if (selectedCard != null) {
      _loadInitialData();
    }
  }
}