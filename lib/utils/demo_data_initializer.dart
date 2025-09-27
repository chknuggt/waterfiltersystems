import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_cache.dart';
import '../models/service_profile.dart';
import '../models/user_model.dart';
import '../services/config_service.dart';

class DemoDataInitializer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final ConfigService _config = ConfigService();

  /// Initialize all demo data for the admin user
  static Future<void> initializeAllDemoData() async {
    try {
      print('DemoDataInitializer: Starting demo data initialization...');

      // Get current user (should be admin)
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DemoDataInitializer: No authenticated user found');
        return;
      }

      print('DemoDataInitializer: Initializing demo data for user: ${user.email}');

      // Create demo product cache
      await _createDemoProductCache();

      // Create demo user profile if it doesn't exist
      await _createDemoUserProfile(user);

      // Create demo service profiles
      await _createDemoServiceProfiles(user.uid);

      print('DemoDataInitializer: Demo data initialization completed successfully');
    } catch (e) {
      print('DemoDataInitializer: Error initializing demo data: $e');
    }
  }

  /// Create demo product cache entries
  static Future<void> _createDemoProductCache() async {
    try {
      print('DemoDataInitializer: Creating demo product cache...');

      final demoProducts = [
        ProductCache(
          wooProductId: 1001,
          name: 'Sediment Filter Cartridge - 5 Micron',
          slug: 'sediment-filter-5-micron',
          shortDescription: 'High-quality sediment filter removes particles down to 5 microns',
          sku: 'SED-FILTER-5M',
          price: 25.99,
          salePrice: 22.99,
          inStock: true,
          stockQuantity: 150,
          manageStock: true,
          status: ProductCacheStatus.active,
          images: [
            ProductCacheImage(
              src: 'https://via.placeholder.com/400x400/2196F3/FFFFFF?text=Sediment+Filter',
              alt: 'Sediment Filter Cartridge',
              position: 1,
            ),
          ],
          categories: [
            ProductCacheCategory(
              id: 10,
              name: 'Filter Cartridges',
              slug: 'filter-cartridges',
            ),
            ProductCacheCategory(
              id: 11,
              name: 'Sediment Filters',
              slug: 'sediment-filters',
            ),
          ],
          attributes: {
            'Micron Rating': '5 micron',
            'Filter Type': 'Sediment',
            'Compatibility': 'Standard 10" housing',
          },
          weight: 0.5,
          dimensions: {'length': '10', 'width': '2.5', 'height': '2.5'},
          updatedAt: DateTime.now(),
          featured: true,
          averageRating: 4.5,
          ratingCount: 23,
        ),
        ProductCache(
          wooProductId: 1002,
          name: 'Carbon Block Filter - Chlorine Removal',
          slug: 'carbon-block-filter-chlorine',
          shortDescription: 'Activated carbon block filter for chlorine and taste/odor removal',
          sku: 'CARBON-BLOCK-CHL',
          price: 35.99,
          inStock: true,
          stockQuantity: 89,
          manageStock: true,
          status: ProductCacheStatus.active,
          images: [
            ProductCacheImage(
              src: 'https://via.placeholder.com/400x400/4CAF50/FFFFFF?text=Carbon+Filter',
              alt: 'Carbon Block Filter',
              position: 1,
            ),
          ],
          categories: [
            ProductCacheCategory(
              id: 10,
              name: 'Filter Cartridges',
              slug: 'filter-cartridges',
            ),
            ProductCacheCategory(
              id: 12,
              name: 'Carbon Filters',
              slug: 'carbon-filters',
            ),
          ],
          attributes: {
            'Filter Type': 'Carbon Block',
            'Removes': 'Chlorine, Taste, Odor',
            'Compatibility': 'Standard 10" housing',
            'Capacity': '6 months typical use',
          },
          weight: 0.7,
          dimensions: {'length': '10', 'width': '2.5', 'height': '2.5'},
          updatedAt: DateTime.now(),
          featured: false,
          averageRating: 4.7,
          ratingCount: 45,
        ),
        ProductCache(
          wooProductId: 1003,
          name: 'Reverse Osmosis Membrane - 75 GPD',
          slug: 'ro-membrane-75gpd',
          shortDescription: 'High-performance RO membrane producing 75 gallons per day',
          sku: 'RO-MEM-75GPD',
          price: 89.99,
          salePrice: 79.99,
          inStock: true,
          stockQuantity: 45,
          manageStock: true,
          status: ProductCacheStatus.active,
          images: [
            ProductCacheImage(
              src: 'https://via.placeholder.com/400x400/FF9800/FFFFFF?text=RO+Membrane',
              alt: 'RO Membrane 75 GPD',
              position: 1,
            ),
          ],
          categories: [
            ProductCacheCategory(
              id: 10,
              name: 'Filter Cartridges',
              slug: 'filter-cartridges',
            ),
            ProductCacheCategory(
              id: 13,
              name: 'RO Membranes',
              slug: 'ro-membranes',
            ),
          ],
          attributes: {
            'Filter Type': 'Reverse Osmosis',
            'Production Rate': '75 GPD',
            'Rejection Rate': '96%+ TDS reduction',
            'Operating Pressure': '40-100 PSI',
          },
          weight: 0.3,
          dimensions: {'length': '12', 'width': '2', 'height': '2'},
          updatedAt: DateTime.now(),
          featured: true,
          averageRating: 4.8,
          ratingCount: 67,
        ),
        ProductCache(
          wooProductId: 1004,
          name: 'UV Sterilization Lamp - 12 GPM',
          slug: 'uv-lamp-12gpm',
          shortDescription: 'UV lamp for water sterilization, 12 GPM flow rate',
          sku: 'UV-LAMP-12GPM',
          price: 125.00,
          inStock: true,
          stockQuantity: 25,
          manageStock: true,
          status: ProductCacheStatus.active,
          images: [
            ProductCacheImage(
              src: 'https://via.placeholder.com/400x400/9C27B0/FFFFFF?text=UV+Lamp',
              alt: 'UV Sterilization Lamp',
              position: 1,
            ),
          ],
          categories: [
            ProductCacheCategory(
              id: 14,
              name: 'UV Systems',
              slug: 'uv-systems',
            ),
            ProductCacheCategory(
              id: 15,
              name: 'Sterilization',
              slug: 'sterilization',
            ),
          ],
          attributes: {
            'Filter Type': 'UV Sterilization',
            'Flow Rate': '12 GPM',
            'Lamp Life': '9000 hours',
            'Power': '40 Watts',
          },
          weight: 2.5,
          dimensions: {'length': '24', 'width': '4', 'height': '4'},
          updatedAt: DateTime.now(),
          featured: false,
          averageRating: 4.6,
          ratingCount: 18,
        ),
        ProductCache(
          wooProductId: 1005,
          name: 'Water Filter Housing - 10" Standard',
          slug: 'filter-housing-10inch',
          shortDescription: 'Standard 10-inch filter housing for cartridge replacement',
          sku: 'HOUSING-10STD',
          price: 45.00,
          inStock: true,
          stockQuantity: 67,
          manageStock: true,
          status: ProductCacheStatus.active,
          images: [
            ProductCacheImage(
              src: 'https://via.placeholder.com/400x400/607D8B/FFFFFF?text=Filter+Housing',
              alt: 'Filter Housing 10 inch',
              position: 1,
            ),
          ],
          categories: [
            ProductCacheCategory(
              id: 16,
              name: 'System Components',
              slug: 'system-components',
            ),
            ProductCacheCategory(
              id: 17,
              name: 'Housings',
              slug: 'housings',
            ),
          ],
          attributes: {
            'Size': '10 inch standard',
            'Material': 'High-grade plastic',
            'Pressure Rating': '125 PSI',
            'Connection': '3/4" NPT',
          },
          weight: 1.2,
          dimensions: {'length': '12', 'width': '5', 'height': '5'},
          updatedAt: DateTime.now(),
          featured: false,
          averageRating: 4.4,
          ratingCount: 31,
        ),
      ];

      // Store each product in Firestore
      for (final product in demoProducts) {
        await _firestore
            .collection('products_cache')
            .doc(product.id)
            .set(product.toMap());

        print('DemoDataInitializer: Created product ${product.name}');
      }

      print('DemoDataInitializer: Created ${demoProducts.length} demo products');
    } catch (e) {
      print('DemoDataInitializer: Error creating demo product cache: $e');
    }
  }

  /// Create demo user profile
  static Future<void> _createDemoUserProfile(User user) async {
    try {
      print('DemoDataInitializer: Creating demo user profile...');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: 'Demo Admin',
          phoneNumber: '+1234567890',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          role: UserRole.admin,
          servicePreferences: ServicePreferences(
            preferredTimeSlots: ['9:00-12:00', '13:00-17:00'],
            availableDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
            emailReminders: true,
            smsReminders: false,
            pushNotifications: true,
            reminderDaysBefore: 7,
            preferredContactMethod: 'email',
            specialInstructions: 'Demo admin account',
          ),
          loyalty: LoyaltyInfo(
            points: 0,
            tier: 'Bronze',
          ),
          marketingConsent: false,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());

        print('DemoDataInitializer: Created user profile for ${user.email}');
      } else {
        print('DemoDataInitializer: User profile already exists');
      }
    } catch (e) {
      print('DemoDataInitializer: Error creating demo user profile: $e');
    }
  }

  /// Create demo service profiles
  static Future<void> _createDemoServiceProfiles(String userId) async {
    try {
      print('DemoDataInitializer: Creating demo service profiles...');

      final demoProfiles = [
        ServiceProfile(
          id: _config.generateDemoId('profile'),
          userId: userId,
          addressId: _config.generateDemoId('address'),
          addressLabel: 'Home - Kitchen',
          installedAt: DateTime.now().subtract(const Duration(days: 180)),
          isActive: true,
          system: WaterFilterSystem(
            type: SystemType.underSink,
            brand: 'AquaPure',
            model: 'AP-3000',
            serial: 'AP3K-2024-001',
            components: [
              ServiceComponent(
                type: ServiceComponentType.sediment,
                name: 'Sediment Pre-Filter',
                sku: 'SED-FILTER-5M',
                intervalDays: 180,
                lastChangedAt: DateTime.now().subtract(const Duration(days: 60)),
                notes: 'Standard 5-micron sediment filter for pre-filtration',
              ),
              ServiceComponent(
                type: ServiceComponentType.carbon,
                name: 'Carbon Block Filter',
                sku: 'CARBON-BLOCK-CHL',
                intervalDays: 180,
                lastChangedAt: DateTime.now().subtract(const Duration(days: 60)),
                notes: 'Chlorine and taste/odor removal filter',
              ),
            ],
            notes: 'Installed under kitchen sink with dedicated faucet',
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 180)),
          updatedAt: DateTime.now(),
        ),
        ServiceProfile(
          id: _config.generateDemoId('profile'),
          userId: userId,
          addressId: _config.generateDemoId('address'),
          addressLabel: 'Home - Whole House',
          installedAt: DateTime.now().subtract(const Duration(days: 365)),
          isActive: true,
          system: WaterFilterSystem(
            type: SystemType.wholehouse,
            brand: 'PureTech',
            model: 'WH-5000',
            serial: 'WH5K-2023-042',
            components: [
              ServiceComponent(
                type: ServiceComponentType.sediment,
                name: 'Whole House Sediment Filter',
                sku: 'SED-FILTER-5M',
                intervalDays: 180,
                lastChangedAt: DateTime.now().subtract(const Duration(days: 90)),
                notes: 'Large capacity sediment filter for whole house protection',
              ),
              ServiceComponent(
                type: ServiceComponentType.carbon,
                name: 'Whole House Carbon Filter',
                sku: 'CARBON-BLOCK-CHL',
                intervalDays: 180,
                lastChangedAt: DateTime.now().subtract(const Duration(days: 90)),
                notes: 'Whole house chlorine removal system',
              ),
              ServiceComponent(
                type: ServiceComponentType.membrane,
                name: 'RO Membrane System',
                sku: 'RO-MEM-75GPD',
                intervalDays: 365,
                lastChangedAt: DateTime.now().subtract(const Duration(days: 180)),
                notes: 'Reverse osmosis membrane for water purification',
              ),
            ],
            notes: 'Main water line filtration system in utility room',
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 365)),
          updatedAt: DateTime.now(),
        ),
      ];

      // Store each service profile
      for (final profile in demoProfiles) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('service_profiles')
            .doc(profile.id)
            .set(profile.toMap());

        print('DemoDataInitializer: Created service profile ${profile.addressLabel}');
      }

      print('DemoDataInitializer: Created ${demoProfiles.length} demo service profiles');
    } catch (e) {
      print('DemoDataInitializer: Error creating demo service profiles: $e');
    }
  }

  /// Clear all demo data (for testing purposes)
  static Future<void> clearAllDemoData() async {
    try {
      print('DemoDataInitializer: Clearing all demo data...');

      // Clear product cache
      final productDocs = await _firestore.collection('products_cache').get();
      for (final doc in productDocs.docs) {
        await doc.reference.delete();
      }

      // Note: We don't clear user data or service profiles in this method
      // as they might contain real data

      print('DemoDataInitializer: Demo data cleared successfully');
    } catch (e) {
      print('DemoDataInitializer: Error clearing demo data: $e');
    }
  }
}