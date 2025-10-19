import 'package:firebase_database/firebase_database.dart';
import 'package:medi_scan_flutter/models/drug_data.dart';
import 'package:medi_scan_flutter/models/scanned_record.dart';
import 'package:intl/intl.dart';

class FirebaseHelper {
  final DatabaseReference _drugsRef = FirebaseDatabase.instance.ref('drugs');
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref('scanned_history');

  Future<DrugData?> lookupDrug(String scannedCode) async {
    try {
      final snapshot = await _drugsRef.child(scannedCode).get();
      if (snapshot.exists && snapshot.value != null) {
        return DrugData.fromJson(scannedCode, snapshot.value as Map);
      }
      return null;
    } catch (e) {
      print("Error looking up drug: $e");
      return null;
    }
  }

  Future<void> saveScannedMedicine(String scannedCode, DrugData? drug) async {
    final now = DateTime.now();
    final record = ScannedRecord(
      scannedCode: scannedCode,
      drugName: drug?.name ?? "Unknown Medicine",
      isGenuine: drug?.genuine ?? false,
      wasFound: drug != null,
      scanDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
      timestamp: now.millisecondsSinceEpoch,
      expirationDate: drug?.expirationDate,
    );
    await _historyRef.push().set(record.toJson());
  }

  Future<void> addCustomMedicine(DrugData medicine) async {
    // Note: in a real app, you'd want to use the full object, not just name and genuine
    await _drugsRef.child(medicine.id).set(medicine.toJson());
  }
}

