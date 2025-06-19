import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconFadeAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2000,
      ), // Total duration for all animations
    );

    // Icon fade-in animation (from 0% to 75% of the timeline)
    _iconFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeIn),
      ),
    );

    // Icon scale-up animation (from 0% to 75% of the timeline)
    _iconScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeInOut),
      ),
    );

    // Text slide-up animation (from 50% to 100% of the timeline)
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), // Start 50% below its final position
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Text fade-in animation (from 50% to 100% of the timeline)
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Navigate to home screen after animations complete
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(const Duration(milliseconds: 500), () {
          // Check if the widget is still in the tree before navigating
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        });
      }
    });

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Theme to adapt to light/dark mode
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Icon
            FadeTransition(
              opacity: _iconFadeAnimation,
              child: ScaleTransition(
                scale: _iconScaleAnimation,
                child: Icon(
                  Icons.description_rounded, // A nice icon for notes
                  size: 100,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Animated Text
            SlideTransition(
              position: _textSlideAnimation,
              child: FadeTransition(
                opacity: _textFadeAnimation,
                child: Text(
                  'Notes',
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
