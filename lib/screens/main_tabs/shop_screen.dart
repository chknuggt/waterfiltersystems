import 'package:flutter/material.dart';
import 'package:waterfilternet/models/category_model.dart';
import 'package:waterfilternet/models/popular_model.dart';
import 'package:waterfilternet/models/recommended_model.dart';
import 'package:waterfilternet/services/woocommerce_api.dart';
import 'package:waterfilternet/models/product.dart';
import 'package:waterfilternet/core/theme/app_theme.dart';
import 'package:waterfilternet/widgets/cards/product_card.dart';
import 'package:waterfilternet/widgets/common/filter_chips_row.dart';
import 'package:waterfilternet/widgets/common/section_header.dart';
import 'package:waterfilternet/widgets/buttons/primary_button.dart';
import 'package:flutter_svg/svg.dart';

// Import product categories
import 'package:waterfilternet/screens/product_categories/product_categories.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

final Map<String, Widget Function()> categoryPages = {
  'Reverse Osmosis': () => ProductCategories.getCategoryPage('reverseOsmosis'),
  'Water Softener': () => ProductCategories.getCategoryPage('waterSofteners'),
  'Water Filters': () => ProductCategories.getCategoryPage('waterFilter'),
  'Water Coolers': () => ProductCategories.getCategoryPage('waterCoolers'),
  'Water Makers': () => ProductCategories.getCategoryPage('waterMakers'),
  'Soda Stream': () => ProductCategories.getCategoryPage('sodaStream'),
  'Faucets': () => ProductCategories.getCategoryPage('faucets'),
  'Water Sterilization': () => ProductCategories.getCategoryPage('waterSterilization'),
  'Water Measuring': () => ProductCategories.getCategoryPage('waterMeasuring'),
};

class _ShopScreenState extends State<ShopScreen> {
  List<CategoryModel> categories = [];
  List<RecommendationModels> recommended = [];
  List<PopularInstalation> popularModels = [];
  List<Product> products = [];
  final WooCommerceAPI api = WooCommerceAPI();

  bool isSearching = false;
  List<Product> searchResults = [];
  bool isLoadingSearch = false;
  bool isLoadingProducts = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Filter state
  String? selectedCategory;
  String? selectedPriceRange;
  String? selectedBrand;

  // Available filter options
  final List<String> categoryFilters = [
    'Water Filters',
    'Reverse Osmosis',
    'Water Coolers',
    'Water Softener',
  ];

  final List<String> priceFilters = [
    'Under €50',
    '€50 - €100',
    '€100 - €200',
    'Over €200',
  ];

  final List<String> brandFilters = [
    'Aquapure',
    'FilterMax',
    'CrystalClear',
    'PureWater',
  ];

  @override
  void initState() {
    super.initState();
    _getInitialInfo();
    _loadProducts();
  }

