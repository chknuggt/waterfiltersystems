import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:waterfilternet/core/theme/app_theme.dart';
import 'package:waterfilternet/widgets/buttons/primary_button.dart';
import 'package:waterfilternet/widgets/common/section_header.dart';
import 'package:waterfilternet/widgets/dialogs/change_email_dialog.dart';
import 'package:waterfilternet/widgets/dialogs/change_password_dialog.dart';
import 'package:waterfilternet/utils/demo_data_initializer.dart';
import 'package:waterfilternet/models/user_model.dart';
import 'package:waterfilternet/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool locationEnabled = true;
  bool marketingEmails = false;
  String selectedLanguage = 'English';
  String selectedCurrency = 'EUR (€)';
  bool _isInitializingDemoData = false;
  bool _isAdmin = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _refreshAdminStatusAndCheckAdmin();
  }

  Future<void> _refreshAdminStatusAndCheckAdmin() async {
    try {
      // Force refresh the authentication token to get latest custom claims
      await _authService.refreshUserToken();

      // Wait a moment for token to refresh
      await Future.delayed(const Duration(milliseconds: 500));

      final isAdmin = await _authService.isCurrentUserAdmin();
      setState(() {
        _isAdmin = isAdmin;
      });

      print('Admin status refreshed: $_isAdmin');
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await _authService.isCurrentUserAdmin();
      setState(() {
        _isAdmin = isAdmin;
      });
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  _showResetDialog();
                },
                icon: const Icon(Icons.restore_outlined),
                tooltip: 'Reset Settings',
              ),
            ],
          ),

          // Settings Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: AppSizing.paddingMedium),

                // App Preferences
                _buildSettingsSection(
                  'App Preferences',
                  [
                    _buildSwitchTile(
                      icon: Icons.notifications_outlined,
                      title: 'Push Notifications',
                      subtitle: 'Get notified about orders and updates',
                      value: notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          notificationsEnabled = value;
                        });
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      subtitle: 'Switch to dark theme',
                      value: darkModeEnabled,
                      onChanged: (value) {
                        setState(() {
                          darkModeEnabled = value;
                        });
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.location_on_outlined,
                      title: 'Location Services',
                      subtitle: 'Help us find nearby stores',
                      value: locationEnabled,
                      onChanged: (value) {
                        setState(() {
                          locationEnabled = value;
                        });
                      },
                    ),
                  ],
                ),

                // Shopping & Orders
                _buildSettingsSection(
                  'Shopping & Orders',
                  [
                    _buildSelectTile(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: selectedLanguage,
                      onTap: () => _showLanguageDialog(),
                    ),
                    _buildSelectTile(
                      icon: Icons.euro_outlined,
                      title: 'Currency',
                      subtitle: selectedCurrency,
                      onTap: () => _showCurrencyDialog(),
                    ),
                    _buildNavigationTile(
                      icon: Icons.local_shipping_outlined,
                      title: 'Shipping Addresses',
                      subtitle: 'Manage your delivery addresses',
                      onTap: () {
                        // TODO: Navigate to addresses
                      },
                    ),
                    _buildNavigationTile(
                      icon: Icons.payment_outlined,
                      title: 'Payment Methods',
                      subtitle: 'Manage cards and payment options',
                      onTap: () {
                        // TODO: Navigate to payment methods
                      },
                    ),
                  ],
                ),

                // Privacy & Security
                _buildSettingsSection(
                  'Privacy & Security',
                  [
                    _buildNavigationTile(
                      icon: Icons.email_outlined,
                      title: 'Change Email',
                      subtitle: 'Update your email address',
                      onTap: _showChangeEmailDialog,
                    ),
                    _buildNavigationTile(
                      icon: Icons.security_outlined,
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      onTap: _showChangePasswordDialog,
                    ),
                    _buildNavigationTile(
                      icon: Icons.fingerprint_outlined,
                      title: 'Biometric Authentication',
                      subtitle: 'Use fingerprint or face unlock',
                      onTap: () {
                        // TODO: Navigate to biometric settings
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.email_outlined,
                      title: 'Marketing Emails',
                      subtitle: 'Receive promotional offers',
                      value: marketingEmails,
                      onChanged: (value) {
                        setState(() {
                          marketingEmails = value;
                        });
                      },
                    ),
                    _buildNavigationTile(
                      icon: Icons.refresh_outlined,
                      title: 'Refresh Admin Status',
                      subtitle: 'Update admin permissions if recently changed',
                      onTap: _refreshAdminStatus,
                    ),
                    _buildNavigationTile(
                      icon: Icons.bug_report_outlined,
                      title: 'Debug Claims',
                      subtitle: 'Show all Firebase custom claims for debugging',
                      onTap: _debugClaims,
                    ),
                    _buildNavigationTile(
                      icon: Icons.logout_outlined,
                      title: 'Force Logout & Login',
                      subtitle: 'Complete logout to get fresh token',
                      onTap: _forceLogout,
                    ),
                    _buildNavigationTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'Read our privacy policy',
                      onTap: () {
                        // TODO: Navigate to privacy policy
                      },
                    ),
                  ],
                ),

                // App Information
                _buildSettingsSection(
                  'App Information',
                  [
                    _buildNavigationTile(
                      icon: Icons.info_outline,
                      title: 'About WaterFilterNet',
                      subtitle: 'Version 1.0.0',
                      onTap: () => _showAboutDialog(),
                    ),
                    _buildNavigationTile(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      subtitle: 'Read our terms and conditions',
                      onTap: () {
                        // TODO: Navigate to terms
                      },
                    ),
                    _buildNavigationTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Get help with your account',
                      onTap: () {
                        // TODO: Navigate to help
                      },
                    ),
                    _buildNavigationTile(
                      icon: Icons.star_outline,
                      title: 'Rate Our App',
                      subtitle: 'Share your feedback on app stores',
                      onTap: () {
                        // TODO: Open app store rating
                      },
                    ),
                  ],
                ),

                // Admin Section (only visible to admins)
                if (_isAdmin) ...[
                  _buildSettingsSection(
                    'Admin Tools',
                    [
                      _buildNavigationTile(
                        icon: Icons.add_to_photos_outlined,
                        title: 'Initialize Demo Data',
                        subtitle: _isInitializingDemoData
                            ? 'Creating demo data...'
                            : 'Create sample products and service profiles',
                        onTap: _isInitializingDemoData ? () {} : _initializeDemoData,
                      ),
                      _buildNavigationTile(
                        icon: Icons.cleaning_services_outlined,
                        title: 'Clear Demo Data',
                        subtitle: 'Remove all demo data from database',
                        onTap: _clearDemoData,
                      ),
                      _buildNavigationTile(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Admin Dashboard',
                        subtitle: 'Access admin management tools',
                        onTap: () {
                          Navigator.pushNamed(context, '/admin');
                        },
                      ),
                    ],
                  ),
                ],

                // Data Management
                _buildSettingsSection(
                  'Data Management',
                  [
                    _buildNavigationTile(
                      icon: Icons.cloud_download_outlined,
                      title: 'Export Data',
                      subtitle: 'Download your account data',
                      onTap: () {
                        // TODO: Export data
                      },
                    ),
                    _buildDangerTile(
                      icon: Icons.delete_forever_outlined,
                      title: 'Delete Account',
                      subtitle: 'Permanently delete your account',
                      onTap: () => _showDeleteAccountDialog(),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizing.paddingXXLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
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
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryTeal,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizing.paddingLarge,
        vertical: AppSizing.paddingSmall,
      ),
    );
  }

  Widget _buildNavigationTile({
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

  Widget _buildSelectTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSizing.paddingSmall),
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizing.radiusSmall),
        ),
        child: Icon(
          icon,
          size: AppSizing.iconMedium,
          color: AppTheme.primaryTeal,
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
          color: AppTheme.primaryTeal,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.primaryTeal,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizing.paddingLarge,
        vertical: AppSizing.paddingSmall,
      ),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSizing.paddingSmall),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizing.radiusSmall),
        ),
        child: Icon(
          icon,
          size: AppSizing.iconMedium,
          color: AppTheme.errorRed,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.errorRed,
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
        color: AppTheme.errorRed,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizing.paddingLarge,
        vertical: AppSizing.paddingSmall,
      ),
    );
  }

  void _showLanguageDialog() {
    final languages = ['English', 'Greek', 'German', 'French', 'Spanish'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Select Language',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((language) => ListTile(
            title: Text(
              language,
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            leading: Radio<String>(
              value: language,
              groupValue: selectedLanguage,
              activeColor: AppTheme.primaryTeal,
              onChanged: (value) {
                setState(() {
                  selectedLanguage = value!;
                });
                Navigator.pop(context);
              },
            ),
          )).toList(),
        ),
      ),
    );
  }

  void _showCurrencyDialog() {
    final currencies = ['EUR (€)', 'USD (\$)', 'GBP (£)', 'JPY (¥)'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Select Currency',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((currency) => ListTile(
            title: Text(
              currency,
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            leading: Radio<String>(
              value: currency,
              groupValue: selectedCurrency,
              activeColor: AppTheme.primaryTeal,
              onChanged: (value) {
                setState(() {
                  selectedCurrency = value!;
                });
                Navigator.pop(context);
              },
            ),
          )).toList(),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'About WaterFilterNet',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'WaterFilterNet is your trusted source for high-quality water filtration solutions. We provide everything you need for clean, safe, and great-tasting water.\n\nVersion: 1.0.0\nBuild: 2024.001',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
        ),
        actions: [
          PrimaryButton(
            text: 'OK',
            onPressed: () => Navigator.pop(context),
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Reset Settings',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            text: 'Reset',
            onPressed: () {
              setState(() {
                notificationsEnabled = true;
                darkModeEnabled = false;
                locationEnabled = true;
                marketingEmails = false;
                selectedLanguage = 'English';
                selectedCurrency = 'EUR (€)';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            size: ButtonSize.small,
            variant: ButtonVariant.secondary,
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: AppTheme.errorRed,
          ),
        ),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.\n\nAre you sure you want to continue?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            text: 'Delete',
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                // Delete the account
                await _authService.deleteAccount();

                // Close loading dialog
                if (mounted) Navigator.pop(context);

                // Navigate to login screen
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account successfully deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                // Close loading dialog
                if (mounted) Navigator.pop(context);

                // Show error
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            size: ButtonSize.small,
            variant: ButtonVariant.outline,
          ),
        ],
      ),
    );
  }

  Future<void> _initializeDemoData() async {
    setState(() {
      _isInitializingDemoData = true;
    });

    try {
      await DemoDataInitializer.initializeAllDemoData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo data initialized successfully!'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error initializing demo data: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing demo data: $e'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializingDemoData = false;
        });
      }
    }
  }

  Future<void> _clearDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Clear Demo Data',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: AppTheme.errorRed,
          ),
        ),
        content: const Text(
          'This will remove all demo products and cached data from the database. This action cannot be undone.\n\nAre you sure you want to continue?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            text: 'Clear Data',
            onPressed: () => Navigator.pop(context, true),
            size: ButtonSize.small,
            variant: ButtonVariant.outline,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DemoDataInitializer.clearAllDemoData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demo data cleared successfully'),
              backgroundColor: AppTheme.successGreen,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('Error clearing demo data: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing demo data: $e'),
              backgroundColor: AppTheme.errorRed,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  // Professional email and password change methods
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  void _showChangeEmailDialog() {
    final currentUser = _authService.currentUser;
    if (currentUser?.email != null) {
      showDialog(
        context: context,
        builder: (context) => ChangeEmailDialog(
          currentEmail: currentUser!.email!,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get current email address'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _refreshAdminStatus() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refreshing admin status...'),
          backgroundColor: AppTheme.primaryTeal,
          duration: Duration(seconds: 2),
        ),
      );

      await _refreshAdminStatusAndCheckAdmin();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isAdmin
                ? 'Admin access confirmed! ✅'
                : 'No admin access found'),
            backgroundColor: _isAdmin
                ? AppTheme.successGreen
                : AppTheme.neutralGray600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing admin status: $e'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _debugClaims() async {
    try {
      await _authService.debugPrintAllClaims();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debug info printed to console'),
            backgroundColor: AppTheme.primaryTeal,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug error: $e'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _forceLogout() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Force Logout',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'This will log you out completely. You\'ll need to login again with mariosano333@gmail.com to get a fresh token with admin claims.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            PrimaryButton(
              text: 'Logout',
              onPressed: () => Navigator.pop(context, true),
              size: ButtonSize.small,
              variant: ButtonVariant.secondary,
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _authService.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully. Please login again.'),
              backgroundColor: AppTheme.successGreen,
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate to auth screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/auth',
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout error: $e'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}