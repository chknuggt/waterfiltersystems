import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:waterfilternet/core/navigation/app_bar_navigation.dart';

class ServicesPage extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const ServicesPage({Key? key, this.onBackPressed}) : super(key: key);

  @override
  _ServicesPageState createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Water Filter',
      'icon': 'assets/icons/waterFilter.svg',
      'serviceDueDays': 180,
    },
    {
      'name': 'Reverse Osmosis',
      'icon': 'assets/icons/reverseOsmosis.svg',
      'serviceDueDays': 365,
    },
  ];

  final List<Map<String, String>> _services = [];
  String? _selectedCategory;
  DateTime? _installationDate;

  void _addService() {
    if (_selectedCategory == null || _installationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final selectedCategoryDetails = _categories.firstWhere(
      (category) => category['name'] == _selectedCategory,
    );
    final int serviceDueDays = selectedCategoryDetails['serviceDueDays'];

    final DateTime nextServiceDate = _installationDate!.add(
      Duration(days: serviceDueDays),
    );
    final String formattedInstallationDate = DateFormat(
      'dd/MM/yyyy',
    ).format(_installationDate!);
    final String formattedNextServiceDate = DateFormat(
      'dd/MM/yyyy',
    ).format(nextServiceDate);

    if (mounted) {
      setState(() {
        _services.add({
          'category': _selectedCategory!,
          'dateAdded': formattedInstallationDate,
          'nextService': formattedNextServiceDate,
        });
      });
    }

    _selectedCategory = null;
    _installationDate = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavigationUpMenu(
        title: 'Services',
        onBackPressed: widget.onBackPressed,
        onActionPressed: () {
          print('Action button pressed');
        },
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Select a Category:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        _categories.map((category) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category['name'];
                              });
                            },
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Container(
                                width: 120,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      _selectedCategory == category['name']
                                          ? Colors.blueAccent.withOpacity(0.2)
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      category['icon']!,
                                      width: 50,
                                      height: 50,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      category['name']!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            _selectedCategory ==
                                                    category['name']
                                                ? Colors.blueAccent
                                                : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Installation Date:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _installationDate = pickedDate;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      _installationDate == null
                          ? 'Select Installation Date'
                          : DateFormat('dd/MM/yyyy').format(_installationDate!),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addService,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Add Service',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                if (_services.isNotEmpty)
                  const Text(
                    'Added Services:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: SvgPicture.asset(
                          _categories.firstWhere(
                            (category) =>
                                category['name'] == service['category'],
                          )['icon']!,
                          width: 40,
                          height: 40,
                        ),
                        title: Text(
                          service['category']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date Added: ${service['dateAdded']}'),
                            Text('Next Service Due: ${service['nextService']}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
