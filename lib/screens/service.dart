import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../widgets/buttons/primary_button.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({Key? key}) : super(key: key);

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = false;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'EUR';
  double _filterLifeReminder = 6.0; // months

  final List<String> _languages = ['English', 'Greek', 'German', 'French', 'Spanish'];
  final List<String> _currencies = ['EUR', 'USD', 'GBP', 'CHF'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralGray50,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.neutralGray900,
            title: const Text(
              'Services & Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showResetDialog();
                },
                icon: const Icon(Icons.refresh_outlined),
                tooltip: 'Reset All Settings',
              ),
            ],
          ),

          // Service Status
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(AppSizing.paddingLarge),
              padding: const EdgeInsets.all(AppSizing.paddingLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryTeal.withOpacity(0.1),
                    AppTheme.successGreen.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
                border: Border.all(
                  color: AppTheme.primaryTeal.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen,
                          borderRadius: BorderRadius.circular(AppSizing.radiusMedium),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSizing.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'All Systems Operational',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.neutralGray900,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              'Last updated: ${DateTime.now().toLocal().toString().substring(0, 16)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.neutralGray600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizing.paddingMedium),
                  const Text(
                    'Your water filtration system is working perfectly. All filters are functioning optimally.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.neutralGray700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter Management
          SliverToBoxAdapter(
            child: _buildServiceSection(
              'Filter Management',
              [
                _buildServiceTile(
                  icon: Icons.water_drop_outlined,
                  iconColor: AppTheme.primaryTeal,
                  title: 'Filter Status',
                  subtitle: 'Check current filter conditions',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSizing.radiusSmall),
                    ),
                    child: const Text(
                      'Good',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ),
                  onTap: () => _showFilterStatusDialog(),
                ),
                _buildServiceTile(
                  icon: Icons.schedule_outlined,
                  iconColor: AppTheme.warningAmber,
                  title: 'Filter Replacement Reminder',
                  subtitle: 'Set reminder for filter changes',
                  trailing: Text(
                    '${_filterLifeReminder.toInt()} months',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutralGray700,
                    ),
                  ),
                  onTap: () => _showReminderDialog(),
                ),
                _buildServiceTile(
                  icon: Icons.shopping_cart_outlined,
                  iconColor: AppTheme.primaryTeal,
                  title: 'Order Replacement Filters',
                  subtitle: 'Quick reorder your filter supplies',
                  onTap: () => _navigateToFilterShop(),
                ),
              ],
            ),
          ),

          // System Services
          SliverToBoxAdapter(
            child: _buildServiceSection(
              'System Services',
              [
                _buildServiceTile(
                  icon: Icons.build_outlined,
                  iconColor: AppTheme.primaryTeal,
                  title: 'Schedule Maintenance',
                  subtitle: 'Book professional service visit',
                  onTap: () => _showMaintenanceDialog(),
                ),
                _buildServiceTile(
                  icon: Icons.analytics_outlined,
                  iconColor: AppTheme.secondaryBlue,
                  title: 'Water Quality Report',
                  subtitle: 'View detailed water analysis',
                  onTap: () => _showWaterQualityDialog(),
                ),
                _buildServiceTile(
                  icon: Icons.support_agent_outlined,
                  iconColor: AppTheme.successGreen,
                  title: 'Technical Support',
                  subtitle: '24/7 expert assistance available',
                  onTap: () => _contactSupport(),
                ),
                _buildServiceTile(
                  icon: Icons.video_library_outlined,
                  iconColor: AppTheme.warningAmber,
                  title: 'Installation Guide',
                  subtitle: 'Step-by-step video tutorials',
                  onTap: () => _openInstallationGuide(),
                ),
              ],
            ),
          ),

          // App Settings
          SliverToBoxAdapter(
            child: _buildServiceSection(
              'App Preferences',
              [
                _buildSwitchTile(
                  icon: Icons.notifications_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Get alerts for filter changes and updates',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                    HapticFeedback.lightImpact();
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.email_outlined,
                  title: 'Email Notifications',
                  subtitle: 'Receive maintenance reminders via email',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                    HapticFeedback.lightImpact();
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: 'Switch to dark theme (Coming Soon)',
                  value: _darkModeEnabled,
                  enabled: false,
                  onChanged: (value) {
                    // setState(() {
                    //   _darkModeEnabled = value;
                    // });
                  },
                ),
                _buildDropdownTile(
                  icon: Icons.language_outlined,
                  title: 'Language',
                  subtitle: 'Select your preferred language',
                  value: _selectedLanguage,
                  options: _languages,
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                    HapticFeedback.lightImpact();
                  },
                ),
                _buildDropdownTile(
                  icon: Icons.euro_outlined,
                  title: 'Currency',
                  subtitle: 'Display prices in your currency',
                  value: _selectedCurrency,
                  options: _currencies,
                  onChanged: (value) {
                    setState(() {
                      _selectedCurrency = value!;
                    });
                    HapticFeedback.lightImpact();
                  },
                ),
              ],
            ),
          ),

          // About & Legal
          SliverToBoxAdapter(
            child: _buildServiceSection(
              'About & Legal',
              [
                _buildServiceTile(
                  icon: Icons.info_outline,
                  iconColor: AppTheme.secondaryBlue,
                  title: 'App Version',
                  subtitle: 'WaterFilterNet v2.1.0',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSizing.radiusSmall),
                    ),
                    child: const Text(
                      'Latest',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ),
                  onTap: () => _checkForUpdates(),
                ),
                _buildServiceTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: AppTheme.neutralGray700,
                  title: 'Privacy Policy',
                  subtitle: 'How we protect your data',
                  onTap: () => _openPrivacyPolicy(),
                ),
                _buildServiceTile(
                  icon: Icons.gavel_outlined,
                  iconColor: AppTheme.neutralGray700,
                  title: 'Terms of Service',
                  subtitle: 'Legal terms and conditions',
                  onTap: () => _openTermsOfService(),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSizing.paddingXXLarge),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSection(String title, List<Widget> children) {
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
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutralGray900,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildServiceTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSizing.paddingSmall),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryTeal).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizing.radiusSmall),
        ),
        child: Icon(
          icon,
          size: AppSizing.iconMedium,
          color: iconColor ?? AppTheme.primaryTeal,
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
      trailing: trailing ?? const Icon(
        Icons.chevron_right,
        color: AppTheme.neutralGray400,
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizing.paddingLarge,
        vertical: AppSizing.paddingSmall,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool enabled = true,
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
          color: enabled ? AppTheme.primaryTeal : AppTheme.neutralGray400,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: enabled ? AppTheme.neutralGray900 : AppTheme.neutralGray400,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: enabled ? AppTheme.neutralGray600 : AppTheme.neutralGray400,
          fontFamily: 'Poppins',
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: AppTheme.primaryTeal,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizing.paddingLarge,
        vertical: AppSizing.paddingSmall,
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
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
          color: AppTheme.neutralGray600,
          fontFamily: 'Poppins',
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(
              option,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          );
        }).toList(),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizing.paddingLarge,
        vertical: AppSizing.paddingSmall,
      ),
    );
  }

  // Dialog Methods
  void _showFilterStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusItem('Primary Filter', 'Good', AppTheme.successGreen),
            _buildStatusItem('Carbon Filter', 'Replace Soon', AppTheme.warningAmber),
            _buildStatusItem('UV Sterilizer', 'Excellent', AppTheme.successGreen),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String name, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppSizing.radiusSmall),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Replacement Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set reminder interval for filter replacement:'),
            const SizedBox(height: 16),
            Slider(
              value: _filterLifeReminder,
              min: 1,
              max: 12,
              divisions: 11,
              label: '${_filterLifeReminder.toInt()} months',
              onChanged: (value) {
                setState(() {
                  _filterLifeReminder = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            text: 'Save',
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reminder set for ${_filterLifeReminder.toInt()} months'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  void _showMaintenanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Maintenance'),
        content: const Text(
          'Our certified technicians are available for professional maintenance visits. Would you like to schedule a service?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          PrimaryButton(
            text: 'Schedule',
            onPressed: () {
              Navigator.pop(context);
              _contactSupport();
            },
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  void _showWaterQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Water Quality Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Latest Analysis Results:'),
            const SizedBox(height: 12),
            _buildQualityItem('pH Level', '7.2', 'Optimal'),
            _buildQualityItem('TDS', '45 ppm', 'Excellent'),
            _buildQualityItem('Chlorine', '0.1 mg/L', 'Safe'),
            _buildQualityItem('Heavy Metals', 'Not Detected', 'Safe'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          PrimaryButton(
            text: 'Full Report',
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to detailed report
            },
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  Widget _buildQualityItem(String parameter, String value, String status) {
    Color statusColor = AppTheme.successGreen;
    if (status == 'Warning') statusColor = AppTheme.warningAmber;
    if (status == 'Critical') statusColor = AppTheme.errorRed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(parameter, style: const TextStyle(fontSize: 14)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                status,
                style: TextStyle(fontSize: 12, color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            text: 'Reset',
            onPressed: () {
              Navigator.pop(context);
              _resetAllSettings();
            },
            size: ButtonSize.small,
            variant: ButtonVariant.secondary,
          ),
        ],
      ),
    );
  }

  // Action Methods
  void _navigateToFilterShop() {
    // Navigate to shop tab with filter category
    Navigator.of(context).popUntil((route) => route.isFirst);
    // TODO: Navigate to specific filter category
  }

  void _contactSupport() async {
    const phoneNumber = 'tel:+302101234567';
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
    }
  }

  void _openInstallationGuide() async {
    const url = 'https://waterfilternet.com/installation-guide';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _checkForUpdates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have the latest version!'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  void _openPrivacyPolicy() async {
    const url = 'https://waterfilternet.com/privacy-policy';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _openTermsOfService() async {
    const url = 'https://waterfilternet.com/terms-of-service';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _resetAllSettings() {
    setState(() {
      _notificationsEnabled = true;
      _emailNotifications = true;
      _pushNotifications = false;
      _darkModeEnabled = false;
      _selectedLanguage = 'English';
      _selectedCurrency = 'EUR';
      _filterLifeReminder = 6.0;
    });

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All settings have been reset to defaults'),
        backgroundColor: AppTheme.neutralGray700,
      ),
    );
  }
}