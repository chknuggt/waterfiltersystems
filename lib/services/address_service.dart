import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:waterfilternet/models/shipping_address.dart';

class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _addressesCollection = 'addresses';
  static const String _userAddressesCollection = 'user_addresses';

  Future<String> saveAddress({
    required String firstName,
    required String lastName,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String countryCode,
    String? phoneNumber,
    bool setAsDefault = false,
    AddressType type = AddressType.shipping,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to save an address');
    }

    try {
      final addressId = _firestore.collection(_addressesCollection).doc().id;

      // If this is the user's first address or set as default, make it default
      final existingAddresses = await getUserAddresses();
      final isDefault = setAsDefault || existingAddresses.isEmpty;

      // If setting as default, update all other addresses of the same type
      if (isDefault && existingAddresses.isNotEmpty) {
        await _updateAllAddressesDefault(user.uid, type, false);
      }

      final address = ShippingAddress(
        id: addressId,
        userId: user.uid,
        firstName: firstName,
        lastName: lastName,
        addressLine1: addressLine1,
        addressLine2: addressLine2 ?? '',
        city: city,
        state: state,
        postalCode: postalCode,
        country: _getCountryName(countryCode),
        countryCode: countryCode,
        phoneNumber: phoneNumber ?? '',
        isDefault: isDefault,
        type: type,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore.collection(_addressesCollection).doc(addressId).set(address.toMap());

      // Create user address reference
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection(_userAddressesCollection)
          .doc(addressId)
          .set({
        'addressId': addressId,
        'fullName': '${address.firstName} ${address.lastName}',
        'shortAddress': address.shortAddress,
        'type': type.toString().split('.').last,
        'isDefault': isDefault,
        'createdAt': address.createdAt.toIso8601String(),
      });

      return addressId;
    } catch (e) {
      throw Exception('Failed to save address: $e');
    }
  }

  Future<List<ShippingAddress>> getUserAddresses({AddressType? type}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    try {
      Query query = _firestore
          .collection(_addressesCollection)
          .where('userId', isEqualTo: user.uid);

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      final snapshot = await query.get();

      final addresses = snapshot.docs
          .map((doc) => ShippingAddress.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort by default first, then by creation date
      addresses.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.createdAt.compareTo(b.createdAt);
      });

      return addresses;
    } catch (e) {
      throw Exception('Failed to get user addresses: $e');
    }
  }

  Future<ShippingAddress?> getDefaultAddress({AddressType? type}) async {
    final addresses = await getUserAddresses(type: type);
    try {
      return addresses.firstWhere((address) => address.isDefault);
    } catch (e) {
      // If no default address found, return first address if available
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }

  Future<void> setDefaultAddress(String addressId, AddressType type) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    try {
      // Update all addresses of the same type to not be default
      await _updateAllAddressesDefault(user.uid, type, false);

      // Set the selected address as default
      await _firestore.collection(_addressesCollection).doc(addressId).update({
        'isDefault': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Update user address reference
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection(_userAddressesCollection)
          .doc(addressId)
          .update({
        'isDefault': true,
      });
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }

  Future<void> deleteAddress(String addressId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    try {
      final address = await getAddress(addressId);
      if (address == null) {
        throw Exception('Address not found');
      }

      // Delete from Firestore
      await _firestore.collection(_addressesCollection).doc(addressId).delete();

      // Delete user reference
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection(_userAddressesCollection)
          .doc(addressId)
          .delete();

      // If this was the default address, set another address as default
      if (address.isDefault) {
        final remainingAddresses = await getUserAddresses(type: address.type);
        if (remainingAddresses.isNotEmpty) {
          await setDefaultAddress(remainingAddresses.first.id, address.type);
        }
      }
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  Future<ShippingAddress?> getAddress(String addressId) async {
    try {
      final doc = await _firestore.collection(_addressesCollection).doc(addressId).get();

      if (!doc.exists) {
        return null;
      }

      return ShippingAddress.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get address: $e');
    }
  }

  Future<String> updateAddress({
    required String addressId,
    required String firstName,
    required String lastName,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String countryCode,
    String? phoneNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    try {
      final updateData = {
        'firstName': firstName,
        'lastName': lastName,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2 ?? '',
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'country': _getCountryName(countryCode),
        'countryCode': countryCode,
        'phoneNumber': phoneNumber ?? '',
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _firestore.collection(_addressesCollection).doc(addressId).update(updateData);

      // Update user address reference
      final fullName = '$firstName $lastName';
      final shortAddress = '$addressLine1, $city';

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection(_userAddressesCollection)
          .doc(addressId)
          .update({
        'fullName': fullName,
        'shortAddress': shortAddress,
      });

      return addressId;
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  Future<void> _updateAllAddressesDefault(String userId, AddressType type, bool isDefault) async {
    final batch = _firestore.batch();

    final addressesQuery = await _firestore
        .collection(_addressesCollection)
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.toString().split('.').last)
        .get();

    for (final doc in addressesQuery.docs) {
      batch.update(doc.reference, {
        'isDefault': isDefault,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    final userAddressesQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection(_userAddressesCollection)
        .where('type', isEqualTo: type.toString().split('.').last)
        .get();

    for (final doc in userAddressesQuery.docs) {
      batch.update(doc.reference, {'isDefault': isDefault});
    }

    await batch.commit();
  }

  // Validation methods
  static bool validateAddressForm({
    required String firstName,
    required String lastName,
    required String addressLine1,
    required String city,
    required String state,
    required String postalCode,
    required String countryCode,
  }) {
    if (firstName.trim().isEmpty) return false;
    if (lastName.trim().isEmpty) return false;
    if (addressLine1.trim().isEmpty) return false;
    if (city.trim().isEmpty) return false;
    if (state.trim().isEmpty) return false;
    if (postalCode.trim().isEmpty) return false;
    if (countryCode.trim().isEmpty) return false;

    // Basic postal code validation
    if (!ShippingAddress.isValidPostalCode(postalCode, countryCode)) {
      return false;
    }

    return true;
  }

  String _getCountryName(String countryCode) {
    // App is Cyprus-only
    return 'Cyprus';
  }
}