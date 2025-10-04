import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/admin/overview_dashboard.dart';
import '../../widgets/admin/service_requests_view.dart';
import '../../widgets/admin/calendar_view.dart';
import '../../widgets/admin/customers_view.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with AutomaticKeepAliveClientMixin {
  int _selectedIndex = 0;

  // Keep widgets alive to preserve their state
  late final List<Widget> _tabWidgets;
  late final List<Map<String, dynamic>> _tabs;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Initialize widgets once to preserve state
    _tabWidgets = [
      const OverviewDashboard(key: PageStorageKey('overview')),
      const ServiceRequestsView(key: PageStorageKey('service_requests')),
      const CalendarView(key: PageStorageKey('calendar')),
      const CustomersView(key: PageStorageKey('customers')),
    ];

    _tabs = [
      {
        'title': 'Overview',
        'icon': Icons.dashboard_outlined,
        'widget': _tabWidgets[0],
      },
      {
        'title': 'Service Requests',
        'icon': Icons.build_outlined,
        'widget': _tabWidgets[1],
      },
      {
        'title': 'Calendar',
        'icon': Icons.calendar_today_outlined,
        'widget': _tabWidgets[2],
      },
      {
        'title': 'Customers',
        'icon': Icons.people_outline,
        'widget': _tabWidgets[3],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final isDesktop = MediaQuery.of(context).size.width > 768;

    if (!isDesktop) {
      // Mobile layout with bottom navigation
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: _tabWidgets,
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: _tabs.map((tab) => NavigationDestination(
            icon: Icon(tab['icon']),
            label: tab['title'],
          )).toList(),
        ),
      );
    }

    // Desktop layout with sidebar
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 280,
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.water_drop,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'WaterFilterNet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 16),
                    itemCount: _tabs.length,
                    itemBuilder: (context, index) {
                      final tab = _tabs[index];
                      final isSelected = _selectedIndex == index;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        child: ListTile(
                          leading: Icon(
                            tab['icon'],
                            color: isSelected ? AppTheme.primaryTeal : Colors.grey[600],
                          ),
                          title: Text(
                            tab['title'],
                            style: TextStyle(
                              color: isSelected ? AppTheme.primaryTeal : Colors.grey[800],
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

                // Logout Button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red[600]),
                    title: Text(
                      'Logout',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      Navigator.of(context).pushReplacementNamed('/');
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        _tabs[_selectedIndex]['title'],
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Online',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content - Use IndexedStack to keep all tabs alive in memory
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _tabWidgets,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}