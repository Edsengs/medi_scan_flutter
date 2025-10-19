import 'package:flutter/material.dart';
import 'package:medi_scan_flutter/screens/web_scanner_screen.dart';
import 'package:medi_scan_flutter/services/firebase_helper.dart';

/// Main home screen of the MediScan app
/// Provides options to scan barcodes via camera or manual entry
/// Displays app branding and navigation to other features
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// State class for HomeScreen with animation support
/// SingleTickerProviderStateMixin enables animation controllers
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Controller for manual barcode text input
  final TextEditingController _barcodeController = TextEditingController();

  // Firebase helper for database operations
  final FirebaseHelper _firebaseHelper = FirebaseHelper();

  // Loading state for verification process
  bool _isLoading = false;

  // Animation controllers for smooth screen transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  /// Initialize animations when screen loads
  @override
  void initState() {
    super.initState();

    // Create animation controller with 800ms duration
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this, // Provides ticker for animation
    );

    // Fade animation from transparent (0.0) to opaque (1.0)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Slide animation from 30% down to original position
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), // Start 30% below
      end: Offset.zero, // End at original position
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    // Start the animation
    _animationController.forward();
  }

  /// Clean up controllers to prevent memory leaks
  @override
  void dispose() {
    _animationController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  /// Opens the camera scanner screen and processes the scanned barcode
  /// Returns to home screen after scanning completes
  Future<void> _scanBarcode() async {
    // Navigate to scanner screen and wait for result
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WebScannerScreen()),
    );

    // Verify barcode if valid result was returned
    // Result of '-1' indicates cancelled or failed scan
    if (result != null && result is String && result != '-1') {
      _verifyBarcode(result);
    }
  }

  /// Verifies a barcode against the Firebase database
  /// Looks up medicine information and saves scan history
  ///
  /// Parameters:
  /// - barcode: The barcode string to verify
  Future<void> _verifyBarcode(String barcode) async {
    // Validate barcode is not empty
    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a barcode.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading indicator
    setState(() => _isLoading = true);

    // Look up medicine information in Firebase
    final drug = await _firebaseHelper.lookupDrug(barcode);

    // Save scan to history
    await _firebaseHelper.saveScannedMedicine(barcode, drug);

    // Check if widget is still mounted before updating state
    if (!mounted) return;

    // Hide loading indicator
    setState(() => _isLoading = false);

    // Navigate to result screen with scanned data
    Navigator.of(context)
        .pushNamed('/result', arguments: {'scannedCode': barcode, 'drug': drug});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'MediScan',
          style: TextStyle(
            color: Color(0xFF007BFF),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          // History button in top right corner
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Color(0xFF007BFF)),
            tooltip: 'View History',
            onPressed: () => Navigator.of(context).pushNamed('/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ConstrainedBox(
            // Ensure content takes full height for proper centering
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // App Logo with shadow effect
                    // Hero animation allows smooth transition between screens
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.asset('assets/icon_nobg.png'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Main Title with gradient effect
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF007BFF), Color(0xFF0056b3)],
                      ).createShader(bounds),
                      child: const Text(
                        'Instantly verify your medicines.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 39,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Required for ShaderMask
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Primary action: Scan with Camera button
                    // Disabled during loading state
                    _AnimatedButton(
                      onPressed: _isLoading ? null : _scanBarcode,
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Scan with Camera',
                      backgroundColor: const Color(0xFF007BFF),
                    ),

                    const SizedBox(height: 20),

                    // Divider with "OR" text
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Manual Barcode Entry TextField
                    // Allows users to type barcode numbers directly
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _barcodeController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Enter Barcode Manually',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Color(0xFF007BFF), width: 2),
                          ),
                          // Suffix icon changes based on loading state
                          suffixIcon: _isLoading
                              ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                              : IconButton(
                            icon: const Icon(Icons.send_rounded, color: Color(0xFF007BFF)),
                            onPressed: () => _verifyBarcode(_barcodeController.text),
                          ),
                        ),
                        // Submit on keyboard enter key
                        onSubmitted: _verifyBarcode,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Centered Add Sample Button
                    // Navigates to screen for adding new medicines to database
                    Center(
                      child: SizedBox(
                        width: 180,
                        child: _NavigationCard(
                          icon: Icons.add_circle_outline,
                          label: 'Add Sample',
                          onTap: () => Navigator.of(context).pushNamed('/add_medicine'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom animated button widget with press effect
/// Provides visual feedback by shrinking when pressed
class _AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;

  const _AnimatedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  // Tracks whether button is currently being pressed
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Update pressed state based on user interaction
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        // Scale down to 95% when pressed for tactile feedback
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            // Remove shadow when pressed to enhance depth effect
            boxShadow: _isPressed
                ? []
                : [
              BoxShadow(
                color: widget.backgroundColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: widget.onPressed,
            icon: Icon(widget.icon, size: 24),
            label: Text(widget.label),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: widget.backgroundColor,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom navigation card with hover effect
/// Used for secondary actions like "Add Sample"
class _NavigationCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavigationCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_NavigationCard> createState() => _NavigationCardState();
}

class _NavigationCardState extends State<_NavigationCard> {
  // Tracks hover state for mouse/desktop interactions
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // Track mouse hover for desktop users
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            // Change background color on hover (blue when hovered, white normally)
            color: _isHovered ? const Color(0xFF007BFF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                // Increase shadow intensity and size on hover
                color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
                blurRadius: _isHovered ? 15 : 10,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                widget.icon,
                // Invert icon color on hover
                color: _isHovered ? Colors.white : const Color(0xFF007BFF),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  // Invert text color on hover
                  color: _isHovered ? Colors.white : const Color(0xFF1A2A3A),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}