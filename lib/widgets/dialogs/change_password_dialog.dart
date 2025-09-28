import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({Key? key}) : super(key: key);

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.updateUserPassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    final basicValidation = _validatePassword(value);
    if (basicValidation != null) return basicValidation;

    if (value == _currentPasswordController.text) {
      return 'New password must be different from current password';
    }

    // Password strength requirements
    bool hasUppercase = value!.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = value.contains(RegExp(r'[a-z]'));
    bool hasDigits = value.contains(RegExp(r'[0-9]'));

    if (!hasUppercase || !hasLowercase || !hasDigits) {
      return 'Password must contain uppercase, lowercase, and numbers';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon ?? Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: onToggleVisibility,
        ),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      onChanged: (_) {
        // Trigger validation on change for better UX
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
      },
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _newPasswordController.text;
    if (password.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    List<String> requirements = [];

    // Check requirements
    if (password.length >= 6) {
      strength++;
    } else {
      requirements.add('At least 6 characters');
    }

    if (password.contains(RegExp(r'[A-Z]'))) {
      strength++;
    } else {
      requirements.add('Uppercase letter');
    }

    if (password.contains(RegExp(r'[a-z]'))) {
      strength++;
    } else {
      requirements.add('Lowercase letter');
    }

    if (password.contains(RegExp(r'[0-9]'))) {
      strength++;
    } else {
      requirements.add('Number');
    }

    Color strengthColor;
    String strengthText;

    if (strength <= 1) {
      strengthColor = AppTheme.errorRed;
      strengthText = 'Weak';
    } else if (strength <= 2) {
      strengthColor = Colors.orange;
      strengthText = 'Fair';
    } else if (strength <= 3) {
      strengthColor = Colors.blue;
      strengthText = 'Good';
    } else {
      strengthColor = AppTheme.successGreen;
      strengthText = 'Strong';
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: strengthColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: strengthColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Password Strength: ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.neutralGray700,
                ),
              ),
              Text(
                strengthText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: strengthColor,
                ),
              ),
            ],
          ),
          if (requirements.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Missing: ${requirements.join(', ')}',
              style: TextStyle(
                fontSize: 11,
                color: strengthColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Change Password',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current password field
            _buildPasswordField(
              controller: _currentPasswordController,
              label: 'Current Password',
              hint: 'Enter your current password',
              isVisible: _currentPasswordVisible,
              onToggleVisibility: () {
                setState(() {
                  _currentPasswordVisible = !_currentPasswordVisible;
                });
              },
              validator: _validatePassword,
              prefixIcon: Icons.lock_outline,
            ),

            const SizedBox(height: 16),

            // New password field
            _buildPasswordField(
              controller: _newPasswordController,
              label: 'New Password',
              hint: 'Enter your new password',
              isVisible: _newPasswordVisible,
              onToggleVisibility: () {
                setState(() {
                  _newPasswordVisible = !_newPasswordVisible;
                });
              },
              validator: _validateNewPassword,
              prefixIcon: Icons.lock_reset,
            ),

            // Password strength indicator
            _buildPasswordStrengthIndicator(),

            const SizedBox(height: 16),

            // Confirm password field
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              hint: 'Confirm your new password',
              isVisible: _confirmPasswordVisible,
              onToggleVisibility: () {
                setState(() {
                  _confirmPasswordVisible = !_confirmPasswordVisible;
                });
              },
              validator: _validateConfirmPassword,
              prefixIcon: Icons.lock_outline,
            ),

            const SizedBox(height: 16),

            // Security notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: Colors.orange[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Changing your password will sign you out of all other devices.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryTeal,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text('Change Password'),
        ),
      ],
    );
  }
}