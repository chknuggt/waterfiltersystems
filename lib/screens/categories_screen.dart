import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:waterfilternet/core/theme/app_theme.dart';
import 'package:waterfilternet/models/category_model.dart';

// Import product categories
import 'package:waterfilternet/screens/product_categories/product_categories.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<CategoryModel> categories = [];
  String searchQuery = '';

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

  @override
  void initState() {
    super.initState();
    categories = CategoryModel.getCategories();
  }

  List<CategoryModel> get filteredCategories {
    if (searchQuery.isEmpty) {
      return categories;
    }
    return categories.where((category) =>
        category.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  void _onCategoryTap(CategoryModel category) {
    if (categoryPages.containsKey(category.name)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => categoryPages[category.name]!(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${category.name} page coming soon!'),
          backgroundColor: AppTheme.neutralGray800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralGray50,
      body: CustomScrollView(
        slivers: [
          // App Bar with Search
          SliverAppBar(
            floating: true,
            pinned: false,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.neutralGray900,
            automaticallyImplyLeading: false,
            title: const Text(
              'Categories',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(
                  AppSizing.paddingLarge,
                  0,
                  AppSizing.paddingLarge,
                  AppSizing.paddingLarge,
                ),
                child: _buildSearchField(),
              ),
            ),
          ),

          // Categories Count Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSizing.paddingLarge),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredCategories.length} Categories',
                    style: AppTextStyles.sectionHeader.copyWith(fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Sort functionality
                    },
                    icon: const Icon(
                      Icons.sort,
                      size: AppSizing.iconSmall,
                    ),
                    label: const Text('Sort'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizing.paddingMedium,
                        vertical: AppSizing.paddingSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categories Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.paddingLarge,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                mainAxisSpacing: AppSizing.paddingLarge,
                crossAxisSpacing: AppSizing.paddingLarge,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = filteredCategories[index];
                  return _buildCategoryCard(category);
                },
                childCount: filteredCategories.length,
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSizing.paddingXXLarge),
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
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search categories...',
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.neutralGray500,
              ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppTheme.neutralGray500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizing.paddingLarge,
            vertical: AppSizing.paddingMedium,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return GestureDetector(
      onTap: () => _onCategoryTap(category),
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
          padding: const EdgeInsets.all(AppSizing.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: category.boxColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    category.iconPath,
                    width: 28,
                    height: 28,
                    colorFilter: ColorFilter.mode(
                      category.boxColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSizing.paddingMedium),

              // Category Name
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: AppTextStyles.productTitle.copyWith(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Product Count (placeholder)
              Text(
                '12 products', // TODO: Get actual product count
                style: AppTextStyles.productDescription.copyWith(
                  fontSize: 12,
                  color: AppTheme.neutralGray600,
                ),
              ),

              const SizedBox(height: AppSizing.paddingMedium),

              // View Button
              Container(
                width: double.infinity,
                height: 32,
                decoration: BoxDecoration(
                  color: category.boxColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizing.radiusSmall),
                  border: Border.all(
                    color: category.boxColor,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'View Products',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: category.boxColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}