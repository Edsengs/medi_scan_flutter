import 'package:flutter/material.dart';
import 'package:medi_scan_flutter/models/drug_data.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultScreen extends StatelessWidget {
  final String scannedCode;
  final DrugData? drug;

  const ResultScreen({super.key, required this.scannedCode, this.drug});

  void _reportDrug(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'report@mediscan.org',
      query: 'subject=Suspicious Drug Report&body=Found suspicious drug with barcode: $scannedCode',
    );
    try {
      if (!await launchUrl(emailLaunchUri)) {
        throw 'Could not launch $emailLaunchUri';
      }
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool drugFound = drug != null;
    bool isGenuine = drug?.genuine ?? false;
    // You can add the expiry logic here if needed

    IconData statusIcon = Icons.help_outline;
    Color statusColor = Colors.orange;
    String statusTitle = "Product Not Found";

    if (drugFound) {
      if (isGenuine) {
        statusIcon = Icons.verified_user;
        statusColor = Colors.green;
        statusTitle = "Genuine Product";
      } else {
        statusIcon = Icons.gpp_bad;
        statusColor = Colors.red;
        statusTitle = "Suspicious Product";
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Verification Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(statusIcon, color: statusColor, size: 100),
            const SizedBox(height: 16),
            Text(
              statusTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: statusColor),
            ),
            const SizedBox(height: 24),
            if (drugFound)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${drug!.name}'),
                      Text('Manufacturer: ${drug!.manufacturer}'),
                      Text('Expires on: ${drug!.expirationDate}'),
                      Text('Batch: ${drug!.batchNumber}'),
                      const Divider(height: 20),
                      Text('Indication: ${drug!.indication}'),
                      Text('Dosage: ${drug!.dosage}'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (drugFound && !isGenuine)
              ElevatedButton(
                onPressed: () => _reportDrug(context),
                child: const Text('Report Suspicious Drug'),
              ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Scan Another'),
            ),
          ],
        ),
      ),
    );
  }
}

