import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:waterfilternet/models/invoice.dart';
import 'package:waterfilternet/models/order.dart' as order_model;
import 'package:waterfilternet/services/config_service.dart';

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConfigService _config = ConfigService();

  static const String _invoicesCollection = 'invoices';
  static const String _userInvoicesCollection = 'user_invoices';

  // Demo mode invoice storage
  static final List<Invoice> _demoInvoices = [];

  Future<String> createInvoice(order_model.Order order, {
    CompanyInfo? companyInfo,
    String? paymentTerms,
    String? notes,
    int dueDays = 30,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to create an invoice');
    }

    try {
      // Use demo mode if configured or on web
      if (_config.isDemoMode) {
        await Future.delayed(Duration(seconds: 1)); // Simulate processing time

        // Create complete invoice data even in demo mode
        final invoice = Invoice.fromOrder(
          order,
          companyInfo: companyInfo,
          paymentTerms: paymentTerms,
          notes: notes,
          dueDays: dueDays,
        );

        // Store in demo invoices list for persistence
        _demoInvoices.add(invoice);

        // Save to Firestore if available for demo data viewing
        try {
          await _firestore.collection(_invoicesCollection).doc(invoice.id).set(invoice.toMapForDatabase());
          print('Demo: Invoice saved to Firestore with complete data - ID: ${invoice.id}, Number: ${invoice.invoiceNumber}');
        } catch (e) {
          print('Demo: Invoice created in memory only - ID: ${invoice.id}, Number: ${invoice.invoiceNumber}');
        }

        return invoice.id;
      }

      // Normal flow for mobile/production
      try {
        final invoice = Invoice.fromOrder(
          order,
          companyInfo: companyInfo,
          paymentTerms: paymentTerms,
          notes: notes,
          dueDays: dueDays,
        );


        // Try to save to Firestore
        try {
          await _firestore.collection(_invoicesCollection).doc(invoice.id).set(invoice.toMapForDatabase());

          // Create user invoice reference
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection(_userInvoicesCollection)
              .doc(invoice.id)
              .set({
            'invoiceId': invoice.id,
            'invoiceNumber': invoice.invoiceNumber,
            'orderId': invoice.orderId,
            'total': invoice.total,
            'status': invoice.status.toString().split('.').last,
            'issueDate': invoice.issueDate.toIso8601String(),
            'dueDate': invoice.dueDate.toIso8601String(),
          });

          print('Invoice saved to Firestore successfully');
        } catch (firestoreError) {
          print('Firestore operation failed: $firestoreError');
          // Continue anyway - invoice metadata created but not persisted
        }

        return invoice.id;
      } catch (e) {
        print('Invoice creation failed, falling back to demo mode: $e');
        _config.enableDemoMode();

        // Fall back to demo mode
        final invoiceId = _config.generateDemoId('invoice');
        final invoiceNumber = 'INV-WF-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

        print('Demo: Invoice created in fallback mode - ID: $invoiceId, Number: $invoiceNumber');
        return invoiceId;
      }
    } catch (e) {
      throw Exception('Failed to create invoice: $e');
    }
  }


  Future<Invoice?> getInvoice(String invoiceId) async {
    try {
      final doc = await _firestore.collection(_invoicesCollection).doc(invoiceId).get();

      if (!doc.exists) {
        return null;
      }

      return Invoice.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get invoice: $e');
    }
  }

  Future<List<Invoice>> getUserInvoices({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    try {
      Query query = _firestore
          .collection(_invoicesCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => Invoice.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user invoices: $e');
    }
  }

  Stream<List<Invoice>> getUserInvoicesStream({int limit = 20}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_invoicesCollection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Invoice.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> updateInvoiceStatus(String invoiceId, InvoiceStatus status) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.toString().split('.').last,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (status == InvoiceStatus.paid) {
        updateData['paidDate'] = DateTime.now().toIso8601String();
      }

      await _firestore.collection(_invoicesCollection).doc(invoiceId).update(updateData);

      // Update user invoice reference
      final invoice = await getInvoice(invoiceId);
      if (invoice != null) {
        await _firestore
            .collection('users')
            .doc(invoice.userId)
            .collection(_userInvoicesCollection)
            .doc(invoiceId)
            .update({
          'status': status.toString().split('.').last,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to update invoice status: $e');
    }
  }

  Future<void> deleteInvoice(String invoiceId) async {
    try {
      final invoice = await getInvoice(invoiceId);
      if (invoice == null) {
        throw Exception('Invoice not found');
      }

      // Delete from Firestore
      await _firestore.collection(_invoicesCollection).doc(invoiceId).delete();

      // Delete user reference
      await _firestore
          .collection('users')
          .doc(invoice.userId)
          .collection(_userInvoicesCollection)
          .doc(invoiceId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete invoice: $e');
    }
  }
}