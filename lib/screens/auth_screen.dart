import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPass = TextEditingController();
  final _signupConfirm = TextEditingController();
  bool _obscureLogin = true;
  bool _obscureSignup = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmail.dispose();
    _loginPass.dispose();
    _signupName.dispose();
    _signupEmail.dispose();
    _signupPass.dispose();
    _signupConfirm.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginEmail.text.isEmpty || _loginPass.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    final provider = context.read<AppProvider>();
    final err = await provider.signIn(_loginEmail.text.trim(), _loginPass.text);
    if (err != null) {
      setState(() => _error = err);
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _signup() async {
    if (_signupName.text.isEmpty || _signupEmail.text.isEmpty ||
        _signupPass.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    if (_signupPass.text != _signupConfirm.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (_signupPass.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    final provider = context.read<AppProvider>();
    final err = await provider.signUp(
        _signupEmail.text.trim(), _signupPass.text, _signupName.text.trim());
    if (err != null) {
      setState(() => _error = err);
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.insights_rounded, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text('InsightBoard',
                    style: GoogleFonts.inter(
                      fontSize: 28, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('AI-Powered Business Intelligence',
                    style: GoogleFonts.inter(
                      fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Sign In'),
                        Tab(text: 'Sign Up'),
                      ],
                      onTap: (_) => setState(() => _error = null),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13))),
                        ],
                      ),
                    ),

                  // Forms
                  SizedBox(
                    height: _tabController.index == 0 ? 240 : 340,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Login form
                        Column(
                          children: [
                            TextField(
                              controller: _loginEmail,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.email_outlined),
                                hintText: 'Email address',
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _loginPass,
                              obscureText: _obscureLogin,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outlined),
                                hintText: 'Password',
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureLogin
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined, size: 20),
                                  onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {/* forgot password */},
                                child: const Text('Forgot Password?', style: TextStyle(fontSize: 13)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: provider.isLoading ? null : _login,
                                child: provider.isLoading
                                    ? const SizedBox(width: 20, height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Sign In'),
                              ),
                            ),
                          ],
                        ),
                        // Signup form
                        Column(
                          children: [
                            TextField(
                              controller: _signupName,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outlined),
                                hintText: 'Full name',
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _signupEmail,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.email_outlined),
                                hintText: 'Email address',
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _signupPass,
                              obscureText: _obscureSignup,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outlined),
                                hintText: 'Password',
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureSignup
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined, size: 20),
                                  onPressed: () => setState(() => _obscureSignup = !_obscureSignup),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _signupConfirm,
                              obscureText: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.lock_outlined),
                                hintText: 'Confirm password',
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: provider.isLoading ? null : _signup,
                                child: provider.isLoading
                                    ? const SizedBox(width: 20, height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Create Account'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
