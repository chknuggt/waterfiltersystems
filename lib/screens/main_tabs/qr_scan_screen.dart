import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/buttons/primary_button.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({Key? key}) : super(key: key);

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;
  String? lastScannedCode;
  DateTime? lastScanTime;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
        _isCheckingPermission = false;
      });
    } else if (status.isDenied) {
      final result = await Permission.camera.request();
      setState(() {
        _hasPermission = result.isGranted;
        _isCheckingPermission = false;
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _hasPermission = false;
        _isCheckingPermission = false;
      });
      _showPermissionDialog();
    } else {
      setState(() {
        _hasPermission = false;
        _isCheckingPermission = false;
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Camera Permission Required',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        content: const Text(
          'To scan QR codes, please allow camera access in your device settings.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Go back to previous tab
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            text: 'Open Settings',
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isEmpty || isProcessing) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Debounce - prevent multiple scans of the same code within 3 seconds
    final now = DateTime.now();
    if (lastScannedCode == code &&
        lastScanTime != null &&
        now.difference(lastScanTime!).inSeconds < 3) {
      return;
    }

    setState(() {
      isProcessing = true;
      lastScannedCode = code;
      lastScanTime = now;
    });

    // Check if the code is a valid URL
    if (_isValidUrl(code)) {
      try {
        final uri = Uri.parse(code);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showSnackBar('Cannot open this URL');
        }
      } catch (e) {
        _showSnackBar('Error opening URL: $e');
      }
    } else {
      _showSnackBar('Scanned content is not a URL');
    }

    // Reset processing state after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    });
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.neutralGray800,
        ),
      );
    }
  }

  void _toggleFlash() {
    cameraController.toggleTorch();
  }

  void _switchCamera() {
    cameraController.switchCamera();
  }

  void _resetScanner() {
    setState(() {
      isProcessing = false;
      lastScannedCode = null;
      lastScanTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: _hasPermission ? [
          IconButton(
            onPressed: _toggleFlash,
            icon: const Icon(Icons.flash_on),
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.flip_camera_ios),
            tooltip: 'Switch Camera',
          ),
        ] : null,
      ),
      backgroundColor: Colors.black,
      body: _isCheckingPermission
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : !_hasPermission
              ? _buildPermissionDeniedView()
              : Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Camera Error',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.errorDetails?.message ?? 'Please check camera permissions',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),

          // Scanning overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isProcessing ? AppTheme.successGreen : Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
              ),
              child: isProcessing
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppSizing.radiusLarge - 3),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.successGreen,
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Processing...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
          ),

          // Instructions at the bottom
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSizing.paddingLarge),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizing.paddingLarge,
                      vertical: AppSizing.paddingMedium,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(AppSizing.radiusLarge),
                    ),
                    child: const Text(
                      'Position the QR code inside the frame to scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSizing.paddingLarge),
                  if (isProcessing)
                    PrimaryButton(
                      text: 'Scan Again',
                      onPressed: _resetScanner,
                      variant: ButtonVariant.outline,
                    ),
                ],
              ),
            ),
          ),

          // Corner indicators for scanning frame
          Positioned(
            left: (MediaQuery.of(context).size.width - 250) / 2 - 10,
            top: (MediaQuery.of(context).size.height - 250) / 2 - 60,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.white, width: 4),
                  top: BorderSide(color: Colors.white, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            right: (MediaQuery.of(context).size.width - 250) / 2 - 10,
            top: (MediaQuery.of(context).size.height - 250) / 2 - 60,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.white, width: 4),
                  top: BorderSide(color: Colors.white, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            left: (MediaQuery.of(context).size.width - 250) / 2 - 10,
            bottom: (MediaQuery.of(context).size.height - 250) / 2 + 160,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.white, width: 4),
                  bottom: BorderSide(color: Colors.white, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            right: (MediaQuery.of(context).size.width - 250) / 2 - 10,
            bottom: (MediaQuery.of(context).size.height - 250) / 2 + 160,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.white, width: 4),
                  bottom: BorderSide(color: Colors.white, width: 4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizing.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Colors.white70,
            ),
            const SizedBox(height: AppSizing.paddingLarge),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizing.paddingMedium),
            const Text(
              'To scan QR codes, we need access to your camera. Please tap the button below to grant permission.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizing.paddingXLarge),
            PrimaryButton(
              text: 'Grant Camera Permission',
              onPressed: () async {
                final result = await Permission.camera.request();
                if (result.isGranted) {
                  setState(() {
                    _hasPermission = true;
                  });
                } else if (result.isPermanentlyDenied) {
                  _showPermissionDialog();
                }
              },
              icon: Icons.camera_alt,
            ),
            const SizedBox(height: AppSizing.paddingMedium),
            TextButton(
              onPressed: () {
                // Go back to previous tab
                Navigator.of(context).pop();
              },
              child: const Text(
                'Go Back',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}