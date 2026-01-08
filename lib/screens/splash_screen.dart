import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _controller.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Wait for Firebase Auth to restore session (if any)
    // This gives Firebase time to check if user is already logged in
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Wait for auth provider to load current user if Firebase user exists
    int attempts = 0;
    while (attempts < 10) {
      if (!mounted) return;
      
      // If we have a current user, we're authenticated
      if (authProvider.currentUser != null) {
        break;
      }
      
      // Wait a bit more for auth state to load
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }
    
    // Ensure minimum splash duration for UX
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    // Navigate based on auth state
    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF), // White
              Color(0xFFF5F8FF), // Light blue
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 24),
                
                // App Name
                Text(
                  'XChangeHub',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: const Color(0xFF1A237E),
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 12),
                
                // Tagline
                Text(
                  'Learn. Share. Grow.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF666666),
                        fontSize: 18,
                        letterSpacing: 0.3,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                
                // Loading Indicator
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
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
