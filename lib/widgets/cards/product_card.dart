import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppSizing.paddingMedium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizing.radiusMedium),
                  color: AppTheme.neutralGray50,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizing.radiusMedium),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.water_drop_outlined,
                              size: AppSizing.iconLarge,
                              color: AppTheme.neutralGray400,
                            );
                          },
                        )
                      : const Icon(
                          Icons.water_drop_outlined,
                          size: AppSizing.iconLarge,
                          color: AppTheme.neutralGray400,
                        ),
                ),
              ),

              const SizedBox(width: AppSizing.paddingMedium),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: AppTextStyles.productTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Product Description (if available)
                    if (product.description.isNotEmpty)
                      Text(
                        product.description,
                        style: AppTextStyles.productDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 8),

                    // Rating placeholder
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 14,
                            color: index < 4
                                ? AppTheme.warningAmber
                                : AppTheme.neutralGray300,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          '4.0',
                          style: AppTextStyles.productRating,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Price and Add to Cart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '€${product.price.toStringAsFixed(2)}',
                                style: AppTextStyles.priceText,
                              ),
                            ],
                          ),
                        ),

                        // Add to Cart Button
                        Consumer<CartProvider>(
                          builder: (context, cart, child) {
                            final isInCart = cart.isInCart(product.id);
                            final quantity = cart.getQuantity(product.id);

                            if (isInCart) {
                              return Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTeal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppSizing.radiusSmall),
                                  border: Border.all(color: AppTheme.primaryTeal, width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => cart.decreaseQuantity(product.id),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: const Icon(
                                          Icons.remove,
                                          size: 16,
                                          color: AppTheme.primaryTeal,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryTeal,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => cart.increaseQuantity(product.id),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: const Icon(
                                          Icons.add,
                                          size: 16,
                                          color: AppTheme.primaryTeal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return SizedBox(
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () {
                                  cart.addToCart(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${product.name} added to cart'),
                                      backgroundColor: AppTheme.successGreen,
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizing.paddingMedium,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: const Text('Add'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}