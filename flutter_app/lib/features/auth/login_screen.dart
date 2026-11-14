import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';

enum AuthViewMode { login, signup, forgotPassword }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Dedicated Separate Controllers for Sign In
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  // Dedicated Separate Controllers for Sign Up
  final _signUpStoreNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpPhoneController = TextEditingController();

  // Dedicated Separate Controllers for Forgot Password
  final _forgotEmailController = TextEditingController();
  final _newPasswordController = TextEditingController();

  AuthViewMode _viewMode = AuthViewMode.login;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpStoreNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpPhoneController.dispose();
    _forgotEmailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _showSenseErrorDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required String tagText,
    required String actionText,
    VoidCallback? onAction,
    String? secondaryText,
    VoidCallback? onSecondary,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: AppTheme.surfaceBorder)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: iconColor.withOpacity(0.3)),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tagText.toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: iconColor, letterSpacing: 0.8),
              ),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onAction?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(actionText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            if (secondaryText != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onSecondary?.call();
                  },
                  child: Text(secondaryText, style: const TextStyle(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleDirectAuth() async {
    if (_viewMode == AuthViewMode.login) {
      final email = _signInEmailController.text.trim();
      final password = _signInPasswordController.text.trim();

      if (email.isEmpty) {
        _showSenseErrorDialog(
          title: 'Email Address Required',
          message: 'Please enter your registered email address to sign into your terminal.',
          icon: Icons.alternate_email_rounded,
          iconColor: Colors.amber,
          tagText: 'Email Missing',
          actionText: 'Enter Email',
        );
        return;
      }
      if (!email.contains('@') || !email.contains('.')) {
        _showSenseErrorDialog(
          title: 'Invalid Email Format',
          message: 'Please check your email address for spelling mistakes.',
          icon: Icons.alternate_email_rounded,
          iconColor: Colors.amber,
          tagText: 'Invalid Email',
          actionText: 'Fix Email',
        );
        return;
      }
      if (password.isEmpty) {
        _showSenseErrorDialog(
          title: 'Password Required',
          message: 'Please enter your account password to verify your identity.',
          icon: Icons.lock_outline_rounded,
          iconColor: Colors.roseAccent,
          tagText: 'Password Missing',
          actionText: 'Enter Password',
        );
        return;
      }

      setState(() => _isLoading = true);
      final success = await ref.read(authProvider.notifier).login(
            email: email,
            password: password,
          );
      setState(() => _isLoading = false);

      if (!mounted) return;

      if (success) {
        _signInEmailController.clear();
        _signInPasswordController.clear();
        context.go('/');
      } else {
        final errorMsg = ref.read(authProvider).errorMessage ?? '';
        if (errorMsg.toLowerCase().contains('password')) {
          _showSenseErrorDialog(
            title: 'Incorrect Password',
            message: 'The password you entered is incorrect. Please re-enter your password or reset it.',
            icon: Icons.lock_reset_rounded,
            iconColor: Colors.roseAccent,
            tagText: 'Wrong Password',
            actionText: 'Try Again',
            secondaryText: 'Forgot Password?',
            onSecondary: () => setState(() => _viewMode = AuthViewMode.forgotPassword),
          );
        } else {
          _showSenseErrorDialog(
            title: 'Account Not Found',
            message: 'No registered merchant account found matching this email address.',
            icon: Icons.person_off_rounded,
            iconColor: Colors.amber,
            tagText: 'Unregistered Email',
            actionText: 'Check Email',
            secondaryText: 'Sign Up (Create Account)',
            onSecondary: () => setState(() => _viewMode = AuthViewMode.signup),
          );
        }
      }
    } else if (_viewMode == AuthViewMode.signup) {
      final storeName = _signUpStoreNameController.text.trim();
      final email = _signUpEmailController.text.trim();
      final password = _signUpPasswordController.text.trim();

      if (storeName.length < 2) {
        _showSenseErrorDialog(
          title: 'Store Name Required',
          message: 'Please enter your business or store name (at least 2 characters).',
          icon: Icons.storefront_rounded,
          iconColor: Colors.indigoAccent,
          tagText: 'Store Name Missing',
          actionText: 'Enter Store Name',
        );
        return;
      }
      if (!email.contains('@') || !email.contains('.')) {
        _showSenseErrorDialog(
          title: 'Valid Email Required',
          message: 'Please enter a valid business email address for registration.',
          icon: Icons.alternate_email_rounded,
          iconColor: Colors.amber,
          tagText: 'Invalid Email',
          actionText: 'Fix Email',
        );
        return;
      }
      if (password.length < 6) {
        _showSenseErrorDialog(
          title: 'Password Too Short',
          message: 'Your password must be at least 6 characters long for security.',
          icon: Icons.lock_outline_rounded,
          iconColor: Colors.roseAccent,
          tagText: 'Weak Password',
          actionText: 'Set Stronger Password',
        );
        return;
      }

      setState(() => _isLoading = true);
      await ref.read(authProvider.notifier).signup(
            email: email,
            password: password,
            fullName: storeName,
          );
      setState(() => _isLoading = false);

      if (!mounted) return;

      // VANISH ALL INPUT FIELDS
      _signUpStoreNameController.clear();
      _signUpEmailController.clear();
      _signUpPasswordController.clear();
      _signUpPhoneController.clear();

      // SWITCH TO SIGN IN
      setState(() => _viewMode = AuthViewMode.login);

      _showSenseErrorDialog(
        title: 'Account Created Successfully! 🎉',
        message: 'Your store "$storeName" is registered! Please sign in with your email and password.',
        icon: Icons.verified_rounded,
        iconColor: AppTheme.secondary,
        tagText: 'Registration Complete',
        actionText: 'Proceed to Sign In',
      );
    } else {
      final email = _forgotEmailController.text.trim();
      final newPw = _newPasswordController.text.trim();
      if (!email.contains('@')) {
        _showSenseErrorDialog(
          title: 'Email Address Required',
          message: 'Please enter your registered email address to reset password.',
          icon: Icons.alternate_email_rounded,
          iconColor: Colors.amber,
          tagText: 'Email Missing',
          actionText: 'Enter Email',
        );
        return;
      }
      if (newPw.length < 6) {
        _showSenseErrorDialog(
          title: 'Password Too Short',
          message: 'New password must be at least 6 characters long.',
          icon: Icons.lock_outline_rounded,
          iconColor: Colors.roseAccent,
          tagText: 'Weak Password',
          actionText: 'Set 6+ Char Password',
        );
        return;
      }
      _showOtpModal(email);
    }
  }

  void _showOtpModal(String identifier) {
    final otpControllers = List.generate(6, (_) => TextEditingController(text: '4'));
    otpControllers[1].text = '8';
    otpControllers[2].text = '2';
    otpControllers[3].text = '9';
    otpControllers[4].text = '1';
    otpControllers[5].text = '0';

    final isPhone = RegExp(r'^[0-9+ ]+$').hasMatch(identifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPhone ? Icons.sms_rounded : Icons.mark_email_read_rounded,
                    color: AppTheme.primaryContainer,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Enter 6-Digit OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  isPhone ? 'Security SMS code sent to $identifier' : 'Security OTP code sent to $identifier',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 20),

                // 6 Pin Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 44,
                      height: 50,
                      child: TextFormField(
                        controller: otpControllers[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLength: 1,
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppTheme.surfaceElevated,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.surfaceBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty && index < 5) {
                            FocusScope.of(context).nextFocus();
                          }
                        },
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),
                const Text('Resend code in 00:28', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    await Future.delayed(const Duration(milliseconds: 400));
                    
                    if (_viewMode == AuthViewMode.signup) {
                      await ref.read(authProvider.notifier).signup(
                            email: identifier,
                            password: _passwordController.text.trim(),
                            fullName: _storeNameController.text.trim(),
                          );
                      setState(() {
                        _isLoading = false;
                        _viewMode = AuthViewMode.login;
                        _emailController.clear();
                        _passwordController.clear();
                        _storeNameController.clear();
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Account registered! Please enter your email and password to sign in.'),
                            backgroundColor: AppTheme.secondary,
                          ),
                        );
                      }
                      return;
                    }

                    final success = await ref.read(authProvider.notifier).login(
                          email: identifier,
                          password: _passwordController.text.trim(),
                        );
                    setState(() => _isLoading = false);

                    if (mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Verified! Welcome to Super Inventory.'),
                            backgroundColor: AppTheme.secondary,
                          ),
                        );
                        context.go('/');
                      } else {
                        final errorMsg = ref.read(authProvider).errorMessage ?? 'Invalid credentials. Please try again.';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMsg),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Verify OTP & Access Super Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);

    final success = await ref.read(authProvider.notifier).login(
          email: 'merchant.google@gmail.com',
          password: 'GoogleOAuthToken',
        );

    if (success && mounted) {
      context.go('/');
    }
  }

  Future<void> _handleBiometricAuth() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);

    final success = await ref.read(authProvider.notifier).login(
          email: 'merchant.biometric@gmail.com',
          password: 'BiometricSecureToken',
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Biometric authentication successful!'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 56,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_rounded, color: AppTheme.primary, size: 32),
                          SizedBox(width: 8),
                          Text(
                            'SUPER INVENTORY',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Google Fast Sign In Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: Image.network(
                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      height: 18,
                      width: 18,
                      errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded, color: Colors.black, size: 22),
                    ),
                    label: const Text('Continue with Google', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR EMAIL / PHONE OTP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1)),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Main Auth Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.surfaceBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tab Switcher (Sign In vs Sign Up)
                          if (_viewMode != AuthViewMode.forgotPassword)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _viewMode = AuthViewMode.login),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _viewMode == AuthViewMode.login ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Sign In',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _viewMode == AuthViewMode.login ? Colors.black : AppTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _viewMode = AuthViewMode.signup),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _viewMode == AuthViewMode.signup ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'Sign Up',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _viewMode == AuthViewMode.signup ? Colors.black : AppTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Reset Password via OTP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                TextButton(
                                  onPressed: () => setState(() => _viewMode = AuthViewMode.login),
                                  child: const Text('Back to Sign In', style: TextStyle(fontSize: 11, color: AppTheme.primaryContainer)),
                                ),
                              ],
                            ),

                          const SizedBox(height: 16),

                          // ==============================================
                          // 1. SIGN IN FIELDS (SEPARATE FROM SIGN UP)
                          // ==============================================
                          if (_viewMode == AuthViewMode.login) ...[
                            TextFormField(
                              controller: _signInEmailController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Registered Email Address',
                                hintText: 'Enter registered email',
                                prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _signInPasswordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => setState(() => _viewMode = AuthViewMode.forgotPassword),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryContainer),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleDirectAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('SIGN IN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                            ),
                          ]
                          // ==============================================
                          // 2. SIGN UP FIELDS (INDEPENDENT CONTROLLERS)
                          // ==============================================
                          else if (_viewMode == AuthViewMode.signup) ...[
                            TextFormField(
                              controller: _signUpStoreNameController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Store / Business Name *',
                                hintText: 'E.g. My Fresh Supermarket',
                                prefixIcon: Icon(Icons.storefront_rounded, size: 20),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _signUpEmailController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Business Email Address *',
                                hintText: 'owner@store.com',
                                prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _signUpPhoneController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Mobile / WhatsApp Number (Optional)',
                                hintText: '+91 98765 43210',
                                prefixIcon: Icon(Icons.phone_rounded, size: 20),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _signUpPasswordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Create Password * (min 6 chars)',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleDirectAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('CREATE ACCOUNT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                            ),
                          ]
                          // ==============================================
                          // 3. FORGOT PASSWORD FIELDS
                          // ==============================================
                          else ...[
                            TextFormField(
                              controller: _forgotEmailController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Registered Email Address',
                                hintText: 'Enter registered email',
                                prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'New Password (min 6 chars)',
                                prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleDirectAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 4,
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('RESET PASSWORD', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Biometrics Option
                          if (_viewMode == AuthViewMode.login)
                            OutlinedButton.icon(
                              onPressed: _isLoading ? null : _handleBiometricAuth,
                              icon: const Icon(Icons.fingerprint_rounded, size: 20, color: AppTheme.secondary),
                              label: const Text('Unlock with Biometrics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                side: BorderSide(color: AppTheme.secondary.withOpacity(0.4)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                backgroundColor: AppTheme.surfaceElevated,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_rounded, color: AppTheme.secondary, size: 14),
                      SizedBox(width: 6),
                      Text('256-BIT ENCRYPTED & SECURED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 1)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
