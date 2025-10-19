import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

/// Screen widget that displays the history of scanned medicines
/// Shows a list of all previously scanned items with their status and details
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  /// Clears all scan history from Firebase after user confirmation
  /// Shows a confirmation dialog before permanently deleting records
  void _clearHistory(BuildContext context) async {
    // Reference to the scanned history node in Firebase
    final historyRef = FirebaseDatabase.instance.ref('scanned_history');
    final snapshot = await historyRef.get();

    // Check if history is already empty
    if (!snapshot.exists || snapshot.value == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History is already empty.')),
        );
      }
      return;
    }

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear History?'),
          content: const Text('Are you sure you want to permanently delete all scan records? This action cannot be undone.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    // Delete history if user confirmed
    if (confirmed == true) {
      try {
        await historyRef.remove();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('History cleared successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Handle deletion errors
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear history: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Determines the expiration status of a medicine based on its expiration date
  ///
  /// Returns a map with:
  /// - 'status': 'expired', 'soon_expiring', 'valid', or 'unknown'
  /// - 'daysRemaining': number of days until expiration (negative if expired)
  Map<String, dynamic> _getExpirationStatus(String? expirationDateStr) {
    // Handle missing or invalid dates
    if (expirationDateStr == null || expirationDateStr == 'N/A') {
      return {'status': 'unknown', 'daysRemaining': 0};
    }

    try {
      // Parse the expiration date and calculate days remaining
      final expirationDate = DateFormat('yyyy-MM-dd').parse(expirationDateStr);
      final now = DateTime.now();
      final daysRemaining = expirationDate.difference(now).inDays;

      // Determine status based on days remaining
      if (daysRemaining < 0) {
        // Already expired
        return {'status': 'expired', 'daysRemaining': daysRemaining};
      } else if (daysRemaining <= 90) { // 90 days = ~3 months
        // Expiring within 3 months
        return {'status': 'soon_expiring', 'daysRemaining': daysRemaining};
      } else {
        // Still valid with more than 3 months remaining
        return {'status': 'valid', 'daysRemaining': daysRemaining};
      }
    } catch (e) {
      // Return unknown status if date parsing fails
      return {'status': 'unknown', 'daysRemaining': 0};
    }
  }

  /// Determines the overall status of a scanned medicine record
  /// Considers whether medicine was found, if it's genuine, and expiration status
  ///
  /// Returns a map with status text, color, and icon for display
  Map<String, dynamic> _getRecordStatus(Map record) {
    // Extract key fields from the record
    final bool wasFound = record['wasFound'] ?? false;
    final bool isGenuine = record['isGenuine'] ?? false;
    final String? expirationDate = record['expirationDate'];

    // Priority 1: Medicine not found in database
    if (!wasFound) {
      return {
        'text': 'Not Found',
        'color': const Color(0xFF757575), // Gray
        'icon': Icons.help_outline,
      };
    }

    // Priority 2: Medicine is counterfeit/not genuine
    if (!isGenuine) {
      return {
        'text': 'Counterfeit',
        'color': const Color(0xFFD32F2F), // Red
        'icon': Icons.gpp_bad,
      };
    }

    // Priority 3: Check expiration status
    final expStatusMap = _getExpirationStatus(expirationDate);
    final String expStatus = expStatusMap['status'];

    if (expStatus == 'expired') {
      return {
        'text': 'Expired',
        'color': const Color(0xFFC62828), // Dark Red
        'icon': Icons.event_busy,
      };
    }

    if (expStatus == 'soon_expiring') {
      return {
        'text': 'Expiring Soon',
        'color': const Color(0xFFFFA000), // Orange
        'icon': Icons.warning_amber_rounded,
      };
    }

    // Medicine is genuine and valid
    return {
      'text': 'Genuine',
      'color': const Color(0xFF388E3C), // Green
      'icon': Icons.verified_user,
    };
  }

  /// Formats a date string into a human-readable format
  /// Example: "Jan 15, 2024 - 02:30 PM"
  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      // If parsing fails, return truncated string
      return dateStr.substring(0, dateStr.length > 10 ? 10 : dateStr.length);
    }
  }

  /// Converts a date string into relative time (e.g., "2 days ago", "5 hours ago")
  /// Provides user-friendly time context for when a scan was performed
  String _getRelativeTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      // Return appropriate time unit based on how long ago it was
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  /// Shows a detailed bottom sheet with full information about a scanned medicine
  /// Displays all available data including barcode, dates, manufacturer, etc.
  void _showDetails(BuildContext context, Map record) {
    // Get status information for styling
    final status = _getRecordStatus(record);
    final statusColor = status['color'] as Color;
    final statusIcon = status['icon'] as IconData;
    final statusText = status['text'] as String;

    // Show modal bottom sheet with medicine details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7, // 70% of screen height
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Drag handle indicator at the top
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge at the top
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Medicine name section
                    const Text(
                      'Medicine Name',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record['drugName'] ?? 'Unknown Medicine',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A2A3A)),
                    ),
                    const SizedBox(height: 24),
                    // Details card with all information
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Always show barcode and scan date
                          _buildDetailItem(Icons.qr_code_2, 'Barcode', record['scannedCode'] ?? 'N/A'),
                          const Divider(height: 24),
                          _buildDetailItem(Icons.calendar_today, 'Scanned On', _formatDate(record['scanDate'])),
                          // Conditionally show optional fields if they exist
                          if (record['manufacturer'] != null) ...[
                            const Divider(height: 24),
                            _buildDetailItem(Icons.business, 'Manufacturer', record['manufacturer']),
                          ],
                          if (record['expirationDate'] != null) ...[
                            const Divider(height: 24),
                            _buildDetailItem(Icons.event_busy, 'Expiration Date', record['expirationDate']),
                          ],
                          if (record['batchNumber'] != null) ...[
                            const Divider(height: 24),
                            _buildDetailItem(Icons.tag, 'Batch Number', record['batchNumber']),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF007BFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single detail item row with icon, label, and value
  /// Used in the detail bottom sheet to display medicine information
  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        // Icon container
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: const Color(0xFF007BFF)),
        ),
        const SizedBox(width: 12),
        // Label and value
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2A3A)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Firebase reference ordered by timestamp (newest first after sorting)
    final historyRef = FirebaseDatabase.instance.ref('scanned_history').orderByChild('timestamp');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Clear history button in app bar
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _clearHistory(context),
            tooltip: 'Clear History',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder(
        stream: historyRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          // Show loading indicator while fetching data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF007BFF)));
          }

          // Show empty state if no history exists
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No scan history found', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text('Start scanning medicines to see history', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }

          // Convert Firebase data to list and sort by timestamp (newest first)
          final Map<dynamic, dynamic> historyMap = snapshot.data!.snapshot.value as Map;
          final List<MapEntry> historyList = historyMap.entries.toList();
          historyList.sort((a, b) => b.value['timestamp'].compareTo(a.value['timestamp']));

          // Build scrollable list of history items
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final record = historyList[index].value as Map;

              // Get status information for this record
              final status = _getRecordStatus(record);

              final Color iconColor = status['color'];
              final IconData leadIcon = status['icon'];
              final String statusText = status['text'];

              // Determine display title (show "Expired Product" for expired items)
              String displayTitle = record['drugName'] ?? 'Unknown Medicine';
              if (statusText == 'Expired') {
                displayTitle = 'Expired Product';
              }

              // Build individual history item card
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showDetails(context, record), // Show details on tap
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Status icon on the left
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(leadIcon, color: iconColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          // Medicine information in the middle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title and status badge
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayTitle,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2A3A)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Status badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: iconColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Barcode information
                                Row(
                                  children: [
                                    Icon(Icons.qr_code_2, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(record['scannedCode'] ?? 'N/A', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Relative time information
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getRelativeTime(record['scanDate']),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Chevron icon on the right
                          Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}