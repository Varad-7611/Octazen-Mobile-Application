import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import 'login.dart';
import 'otp_verification.dart';
import 'splash.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final controller in [
      _fullName,
      _mobile,
      _email,
      _username,
      _password,
      _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
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
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Create your student account',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 15,
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
            padding: EdgeInsets.fromLTRB(21, 221, 21, 24 + bottomInset),
            child: _SignupCard(
              formKey: _formKey,
              fullName: _fullName,
              mobile: _mobile,
              email: _email,
              username: _username,
              password: _password,
              confirmPassword: _confirmPassword,
              hidePassword: _hidePassword,
              hideConfirmPassword: _hideConfirmPassword,
              loading: _loading,
              errorMessage: _errorMessage,
              onTogglePassword: () =>
                  setState(() => _hidePassword = !_hidePassword),
              onToggleConfirmPassword: () =>
                  setState(() => _hideConfirmPassword = !_hideConfirmPassword),
              onSubmit: _signup,
              onLogin: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await AuthApi.signup(
        fullName: _fullName.text.trim(),
        mobile: _mobile.text.trim(),
        email: _email.text.trim(),
        username: _username.text.trim(),
        password: _password.text,
        confirmPassword: _confirmPassword.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OtpVerificationScreen(
            email: _email.text.trim(),
            username: _username.text.trim().toLowerCase(),
          ),
        ),
      );
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _SignupCard extends StatelessWidget {
  const _SignupCard({
    required this.formKey,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.username,
    required this.password,
    required this.confirmPassword,
    required this.hidePassword,
    required this.hideConfirmPassword,
    required this.loading,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
    required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController fullName;
  final TextEditingController mobile;
  final TextEditingController email;
  final TextEditingController username;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final bool hidePassword;
  final bool hideConfirmPassword;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSubmit;
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
    child: Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Sign Up',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            'Enter your details registered with your institute\nto activate access',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF626872),
            ),
          ),
          const SizedBox(height: 23),
          _labelledField(
            'Full Name',
            fullName,
            Icons.person_outline,
            'e.g. Alex Turner',
          ),
          _labelledField(
            'Mobile',
            mobile,
            Icons.phone_outlined,
            'e.g. +91 98765 43210',
            keyboardType: TextInputType.phone,
          ),
          _labelledField(
            'Username',
            username,
            Icons.alternate_email,
            'e.g. alex.turner24',
          ),
          _labelledField(
            'Institutional Email',
            email,
            Icons.mail_outline,
            'alex.turner@edutrust.edu',
            keyboardType: TextInputType.emailAddress,
          ),
          _labelledField(
            'Enter Password',
            password,
            Icons.lock_outline,
            'Create secure password',
            obscureText: hidePassword,
            suffix: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          _labelledField(
            'Confirm Password',
            confirmPassword,
            Icons.verified_user_outlined,
            'Re-enter your password',
            obscureText: hideConfirmPassword,
            suffix: IconButton(
              onPressed: onToggleConfirmPassword,
              icon: Icon(
                hideConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            validator: (value) =>
                value != password.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
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
                      'Create Account',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              errorMessage!,
              style: const TextStyle(color: Color(0xFFB3261E)),
            ),
          ],
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: onLogin,
              child: const Text('Already have an account? Sign in'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _labelledField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF36393E),
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator:
              validator ??
              (value) => value == null || value.trim().isEmpty
                  ? 'This field is required'
                  : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF68778C)),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFC9D2DE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF1D316C),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
