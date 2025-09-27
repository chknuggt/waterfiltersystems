import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waterfilternet/core/theme/app_theme.dart';
import 'package:waterfilternet/widgets/buttons/primary_button.dart';
import 'package:waterfilternet/widgets/common/section_header.dart';
import '../../providers/auth_provider.dart';
import '../service.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onBackToPreviousTab;

  const ProfilePage({Key? key, this.onBackToPreviousTab}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  Future<void> _signOut(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show confirmation dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Sign Out',
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        await authProvider.signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    return Scaffold(
      backgroundColor: AppTheme.neutralGray50,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: false,
            pinned: false,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.neutralGray900,
            automaticallyImplyLeading: false,
            title: const Text(
              'Account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ServiceScreen()),
                  );
                },
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
              ),
            ],
          ),

          // Profile Header
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(
                AppSizing.paddingLarge,
                0,
                AppSizing.paddingLarge,
                AppSizing.paddingXLarge,
              ),
              child: Column(
                children: [
                  // Profile Picture and Info
                  Row(
                    children: [
                      // Profile Picture
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryTeal.withOpacity(0.1),
                          border: Border.all(
                            color: AppTheme.primaryTeal.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: AppTheme.primaryTeal,
                        ),
                      ),

                      const SizedBox(width: AppSizing.paddingLarge),

                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Guest User',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? 'No email',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.neutralGray600,
                              ),
                            ),
                            const SizedBox(height: AppSizing.paddingSmall),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizing.paddingMedium,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppSizing.radiusSmall),
                              ),
                              child: const Text(
                                'Premium Member',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryTeal,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Edit Button
                      AppIconButton(
                        onPressed: () {
                          // TODO: Edit profile
                        },
                        icon: Icons.edit_outlined,
                        variant: ButtonVariant.outline,
                        tooltip: 'Edit Profile',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Quick Stats
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(AppSizing.paddingLarge),
              padding: const EdgeInsets.all(AppSizing.paddingLarge),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Orders', '12'),
                  _buildStatDivider(),
                  _buildStatItem('Wishlist', '5'),
                  _buildStatDivider(),
                  _buildStatItem('Reviews', '8'),
                ],
              ),
            ),
          ),

          // Menu Options
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildMenuSection('Order & Shopping', [
                  _buildMenuTile(
                    icon: Icons.shopping_bag_outlined,
                    title: 'My Orders',
                    subtitle: 'Track your orders',
                    onTap: () {},
                  ),
                  _buildMenuTile(
                    icon: Icons.favorite_outline,
                    title: 'Wishlist',
                    subtitle: 'Your saved products',
                    onTap: () {},
                  ),
                  _buildMenuTile(
                    icon: Icons.location_on_outlined,
                    title: 'Addresses',
                    subtitle: 'Manage delivery addresses',
                    onTap: () => Navigator.of(context).pushNamed('/address_management'),
                  ),
                ]),

                _buildMenuSection('Account', [
                  _buildMenuTile(
                    icon: Icons.payment_outlined,
                    title: 'Payment Methods',
                    subtitle: 'Manage cards and wallets',
                    onTap: () => Navigator.of(context).pushNamed('/card_management'),
                  ),
                  _buildMenuTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage your alerts',
                    onTap: () {},
                  ),
                  _buildMenuTile(
                    icon: Icons.security_outlined,
                    title: 'Privacy & Security',
                    subtitle: 'Password and privacy settings',
                    onTap: () {},
                  ),
                ]),

                _buildMenuSection('Support', [
                  _buildMenuTile(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    subtitle: 'FAQs and support',
                    onTap: () {},
                  ),
                  _buildMenuTile(
                    icon: Icons.chat_bubble_outline,
                    title: 'Contact Us',
                    subtitle: 'Get in touch with support',
                    onTap: () {},
                  ),
                  _buildMenuTile(
                    icon: Icons.star_outline,
                    title: 'Rate App',
                    subtitle: 'Share your feedback',
                    onTap: () {},
                  ),
                ]),

                // Logout Button
                Container(
                  margin: const EdgeInsets.all(AppSizing.paddingLarge),
                  child: PrimaryButton(
                    text: 'Sign Out',
                    onPressed: () => _signOut(context),
                    variant: ButtonVariant.outline,
                    fullWidth: true,
                    icon: Icons.logout,
                  ),
                ),

                const SizedBox(height: AppSizing.paddingXXLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryTeal,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.neutralGray600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppTheme.neutralGray200,
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSizing.paddingLarge,
        0,
        AppSizing.paddingLarge,
        AppSizing.paddingLarge,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neutralGray300.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizing.paddingLarge,
              AppSizing.paddingLarge,
              AppSizing.paddingLarge,
              AppSizing.paddingMedium,
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutralGray900,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSizing.paddingSmall),
        decoration: BoxDecoration(
          color: AppTheme.neutralGray100,
          borderRadius: BorderRadius.circular(AppSizing.radiusSmall),
        ),
        child: Icon(
          icon,
          size: AppSizing.iconMedium,
          color: AppTheme.neutralGray700,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.neutralGray900,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.neutralGray600,
          fontFamily: 'Poppins',
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.neutralGray400,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizing.paddingLarge,
        vertical: AppSizing.paddingSmall,
      ),
    );
  }

}
