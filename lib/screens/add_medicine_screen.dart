import 'package:flutter/material.dart';
import 'package:medi_scan_flutter/models/drug_data.dart';
import 'package:medi_scan_flutter/services/firebase_helper.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseHelper _firebaseHelper = FirebaseHelper();
  bool _isGenuine = true;
  bool _isLoading = false;

  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _expDateController = TextEditingController();
  final _batchController = TextEditingController();
  final _indicationController = TextEditingController();
  final _dosageController = TextEditingController();

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final newDrug = DrugData(
        id: _barcodeController.text,
        name: _nameController.text,
        manufacturer: _manufacturerController.text,
        expirationDate: _expDateController.text,
        batchNumber: _batchController.text,
        indication: _indicationController.text,
        dosage: _dosageController.text,
        genuine: _isGenuine,
      );
      try {
        await _firebaseHelper.addCustomMedicine(newDrug);
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine added successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add medicine: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Medicine')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(controller: _barcodeController, decoration: const InputDecoration(labelText: 'Barcode*'), validator: (v) => v!.isEmpty ? 'Required' : null),
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Medicine Name*'), validator: (v) => v!.isEmpty ? 'Required' : null),
            TextFormField(controller: _manufacturerController, decoration: const InputDecoration(labelText: 'Manufacturer')),
            TextFormField(controller: _expDateController, decoration: const InputDecoration(labelText: 'Expiration Date (YYYY-MM-DD)')),
            TextFormField(controller: _batchController, decoration: const InputDecoration(labelText: 'Batch Number')),
            TextFormField(controller: _indicationController, decoration: const InputDecoration(labelText: 'Indication')),
            TextFormField(controller: _dosageController, decoration: const InputDecoration(labelText: 'Dosage')),
            SwitchListTile(
              title: const Text('Genuine Medicine'),
              value: _isGenuine,
              onChanged: (value) => setState(() => _isGenuine = value),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Add to Database'),
            )
          ],
        ),
      ),
    );
  }
}

