import 'package:flutter/material.dart';
import 'package:waterfilternet/core/theme/app_theme.dart';
import 'package:waterfilternet/models/shipping_address.dart';
import 'package:waterfilternet/services/address_service.dart';
import 'package:waterfilternet/widgets/buttons/primary_button.dart';
import 'package:waterfilternet/widgets/common/section_header.dart';
import 'add_edit_address_screen.dart';

class AddressManagementScreen extends StatefulWidget {
  final AddressType? filterType;
  final bool allowSelection;
  final Function(ShippingAddress)? onAddressSelected;

  const AddressManagementScreen({
    super.key,
    this.filterType,
    this.allowSelection = false,
    this.onAddressSelected,
  });

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final AddressService _addressService = AddressService();
  List<ShippingAddress> addresses = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      isLoading = true;
    });

    try {
      final loadedAddresses = await _addressService.getUserAddresses(
        type: widget.filterType,
      );

      if (mounted) {
        setState(() {
          addresses = loadedAddresses;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading addresses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddAddress() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAddressScreen(
          addressType: widget.filterType ?? AddressType.shipping,
        ),
      ),
    );

    if (result == true) {
      _loadAddresses();
    }
  }

  Future<void> _navigateToEditAddress(ShippingAddress address) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAddressScreen(
          address: address,
          addressType: address.type,
        ),
      ),
    );

    if (result == true) {
      _loadAddresses();
    }
  }

  Future<void> _setDefaultAddress(ShippingAddress address) async {
    try {
      await _addressService.setDefaultAddress(address.id, address.type);
      _loadAddresses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting default address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAddress(ShippingAddress address) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "${address.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _addressService.deleteAddress(address.id);
        _loadAddresses();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting address: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.allowSelection
              ? 'Select Address'
              : '${widget.filterType?.toString().split('.').last.toUpperCase() ?? 'ALL'} Addresses',
        ),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : addresses.isEmpty
              ? _buildEmptyState()
              : _buildAddressList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddAddress,
        backgroundColor: AppTheme.primaryTeal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 80,
            color: AppTheme.neutralGray400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No addresses found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first address to get started',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Add Address',
            onPressed: _navigateToAddAddress,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    return Column(
      children: [
        if (!widget.allowSelection) ...[
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryTeal.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryTeal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Tap an address to select it, or use the menu for more options',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAddresses,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final address = addresses[index];
                return _buildAddressCard(address);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(ShippingAddress address) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: address.isDefault
            ? BorderSide(color: AppTheme.primaryTeal, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.allowSelection
            ? () {
                widget.onAddressSelected?.call(address);
                Navigator.of(context).pop();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              address.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (address.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTeal,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'DEFAULT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address.type.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.neutralGray600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.allowSelection)
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'edit':
                            _navigateToEditAddress(address);
                            break;
                          case 'default':
                            _setDefaultAddress(address);
                            break;
                          case 'delete':
                            _deleteAddress(address);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        if (!address.isDefault)
                          const PopupMenuItem(
                            value: 'default',
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 20),
                                SizedBox(width: 8),
                                Text('Set as Default'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                address.shortAddress,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutralGray700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address.fullAddress,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutralGray600,
                ),
              ),
              if (address.phoneNumber.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  address.phoneNumber,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutralGray600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}