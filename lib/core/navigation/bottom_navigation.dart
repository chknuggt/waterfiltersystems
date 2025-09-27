import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/main_tabs/shop_screen.dart';
import '../../screens/main_tabs/settings_screen.dart';
import '../../screens/main_tabs/cart_screen.dart';
import '../../screens/main_tabs/profile.dart';
import '../../screens/main_tabs/qr_scan_screen.dart';
import '../../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({Key? key}) : super(key: key);

  @override
  _NavigationMenuState createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const ShopScreen(), // Shop tab
    const ProfilePage(), // Account tab
    const QrScanScreen(), // Scan tab
    const CartScreen(), // Cart tab
    const SettingsScreen(), // Settings tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: 'Shop',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
          const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Consumer<CartProvider>(
              builder: (context, cart, child) {
                if (cart.itemCount > 0) {
                  return Badge(
                    label: Text(
                      cart.itemCount > 99 ? '99+' : '${cart.itemCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: AppTheme.primaryTeal,
                    textColor: Colors.white,
                    child: const Icon(Icons.shopping_cart_outlined),
                  );
                }
                return const Icon(Icons.shopping_cart_outlined);
              },
            ),
            selectedIcon: Consumer<CartProvider>(
              builder: (context, cart, child) {
                if (cart.itemCount > 0) {
                  return Badge(
                    label: Text(
                      cart.itemCount > 99 ? '99+' : '${cart.itemCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: AppTheme.primaryTeal,
                    textColor: Colors.white,
                    child: const Icon(Icons.shopping_cart),
                  );
                }
                return const Icon(Icons.shopping_cart);
              },
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