  void _getInitialInfo() {
    categories = CategoryModel.getCategories();
    recommended = RecommendationModels.getRecommendations();
    popularModels = PopularInstalation.getPopularProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      isLoadingProducts = true;
    });
    try {
      final results = await api.fetchProducts();
      if (mounted) {
        setState(() {
          products = results;
          isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingProducts = false;
        });
      }
      debugPrint("Products loading error: $e");
    }
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults = [];
      });
      return;
    }
    setState(() {
      isSearching = true;
      isLoadingSearch = true;
    });
    try {
      final results = await api.fetchProducts(search: query);
      if (!mounted) return;
      setState(() {
        searchResults = results;
        isLoadingSearch = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingSearch = false;
      });
      debugPrint("Search error: $e");
    }
  }

  void _onFilterChanged(String? filter) {
    setState(() {
      selectedCategory = filter;
    });
    // TODO: Apply filter to product list
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralGray50,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                pinned: false,
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.neutralGray900,
                title: const Text(
                  'Shop',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      // TODO: Open filter sheet
                    },
                    icon: const Icon(Icons.tune),
                    tooltip: 'Filters',
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(
                      AppSizing.paddingLarge,
                      0,
                      AppSizing.paddingLarge,
                      AppSizing.paddingSmall,
                    ),
                    child: _buildSearchField(),
                  ),
                ),
              ),

              // Filters Bar (Simplified - Non-Sticky for stability)
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: FilterChipsRow(
                    filters: categoryFilters,
                    selectedFilter: selectedCategory,
                    onFilterChanged: _onFilterChanged,
                  ),
                ),
              ),

              // Main Content
              if (!isSearching) ...[
                // Enhanced Categories Section - Now Prominent
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSizing.paddingLarge),
                      const SectionHeader(
                        title: 'Shop by Category',
                        subtitle: 'Find the perfect water solution for your needs',
                        actionText: 'View All',
                      ),
                      const SizedBox(height: AppSizing.paddingMedium),
                      _buildEnhancedCategoriesGrid(),
                      const SizedBox(height: AppSizing.paddingLarge),
                      // Quick Category Actions
                      _buildQuickCategoryActions(),
                    ],
                  ),
                ),

                // Featured Products
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSizing.paddingXLarge),
                      const SectionHeader(
                        title: 'Featured Products',
                        subtitle: 'Our top recommendations for you',
                        actionText: 'View All',
                      ),
                      const SizedBox(height: AppSizing.paddingMedium),
                      _buildRecommendationsSection(),
                    ],
                  ),
                ),

                // All Products
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: AppSizing.paddingXLarge),
                      const SectionHeader(
                        title: 'All Products',
                        subtitle: 'Complete range of water filtration solutions',
                      ),
                      const SizedBox(height: AppSizing.paddingMedium),
                    ],
                  ),
                ),

                // Products Grid
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (isLoadingProducts) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSizing.paddingXLarge),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (products.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSizing.paddingXLarge),
                            child: Text(
                              'No products available',
                              style: AppTextStyles.productDescription,
                            ),
                          ),
                        );
                      }

                      final product = products[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizing.paddingLarge,
                          vertical: AppSizing.paddingSmall,
                        ),
                        child: ProductCard(
                          product: product,
                          onTap: () {
                            // TODO: Navigate to product detail
                          },
                        ),
                      );
                    },
                    childCount: isLoadingProducts ? 1 : products.length,
                  ),
                ),

                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSizing.paddingXXLarge),
                ),
              ],
            ],
          ),

          // Search Results Overlay
          if (isSearching)
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.white,
                child: isLoadingSearch
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSizing.paddingLarge),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final product = searchResults[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSizing.paddingMedium,
                            ),
                            child: ProductCard(
                              product: product,
                              onTap: () {
                                // TODO: Navigate to product detail
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.neutralGray100,
        borderRadius: BorderRadius.circular(AppSizing.radiusMedium),
        border: Border.all(color: AppTheme.neutralGray200),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search water filters, parts...',
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.neutralGray500,
              ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppTheme.neutralGray500,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(
                    Icons.clear,
                    color: AppTheme.neutralGray500,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizing.paddingLarge,
            vertical: AppSizing.paddingMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizing.paddingLarge),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSizing.paddingMedium),
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              String categoryName = category.name;
              if (categoryPages.containsKey(categoryName)) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => categoryPages[categoryName]!(),
                  ),
                );
              }
            },
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neutralGray300.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        category.iconPath,
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          AppTheme.primaryTeal,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizing.paddingSmall),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.neutralGray800,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizing.paddingLarge),
        itemCount: recommended.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSizing.paddingMedium),
        itemBuilder: (context, index) {
          final item = recommended[index];
          return Container(
            width: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neutralGray300.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizing.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: SvgPicture.asset(
                      item.iconPath,
                      height: 60,
                    ),
                  ),
                  const SizedBox(height: AppSizing.paddingMedium),
                  Text(
                    item.name,
                    style: AppTextStyles.productTitle.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${item.price} | ${item.duration}",
                    style: AppTextStyles.productDescription.copyWith(fontSize: 12),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: PrimaryButton(
                      text: 'View',
                      size: ButtonSize.small,
                      onPressed: () {
                        // TODO: Navigate to product
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedCategoriesGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizing.paddingLarge),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          mainAxisSpacing: AppSizing.paddingMedium,
          crossAxisSpacing: AppSizing.paddingMedium,
        ),
        itemCount: categories.length > 6 ? 6 : categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              String categoryName = category.name;
              if (categoryPages.containsKey(categoryName)) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => categoryPages[categoryName]!(),
                  ),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neutralGray300.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizing.paddingMedium),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: category.boxColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          category.iconPath,
                          width: 26,
                          height: 26,
                          colorFilter: ColorFilter.mode(
                            category.boxColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizing.paddingSmall),
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.neutralGray900,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${10 + index * 3} products', // Mock product count
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.neutralGray600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickCategoryActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizing.paddingLarge),
      padding: const EdgeInsets.all(AppSizing.paddingLarge),
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
        border: Border.all(
          color: AppTheme.primaryTeal.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            color: AppTheme.primaryTeal,
            size: AppSizing.iconLarge,
          ),
          const SizedBox(width: AppSizing.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help Finding Products?',
                  style: AppTextStyles.productTitle.copyWith(
                    color: AppTheme.primaryTeal,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Use our smart filters to find exactly what you need',
                  style: AppTextStyles.productDescription.copyWith(
                    fontSize: 13,
                    color: AppTheme.neutralGray700,
                  ),
                ),
              ],
            ),
          ),
          PrimaryButton(
            text: 'Browse All',
            size: ButtonSize.small,
            onPressed: () {
              // TODO: Navigate to all categories
            },
          ),
        ],
      ),
    );
  }
}