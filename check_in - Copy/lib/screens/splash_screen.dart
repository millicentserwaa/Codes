// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../services/hive_service.dart';
// import '../services/biometric_service.dart';
// import '../theme/app_theme.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   // ── Animations ──────────────────────────────────────────────────────────────
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;

//   final HiveService _hiveService = HiveService();

//   // ── Lifecycle ────────────────────────────────────────────────────────────────
//   @override
//   void initState() {
//     super.initState();

//     // Set up fade + scale animations for the logo
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeIn),
//     );

//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
//     );

//     _controller.forward();

//     // Wait 3 seconds for the splash to show, then decide where to go
//     Future.delayed(const Duration(seconds: 3), _handleNavigation);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   // ── Navigation logic ─────────────────────────────────────────────────────────

//   /// Called once after the splash delay.
//   /// Decides whether to go to onboarding or require authentication.
//   Future<void> _handleNavigation() async {
//     if (!mounted) return;

//     if (!_hiveService.hasProfile) {
//       // First-time user — no auth needed, go straight to onboarding
//       Navigator.pushReplacementNamed(context, '/onboarding');
//       return;
//     }

//     // Returning user — must authenticate before seeing health data
//     await _attemptAuthentication();
//   }

//   /// Prompts the user to authenticate.
//   /// On failure, shows a dialog with Retry and Cancel options.
//   /// Retry calls this method again (recursive) so every attempt is handled.
//   Future<void> _attemptAuthentication() async {
//     if (!mounted) return;

//     final authenticated = await BiometricService.authenticate(
//       reason: 'Verify your identity to access CheckIn',
//     );

//     if (!mounted) return;

//     if (authenticated) {
//       // Success — go to home
//       Navigator.pushReplacementNamed(context, '/home');
//       return;
//     }

//     // Failed or cancelled — show dialog
//     _showAuthFailedDialog();
//   }

//   /// Shows a dialog when authentication fails.
//   /// Try Again → calls _attemptAuthentication() again.
//   /// Cancel → stays on splash (user must try again or close the app).
//   void _showAuthFailedDialog() {
//     if (!mounted) return;

//     showDialog(
//       context: context,
//       barrierDismissible: false, // user must tap a button
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('Authentication Required'),
//         content: const Text(
//           'You must verify your identity to access your health data.',
//         ),
//         actions: [
//           // Cancel — dismisses dialog, user is back on the splash screen
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             style: TextButton.styleFrom(foregroundColor: Colors.grey),
//             child: const Text('Cancel'),
//           ),
//           // Try Again — dismisses dialog then retries auth
//           TextButton(
//             onPressed: () {
//               Navigator.pop(dialogContext); // close dialog first
//               _attemptAuthentication();    // then retry
//             },
//             child: const Text('Try Again'),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── UI ────────────────────────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.primary,
//       body: Center(
//         child: FadeTransition(
//           opacity: _fadeAnimation,
//           child: ScaleTransition(
//             scale: _scaleAnimation,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // App icon
//                 Container(
//                   width: 100,
//                   height: 100,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(28),
//                   ),
//                   child: const Icon(
//                     Icons.favorite_rounded,
//                     size: 56,
//                     color: Colors.white,
//                   ),
//                 ),

//                 const SizedBox(height: 24),

//                 // App name
//                 Text(
//                   'CheckIn',
//                   style: GoogleFonts.inter(
//                     fontSize: 36,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.white,
//                     letterSpacing: -0.5,
//                   ),
//                 ),

//                 const SizedBox(height: 8),

//                 // Tagline
//                 Text(
//                   'Your heart. Your health.',
//                   style: GoogleFonts.inter(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w400,
//                     color: Colors.white.withOpacity(0.8),
//                     letterSpacing: 0.2,
//                   ),
//                 ),

//                 const SizedBox(height: 80),

//                 // Loading spinner
//                 SizedBox(
//                   width: 24,
//                   height: 24,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2.5,
//                     valueColor: AlwaysStoppedAnimation<Color>(
//                       Colors.white.withOpacity(0.6),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/hive_service.dart';
import '../services/pin_service.dart';
import '../theme/app_theme.dart';

// Splash screen shown on app launch.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  //  Animations 
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final HiveService _hiveService = HiveService();

  // Lifecycle 
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Wait 3 seconds then navigate
    Future.delayed(const Duration(seconds: 3), _handleNavigation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────────

  Future<void> _handleNavigation() async {
    if (!mounted) return;

    // First time — no profile yet
    if (!_hiveService.hasProfile) {
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    // Returning user — check if PIN exists
    final hasPin = await PinService.hasPin();
    if (!mounted) return;

    if (!hasPin) {
      // Safety net: profile exists but no PIN (e.g. app updated from old version)
      Navigator.pushReplacementNamed(context, '/pin-setup');
      return;
    }

    // Normal returning user — ask for PIN
    Navigator.pushReplacementNamed(context, '/pin-entry');
  }

  // ── UI ────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'CheckIn',
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Your heart. Your health.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 80),

                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}