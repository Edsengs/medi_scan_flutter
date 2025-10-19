import 'package:flutter/material.dart';
import 'package:medi_scan_flutter/models/drug_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

/// Screen that displays the verification result after scanning a medicine barcode
/// Shows product details, expiration status, and medical information
/// Color-coded based on product status (genuine, fake, expired, etc.)
class ResultScreen extends StatelessWidget {
  final String scannedCode;
  final DrugData? drug;

  const ResultScreen({super.key, required this.scannedCode, this.drug});

  /// Opens the device's email app to report a suspicious drug
  /// Pre-fills the email with subject and barcode information
  void _reportDrug(BuildContext context) async {
    // Create mailto URI with pre-filled subject and body
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'report@mediscan.org',
      query: 'subject=Suspicious Drug Report&body=Found suspicious drug with barcode: $scannedCode',
    );

    try {
      // Attempt to launch email app
      if (!await launchUrl(emailLaunchUri)) {
        throw 'Could not launch $emailLaunchUri';
      }
    } catch (e) {
      // Show error message if email app cannot be opened
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app.')),
        );
      }
    }
  }

  /// Determines the expiration status of a medicine
  ///
  /// Returns a map containing:
  /// - 'status': 'expired', 'soon_expiring', 'valid', or 'unknown'
  /// - 'daysRemaining': number of days until expiration (negative if already expired)
  Map<String, dynamic> _getExpirationStatus(String? expirationDateStr) {
    // Handle missing or invalid dates
    if (expirationDateStr == null || expirationDateStr == 'N/A') {
      return {
        'status': 'unknown',
        'daysRemaining': 0,
      };
    }

    try {
      // Parse the expiration date (format: YYYY-MM-DD)
      DateTime expirationDate = DateFormat('yyyy-MM-dd').parse(expirationDateStr);
      DateTime now = DateTime.now();

      // Calculate days remaining until expiration
      int daysRemaining = expirationDate.difference(now).inDays;

      // Determine status based on days remaining
      if (daysRemaining < 0) {
        // Product has already expired
        return {'status': 'expired', 'daysRemaining': daysRemaining};
      } else if (daysRemaining <= 90) { // 90 days = approximately 3 months
        // Product is expiring within 3 months
        return {'status': 'soon_expiring', 'daysRemaining': daysRemaining};
      } else {
        // Product is still valid with more than 3 months remaining
        return {'status': 'valid', 'daysRemaining': daysRemaining};
      }
    } catch (e) {
      // Return unknown status if date parsing fails
      return {'status': 'unknown', 'daysRemaining': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define color palette for different product statuses
    const Color colorFake = Color(0xFFD32F2F);           // Red for counterfeit products
    const Color colorGenuine = Color(0xFF388E3C);        // Green for genuine products
    const Color colorExpiringSoon = Color(0xFFFFA000);   // Orange for products expiring soon
    const Color colorExpired = Color(0xFFC62828);        // Dark red for expired products
    const Color colorNotFound = Color(0xFF757575);       // Gray for products not in database

    // Check if drug was found in database and if it's marked as genuine
    bool drugFound = drug != null;
    bool isGenuine = drug?.genuine ?? false;

    // Get expiration status information
    Map<String, dynamic> expirationStatus = _getExpirationStatus(drug?.expirationDate);
    String expStatus = expirationStatus['status'];
    int daysRemaining = expirationStatus['daysRemaining'];

    // Determine final display status based on priority:
    // 1. Not found (highest priority)
    // 2. Not genuine/fake
    // 3. Expired
    // 4. Expiring soon
    // 5. Genuine (lowest priority - everything is okay)
    IconData statusIcon;
    Color statusColor;
    String statusTitle;
    String statusSubtitle = '';

    if (!drugFound) {
      // Product not found in database
      statusIcon = Icons.search_off;
      statusColor = colorNotFound;
      statusTitle = "Product Not Found";
      statusSubtitle = "This barcode is not registered in our database.";
    } else if (!isGenuine) {
      // Product is marked as fake/suspicious
      statusIcon = Icons.gpp_bad;
      statusColor = colorFake;
      statusTitle = "Suspicious Product";
      statusSubtitle = "This product has been flagged as suspicious.";
    } else if (expStatus == 'expired') {
      // Product has expired
      statusIcon = Icons.event_busy;
      statusColor = colorExpired;
      statusTitle = "Expired Product";
      statusSubtitle = "This product expired ${daysRemaining.abs()} days ago.";
    } else if (expStatus == 'soon_expiring') {
      // Product is expiring within 90 days
      statusIcon = Icons.warning_amber_rounded;
      statusColor = colorExpiringSoon;
      statusTitle = "Expiring Soon";
      statusSubtitle = "This product will expire in $daysRemaining days.";
    } else {
      // Product is genuine and valid
      statusIcon = Icons.verified_user;
      statusColor = colorGenuine;
      statusTitle = "Genuine Product";
      statusSubtitle = "This product is verified and safe to use.";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Result'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Status Icon with colored background and shadow
            // Visual indicator of the verification result
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(statusIcon, color: statusColor, size: 100),
            ),

            const SizedBox(height: 24),

            // Status Title (main result message)
            Text(
              statusTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: statusColor,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 8),

            // Status Subtitle (additional context about the result)
            if (statusSubtitle.isNotEmpty)
              Text(
                statusSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),

            const SizedBox(height: 32),

            // Product Details Card
            // Only shown if product was found in database
            if (drugFound)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007BFF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Color(0xFF007BFF),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Product Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2A3A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Basic product information
                      _buildDetailRow('Name', drug!.name, Icons.medication),
                      const Divider(height: 24),
                      _buildDetailRow('Manufacturer', drug!.manufacturer, Icons.business),
                      const Divider(height: 24),
                      // Expiration date with color based on status
                      _buildDetailRow(
                        'Expires on',
                        drug!.expirationDate,
                        Icons.calendar_today,
                        color: expStatus == 'expired'
                            ? colorExpired
                            : expStatus == 'soon_expiring'
                            ? colorExpiringSoon
                            : colorGenuine,
                      ),
                      const Divider(height: 24),
                      _buildDetailRow('Batch', drug!.batchNumber, Icons.qr_code_2),

                      const SizedBox(height: 24),

                      // Medical Information Section
                      // Contains indication, dosage, side effects, and warnings
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_hospital,
                                  color: Color(0xFF007BFF),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Medical Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A2A3A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // What the medicine is used for
                            _buildInfoSection('Indication', drug!.indication),
                            const SizedBox(height: 12),
                            // Recommended dosage information
                            _buildInfoSection('Dosage', drug!.dosage),

                            // Side Effects Section
                            // Only shown if side effects information is available
                            if (drug!.sideEffects != 'Not provided') ...[
                              const SizedBox(height: 12),
                              _buildInfoSection(
                                'Side Effects',
                                drug!.sideEffects,
                                color: Colors.orange[700],
                                icon: Icons.warning_amber_rounded,
                              ),
                            ],

                            // Warnings Section
                            // Only shown if warnings information is available
                            if (drug!.warnings != 'Not provided') ...[
                              const SizedBox(height: 12),
                              _buildInfoSection(
                                'Warnings',
                                drug!.warnings,
                                color: Colors.red[700],
                                icon: Icons.error_outline,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Disclaimer Box
            // Reminds users to consult healthcare professionals
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[300]!, width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: Colors.amber[800], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This information is for reference only. Always consult your doctor or pharmacist for medical advice.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber[900],
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Report Button
            // Only shown for suspicious/fake products that were found in database
            if (!isGenuine && drugFound)
              ElevatedButton.icon(
                onPressed: () => _reportDrug(context),
                icon: const Icon(Icons.report, size: 20),
                label: const Text('Report Suspicious Product'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colorFake, // Red color to match fake status
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                  shadowColor: colorFake.withOpacity(0.3),
                ),
              ),

            if (!isGenuine && drugFound) const SizedBox(height: 16),

            // Scan Another Button
            // Returns to home screen to scan another product
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: const Text('Scan Another'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: const Color(0xFF007BFF),
                side: const BorderSide(color: Color(0xFF007BFF), width: 2),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Builds a single detail row with icon, label, and value
  /// Used to display basic product information (name, manufacturer, etc.)
  ///
  /// Parameters:
  /// - label: The field name (e.g., "Name", "Manufacturer")
  /// - value: The field value to display
  /// - icon: Icon to show next to the information
  /// - color: Optional custom color for the icon and value text
  Widget _buildDetailRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon container with colored background
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? const Color(0xFF007BFF)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ?? const Color(0xFF007BFF),
          ),
        ),
        const SizedBox(width: 12),
        // Label and value text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: color ?? const Color(0xFF1A2A3A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds an information section with title and content
  /// Used for medical information (indication, dosage, side effects, warnings)
  ///
  /// Parameters:
  /// - title: Section heading
  /// - content: Detailed information text
  /// - color: Optional custom color for title and icon
  /// - icon: Optional icon to display next to title
  Widget _buildInfoSection(String title, String content, {Color? color, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with optional icon
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color ?? Colors.grey[700]),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.grey[700],
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Content text with increased line height for readability
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: color ?? const Color(0xFF1A2A3A),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}