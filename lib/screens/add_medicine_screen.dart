import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:medi_scan_flutter/models/drug_data.dart';
import 'package:medi_scan_flutter/services/firebase_helper.dart';

/// Screen widget for adding new medicine to the database
/// Provides a form interface for entering medicine details
class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Firebase helper instance for database operations
  final FirebaseHelper _firebaseHelper = FirebaseHelper();

  // Flag to track if medicine is marked as genuine
  bool _isGenuine = true;

  // Loading state for submit button
  bool _isLoading = false;

  // Text controllers for all form fields
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _expDateController = TextEditingController();
  final _batchController = TextEditingController();
  final _indicationController = TextEditingController();
  final _dosageController = TextEditingController();
  final _sideEffectsController = TextEditingController();
  final _warningsController = TextEditingController();

  // Stores the selected expiration date
  DateTime? _selectedDate;

  /// Clean up controllers when widget is disposed to prevent memory leaks
  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _manufacturerController.dispose();
    _expDateController.dispose();
    _batchController.dispose();
    _indicationController.dispose();
    _dosageController.dispose();
    _sideEffectsController.dispose();
    _warningsController.dispose();
    super.dispose();
  }

  /// Shows date picker dialog and updates expiration date field
  void _presentDatePicker() async {
    final now = DateTime.now();

    // Show date picker with range from 2000 to 20 years in the future
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20),
    );

    // Update state if user selected a date
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        // Format date as yyyy-MM-dd for database storage
        _expDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  /// Validates form and submits medicine data to Firebase
  void _submitForm() async {
    // Validate all required fields
    if (_formKey.currentState!.validate()) {
      // Show loading indicator
      setState(() => _isLoading = true);

      // Create DrugData object from form inputs
      final newDrug = DrugData(
        id: _barcodeController.text,
        name: _nameController.text,
        manufacturer: _manufacturerController.text,
        expirationDate: _expDateController.text.isNotEmpty ? _expDateController.text : "N/A",
        batchNumber: _batchController.text,
        indication: _indicationController.text,
        dosage: _dosageController.text,
        sideEffects: _sideEffectsController.text,
        warnings: _warningsController.text,
        genuine: _isGenuine,
      );

      try {
        // Add medicine to Firebase database
        await _firebaseHelper.addCustomMedicine(newDrug);

        // Check if widget is still mounted before updating UI
        if (!mounted) return;

        // Close the screen and return to previous page
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Handle errors during submission
        if (!mounted) return;

        // Show error message with details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add medicine: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        // Hide loading indicator if widget is still mounted
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top app bar with title
      appBar: AppBar(
        title: const Text('Add New Medicine'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // Header section with title and description
            const Text(
              'Medicine Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2A3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the details to add a new medicine to the database',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Basic Information Section
            // Contains barcode, name, manufacturer, expiration date, and batch number
            _buildSectionCard(
              title: 'Basic Information',
              icon: Icons.info_outline,
              children: [
                _buildTextField(
                  controller: _barcodeController,
                  label: 'Barcode',
                  hint: 'Enter product barcode',
                  icon: Icons.qr_code,
                  required: true,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: 'Medicine Name',
                  hint: 'Enter medicine name',
                  icon: Icons.medication,
                  required: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _manufacturerController,
                  label: 'Manufacturer',
                  hint: 'Enter manufacturer name',
                  icon: Icons.business,
                ),
                const SizedBox(height: 16),
                // Special read-only field that opens date picker on tap
                TextFormField(
                  controller: _expDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Expiration Date',
                    hintText: 'Select a date',
                    prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF007BFF)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF007BFF), width: 2),
                    ),
                  ),
                  onTap: _presentDatePicker,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _batchController,
                  label: 'Batch Number',
                  hint: 'Enter batch number',
                  icon: Icons.numbers,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Medical Information Section
            // Contains indication (usage) and dosage information
            _buildSectionCard(
              title: 'Medical Information',
              icon: Icons.local_hospital,
              children: [
                _buildTextField(
                  controller: _indicationController,
                  label: 'Indication',
                  hint: 'What is this medicine used for?',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _dosageController,
                  label: 'Dosage',
                  hint: 'Recommended dosage and frequency',
                  icon: Icons.schedule,
                  maxLines: 2,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Side Effects Section
            // Contains information about possible adverse effects
            _buildSectionCard(
              title: 'Side Effects',
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.orange,
              children: [
                _buildTextField(
                  controller: _sideEffectsController,
                  label: 'Side Effects',
                  hint: 'List possible side effects (e.g., nausea, dizziness, headache)',
                  icon: Icons.sentiment_dissatisfied,
                  maxLines: 4,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Warnings Section
            // Contains important safety warnings and contraindications
            _buildSectionCard(
              title: 'Warnings',
              icon: Icons.error_outline,
              iconColor: Colors.red,
              children: [
                _buildTextField(
                  controller: _warningsController,
                  label: 'Warnings',
                  hint: 'Important warnings (e.g., Do not use if allergic to...)',
                  icon: Icons.health_and_safety,
                  maxLines: 4,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Genuine Medicine Toggle
            // Switch to mark if the medicine is verified as genuine
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SwitchListTile(
                title: const Text(
                  'Genuine Medicine',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Mark this product as genuine and verified',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                value: _isGenuine,
                onChanged: (value) => setState(() => _isGenuine = value),
                activeColor: Colors.green,
                secondary: Icon(
                  _isGenuine ? Icons.verified_user : Icons.gpp_maybe,
                  color: _isGenuine ? Colors.green : Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            // Shows loading indicator when submitting
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Add to Database',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Builds a styled card section with title, icon, and child widgets
  /// Used to group related form fields together
  ///
  /// Parameters:
  /// - title: Section heading text
  /// - icon: Icon to display next to title
  /// - children: List of widgets to display in the section
  /// - iconColor: Optional custom color for the icon (defaults to blue)
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with icon and title
          Row(
            children: [
              Icon(icon, color: iconColor ?? const Color(0xFF007BFF), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2A3A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Section content
          ...children,
        ],
      ),
    );
  }

  /// Builds a reusable text field with consistent styling
  ///
  /// Parameters:
  /// - controller: TextEditingController for the field
  /// - label: Label text displayed above the field
  /// - hint: Placeholder text shown when field is empty
  /// - icon: Icon displayed on the left side of the field
  /// - required: If true, adds asterisk to label and enables validation
  /// - maxLines: Number of lines for multiline input (default: 1)
  /// - keyboardType: Type of keyboard to show (e.g., number, email)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        // Add asterisk to required fields
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF007BFF)),
        filled: true,
        fillColor: Colors.grey[50],
        // Border styling for different states
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF007BFF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      // Validator for required fields
      validator: required
          ? (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      }
          : null,
    );
  }
}