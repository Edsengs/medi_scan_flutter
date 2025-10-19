import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class WebScannerScreen extends StatefulWidget {
  const WebScannerScreen({super.key});

  @override
  State<WebScannerScreen> createState() => _WebScannerScreenState();
}

class _WebScannerScreenState extends State<WebScannerScreen> {
  late final MobileScannerController _controller;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [
        BarcodeFormat.all, // Supports all barcode formats including QR, EAN, UPC, etc.
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCamera() {
    _controller.switchCamera();
  }

  void _toggleTorch() {
    _controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: const Color(0xFF007BFF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: _toggleCamera,
            tooltip: 'Switch Camera',
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: _toggleTorch,
            tooltip: 'Toggle Flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            fit: BoxFit.contain,
            onDetect: (BarcodeCapture capture) {
              if (_hasScanned) return; // Prevent multiple scans

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                  setState(() => _hasScanned = true);
                  debugPrint('Barcode found: ${barcode.rawValue}');

                  // Return the scanned barcode back to HomeScreen
                  Navigator.of(context).pop(barcode.rawValue);
                  return;
                }
              }
            },
          ),
          // Scanning overlay
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Position the barcode within the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}