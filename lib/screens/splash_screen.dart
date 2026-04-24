import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo image - BIGGER
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(52),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withAlpha(26),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(52),
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  width: 260,
                  height: 260,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Subtle tagline
            Text(
              'OBD-II Diagnostics',
              style: GoogleFonts.poppins(
                fontSize: 8,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF00ACC1),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 56),
            // Loading indicator in cyan
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: const AlwaysStoppedAnimation<Color>(const Color(0xFF00ACC1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
