import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:medi_scan_flutter/services/firebase_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final FirebaseHelper _firebaseHelper = FirebaseHelper();
  bool _isLoading = false;

  Future<void> _scanBarcode() async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#007BFF', 'Cancel', true, ScanMode.BARCODE);
      if (!mounted) return;
      if (barcodeScanRes != '-1') {
        _verifyBarcode(barcodeScanRes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get platform version: $e')),
      );
    }
  }

  Future<void> _verifyBarcode(String barcode) async {
    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a barcode.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final drug = await _firebaseHelper.lookupDrug(barcode);
    await _firebaseHelper.saveScannedMedicine(barcode, drug);
    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).pushNamed('/result', arguments: {'scannedCode': barcode, 'drug': drug});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MediScan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            const Text(
              'Instantly verify your medicines.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _scanBarcode,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan with Camera'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('OR'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _barcodeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Enter Barcode',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _verifyBarcode(_barcodeController.text),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Verify Medicine'),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/add_medicine'),
              child: const Text('Add Sample Medicine'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/history'),
              child: const Text('View History'),
            ),
          ],
        ),
      ),
    );
  }
}

