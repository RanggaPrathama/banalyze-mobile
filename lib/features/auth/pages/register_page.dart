import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:banalyze/core/constants/app_colors.dart';
import 'package:banalyze/shared/widgets/app_snackbar.dart';
import 'package:banalyze/features/auth/providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.gradientStart;
    final cardColor = isDark ? AppColors.darkCard : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.accent;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : Colors.grey.shade600;
    final fieldFill = isDark ? AppColors.darkSurface : Colors.white;
    final fieldBorder = isDark ? AppColors.darkBorder : Colors.grey.shade200;
    final hintColor = isDark ? AppColors.darkTextHint : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/logo/logo_banalyze.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Create Account',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start your banana analysis journey',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Card form
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                        border: isDark
                            ? Border.all(color: AppColors.darkBorder)
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Error
                          if (auth.error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade900.withValues(
                                  alpha: isDark ? 0.3 : 0.0,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.red.shade700
                                      : Colors.red.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade400,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.error!,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.red.shade300
                                            : Colors.red.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Full Name
                          _label('Full Name', textColor),
                          const SizedBox(height: 8),
                          _field(
                            controller: _nameController,
                            hint: 'Enter your full name',
                            icon: Icons.person_outline_rounded,
                            fillColor: fieldFill,
                            borderColor: fieldBorder,
                            hintColor: hintColor,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),

                          // Email
                          _label('Email', textColor),
                          const SizedBox(height: 8),
                          _field(
                            controller: _emailController,
                            hint: 'Enter your email',
                            icon: Icons.email_outlined,
                            fillColor: fieldFill,
                            borderColor: fieldBorder,
                            hintColor: hintColor,
                            textColor: textColor,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _label('Password', textColor),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: auth.obscurePassword,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration:
                                _decoration(
                                  hint: 'Min. 6 characters',
                                  icon: Icons.lock_outline_rounded,
                                  fillColor: fieldFill,
                                  borderColor: fieldBorder,
                                  hintColor: hintColor,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      auth.obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: hintColor,
                                      size: 20,
                                    ),
                                    onPressed: auth.togglePasswordVisibility,
                                  ),
                                ),
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          _label('Confirm Password', textColor),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: auth.obscureConfirmPassword,
                            style: TextStyle(color: textColor, fontSize: 14),
                            decoration:
                                _decoration(
                                  hint: 'Re-enter your password',
                                  icon: Icons.lock_outline_rounded,
                                  fillColor: fieldFill,
                                  borderColor: fieldBorder,
                                  hintColor: hintColor,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      auth.obscureConfirmPassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: hintColor,
                                      size: 20,
                                    ),
                                    onPressed:
                                        auth.toggleConfirmPasswordVisibility,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                final success = await auth.register(
                                  _nameController.text.trim(),
                                  _emailController.text.trim(),
                                  _passwordController.text,
                                  _confirmPasswordController.text,
                                );
                                if (success && context.mounted) {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/main',
                                  );
                                  AppSnackBar.success(
                                    'Account created successfully!',
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.accent,
                                ),
                              )
                            : Text(
                                'Create Account',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: GoogleFonts.poppins(
                            color: subtextColor,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: Text(
                            'Sign In',
                            style: GoogleFonts.poppins(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color fillColor,
    required Color borderColor,
    required Color hintColor,
    required Color textColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: _decoration(
        hint: hint,
        icon: icon,
        fillColor: fillColor,
        borderColor: borderColor,
        hintColor: hintColor,
      ),
    );
  }

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    required Color fillColor,
    required Color borderColor,
    required Color hintColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
      prefixIcon: Icon(icon, color: hintColor, size: 20),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
