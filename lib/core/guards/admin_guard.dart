import 'package:flutter/material.dart';
import '../../screens/admin/admin_login_screen.dart';
import '../../services/auth_service.dart';

class AdminGuard extends StatefulWidget {
  final Widget child;

  const AdminGuard({Key? key, required this.child}) : super(key: key);

  @override
  State<AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<AdminGuard> {
  final AuthService _authService = AuthService();
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('AdminGuard: Initializing admin guard');
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Check custom claims for admin role (professional approach)
        final isAdmin = await _authService.isCurrentUserAdmin();
        if (isAdmin) {
          setState(() {
            _isAdmin = true;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }

    // Always show admin login screen if not authenticated as admin
    setState(() {
      _isAdmin = false;
      _isLoading = false;
    });
  }

  void _onAdminLogin() {
    setState(() {
      _isAdmin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAdmin) {
      return AdminLoginScreen(onAdminLogin: _onAdminLogin);
    }

    return widget.child;
  }
}