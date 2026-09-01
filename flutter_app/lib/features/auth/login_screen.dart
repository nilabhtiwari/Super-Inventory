import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController(text: 'merchant@gmail.com');
  final _passwordController = TextEditingController(text: 'Merchant@1234');
  final _fullNameController = TextEditingController();

  bool _isLoginTab = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email address is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Please enter a valid email (e.g. name@gmail.com)';
    return null;
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);

    if (mounted) {
      _showOtpModal(email);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
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
    await Future.delayed(const Duration(milliseconds: 600));
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

  void _showOtpModal(String email) {
    final otpControllers = List.generate(6, (_) => TextEditingController());
    final focusNodes = List.generate(6, (_) => FocusNode());
    int secondsLeft = 30;
    Timer? timer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (secondsLeft > 0) {
                setModalState(() => secondsLeft--);
              } else {
                t.cancel();
              }
            });

            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF131520),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(top: BorderSide(color: Color(0xFF2B2F48))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_read_outlined, color: AppTheme.primaryContainer, size: 26),
                  ),
                  const SizedBox(height: 12),
                  const Text('Enter 6-Digit OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Sent to $email', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return SizedBox(
                        width: 44,
                        height: 50,
                        child: TextFormField(
                          controller: otpControllers[i],
                          focusNode: focusNodes[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(1),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: const Color(0xFF1B1E30),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E3352))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && i < 5) focusNodes[i + 1].requestFocus();
                            if (val.isEmpty && i > 0) focusNodes[i - 1].requestFocus();
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    secondsLeft > 0 ? 'Resend code in 00:${secondsLeft.toString().padLeft(2, '0')}' : 'Did not receive code?',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final success = await ref.read(authProvider.notifier).login(
                              email: email,
                              password: _passwordController.text.trim(),
                            );
                        if (success && mounted) context.go('/');
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text('Verify & Continue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => timer?.cancel());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07080C),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // BRAND LOGO HEADER WITH WHITE CAPITAL 'S' + ARROW
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6A00), Color(0xFF1E1035)],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFF6A00).withOpacity(0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6A00).withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'S',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Color(0xFF00D4AA),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SUPER',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'INVENTORY',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'For All Inventory Ecosystem',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8C91B0), fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // FULL-WIDTH CLEAN GOOGLE ONE-TAP BUTTON AT TOP
                    OutlinedButton(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://fonts.gstatic.com/s/i/productlogos/googleg/v6/24px.svg',
                            width: 18,
                            height: 18,
                            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 22, color: Colors.blue),
                          ),
                          const SizedBox(width: 10),
                          const Text('Continue with Google', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Row(
                      children: [
                        Expanded(child: Divider(color: Color(0xFF202334))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('OR EMAIL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF676C8E), letterSpacing: 1)),
                        ),
                        Expanded(child: Divider(color: Color(0xFF202334))),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // SLEEK CARD CONTAINER
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF11131D),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF212538)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tab Switcher
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1D2C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isLoginTab = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _isLoginTab ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Login',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _isLoginTab ? const Color(0xFF11131D) : const Color(0xFF8C91B0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isLoginTab = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: !_isLoginTab ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Sign Up',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: !_isLoginTab ? const Color(0xFF11131D) : const Color(0xFF8C91B0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          if (!_isLoginTab) ...[
                            const Text('Full Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFA5A9C5))),
                            const SizedBox(height: 4),
                            TextFormField(
                              controller: _fullNameController,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF676C8E), size: 18),
                                hintText: 'Rajesh Kumar',
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          const Text('Gmail / Work Email Address', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFA5A9C5))),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.mail_outline_rounded, color: Color(0xFF676C8E), size: 18),
                              hintText: 'merchant@gmail.com',
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Password', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFA5A9C5))),
                              if (_isLoginTab)
                                GestureDetector(
                                  onTap: _handleAuth,
                                  child: const Text('Login via OTP?', style: TextStyle(fontSize: 10, color: AppTheme.primaryContainer, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF676C8E), size: 18),
                              hintText: '••••••••',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF676C8E), size: 18),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // SUBMIT BUTTON
                          SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.mark_email_read_outlined, size: 16),
                                        SizedBox(width: 8),
                                        Text('Send OTP & Verify', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // BIOMETRICS OPTION AT THE BOTTOM OF CARD
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleBiometricAuth,
                            icon: const Icon(Icons.fingerprint_rounded, size: 20, color: AppTheme.secondary),
                            label: const Text('Unlock with Biometrics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFF161926),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              side: const BorderSide(color: Color(0xFF282D42)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 12, color: Color(0xFF34D399)),
                        SizedBox(width: 6),
                        Text('FINGERPRINT, OAUTH2 & OTP ENCRYPTED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF676C8E), letterSpacing: 0.8)),
                      ],
                    ),
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
