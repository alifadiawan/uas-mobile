import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  // This is your primary login function (Email/Password)
  Future<void> _login() async {
    setState(() => _isLoading = true);
    // ... same Supabase logic as before ...
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted && response.user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Placeholder for Google Sign-In logic
  Future<void> _googleSignIn() async {
    print('--- Attempting Google Sign-In ---');
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId:
            '280506600567-96n9hmlu3tcfdlj216snck8u380mu9gv.apps.googleusercontent.com',
      );

      print('1. Awaiting Google Sign-In pop-up...');
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In was cancelled by the user.');
        return;
      }
      print('2. Google User obtained: ${googleUser.displayName}');

      print('3. Fetching authentication tokens...');
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        print('Error: ID token from Google is null!');
        throw 'No ID token from Google!';
      }

      print('4. Attempting to sign in to Supabase with the obtained tokens...');
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      print('--- Google Sign-In with Supabase Successful! ---');
      
      // Check if the widget is still mounted and user exists before navigating
      if (mounted && response.user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (error) {
      // Print the error to the console for detailed debugging
      print('!!! Error during Google Sign-In: $error !!!');

      // Also show a user-friendly message on the screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing in with Google: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. App Logo
                Image.asset('assets/logo_notes.png', width: 100, height: 100),
                const SizedBox(height: 24),

                // 2. Header Text
                Text(
                  'Log in or sign up',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // 3. Email & Password Form
                _buildEmailForm(context),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),

                // 4. "Or" Separator
                _buildSeparator(context),
                const SizedBox(height: 24),

                // 5. Google Sign-In Button
                _buildSocialLogin(context),
                const SizedBox(height: 48),

                // 6. Footer links
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Email',
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Password Field
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Password',
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey.shade600,
              ),
              onPressed:
                  () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Continue Button
        ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.grey.shade800,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child:
              _isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text(
                    'Continue',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
        ),
      ],
    );
  }

  Widget _buildSeparator(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('or', style: TextStyle(color: Colors.grey.shade500)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildSocialLogin(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _googleSignIn,
      icon: Image.asset('assets/google.png', height: 20), // ** IMPORTANT **
      label: const Text(
        'Continue with Google',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        TextButton(
          onPressed: () {},
          child: Text(
            'Need help signing in?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            children: [
              const TextSpan(
                text:
                    'By signing up, you are creating a Notes account and agree to our ',
              ),
              TextSpan(
                text: 'Terms',
                style: const TextStyle(decoration: TextDecoration.underline),
                recognizer:
                    TapGestureRecognizer()
                      ..onTap = () {
                        // TODO: Handle Terms link tap
                      },
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: const TextStyle(decoration: TextDecoration.underline),
                recognizer:
                    TapGestureRecognizer()
                      ..onTap = () {
                        // TODO: Handle Privacy Policy link tap
                      },
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ],
    );
  }
}
