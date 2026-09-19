import 'package:flutter/material.dart';
import '../services/auth_api.dart';
import 'admin/admin_home.dart';
import 'ForgotPasswordScreen.dart';
import 'homeScreen.dart';
import 'signup.dart';
import 'splash.dart';

enum UserRole { admin, student }

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.role, super.key});

  final UserRole role;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(role == UserRole.admin ? 'Admin Dashboard' : 'Dashboard'),
    ),
    body: Center(
      child: Text(
        role == UserRole.admin ? 'Welcome, Admin' : 'Welcome, Student',
        style: const TextStyle(fontSize: 20),
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      key: const ValueKey('login'),
      body: Stack(
        children: [
          SizedBox(
            height: 249,
            width: double.infinity,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFF1D316C)),
              child: Stack(
                children: [
                  const Positioned.fill(child: DotPattern()),
                  SafeArea(
                    child: Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 28),
                          const ShieldMark(size: 64),
                          const SizedBox(height: 14),
                          const Text(
                            'EduTrust Academy',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.45,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            top: 221,
            child: Container(color: const Color(0xFFF6F8FC)),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 21,
              right: 21,
              top: 221,
              bottom: 24 + bottomInset,
            ),
            child: Column(
              children: [
                _LoginCard(
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  errorMessage: _errorMessage,
                  loading: _loading,
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onLogin: _login,
                ),
                const SizedBox(height: 164),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 17,
                      color: Color(0xFF36A16B),
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Protected institutional device session',
                      style: TextStyle(color: Color(0xFF68717F), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: 128,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC7CED8),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Enter your username and password.');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      try {
        await AuthApi.adminLogin(username: username, password: password);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const AdminHomeScreen()),
        );
        return;
      } on AuthApiException {
        await AuthApi.login(username: username, password: password);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.errorMessage,
    required this.loading,
    required this.onTogglePassword,
    required this.onLogin,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final String? errorMessage;
  final bool loading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 25, 24, 27),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFD9DEE6)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x120F224C),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Student Login',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: Color(0xFF202124),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Use the username and password given by your institute',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Color(0xFF626872),
          ),
        ),
        const SizedBox(height: 23),
        const _FieldLabel('Username'),
        const SizedBox(height: 7),
        _InputField(
          controller: usernameController,
          prefixIcon: Icons.alternate_email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 17),
        const _FieldLabel('Password'),
        const SizedBox(height: 7),
        _InputField(
          controller: passwordController,
          prefixIcon: Icons.lock_outline,
          obscureText: obscurePassword,
          suffixIcon: IconButton(
            onPressed: onTogglePassword,
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: const Color(0xFF68778C),
              size: 21,
            ),
            tooltip: obscurePassword ? 'Show password' : 'Hide password',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 44,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D316C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Login',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(errorMessage!, style: const TextStyle(color: Color(0xFFB3261E))),
        ],
        const SizedBox(height: 23),
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const SignupScreen()),
            ),
            child: const Text(
              'Don\'t have an account? Sign up',
              style: TextStyle(color: Color(0xFF3781AA), fontSize: 13),
            ),
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ForgotPasswordScreen(),
              ),
            ),
            child: const Text.rich(
              TextSpan(
                style: TextStyle(color: Color(0xFF3781AA), fontSize: 13),
                children: [
                  TextSpan(text: 'Forgot password?'),
                  TextSpan(
                    text: '  •  ',
                    style: TextStyle(color: Color(0xFFB2BAC4)),
                  ),
                  TextSpan(text: 'Contact your institute'),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xFF36393E),
    ),
  );
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF3F4650),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(prefixIcon, size: 20, color: const Color(0xFF68778C)),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFC9D2DE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1D316C), width: 1.5),
        ),
      ),
    ),
  );
}
