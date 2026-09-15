import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import 'login.dart';
import 'signup.dart';
import 'splash.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    required this.email,
    required this.username,
    super.key,
  });

  final String email;
  final String username;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeControllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());
  Timer? _timer;
  int _seconds = 48;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 48);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) return timer.cancel();
      if (mounted) setState(() => _seconds--);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F8FC),
    body: Stack(
      children: [
        SizedBox(
          height: 287,
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
                        const SizedBox(height: 55),
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
                          'Verify your institutional email',
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
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(21, 231, 21, 90),
          child: _VerificationCard(
            email: widget.email,
            controllers: _codeControllers,
            focusNodes: _focusNodes,
            seconds: _seconds,
            loading: _loading,
            errorMessage: _errorMessage,
            onChanged: _onCodeChanged,
            onVerify: _verify,
            onResend: _resend,
            onBack: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const SignupScreen()),
            ),
          ),
        ),
        const Positioned(
          bottom: 28,
          left: 0,
          right: 0,
          child: _ProtectedSession(),
        ),
      ],
    ),
  );

  void _onCodeChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (var i = 0; i < digits.length && index + i < 4; i++) {
        _codeControllers[index + i].text = digits[i];
      }
      final next = (index + digits.length).clamp(0, 3);
      _focusNodes[next].requestFocus();
    } else if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _verify() async {
    final code = _codeControllers.map((controller) => controller.text).join();
    if (code.length != 4) {
      setState(() => _errorMessage = 'Enter the 4-digit verification code.');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await AuthApi.verifyEmail(username: widget.username, code: code);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified. Please sign in.')),
      );
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_seconds > 0 || _loading) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await AuthApi.resendEmail(username: widget.username);
      _startTimer();
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.email,
    required this.controllers,
    required this.focusNodes,
    required this.seconds,
    required this.loading,
    required this.errorMessage,
    required this.onChanged,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
  });

  final String email;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final int seconds;
  final bool loading;
  final String? errorMessage;
  final void Function(int, String) onChanged;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 26, 24, 27),
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
          'Enter Verification Code',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: Color(0xFF202124),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'We have sent a 4-digit verification code to\nyour institutional email:',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Color(0xFF626872),
          ),
        ),
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FA),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mail_outline,
                size: 16,
                color: Color(0xFF3781AA),
              ),
              const SizedBox(width: 8),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF263B5D),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.edit_outlined,
                size: 15,
                color: Color(0xFF3781AA),
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          '4-DIGIT SECURITY CODE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: Color(0xFF68717F),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(
            4,
            (index) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 3 ? 0 : 14),
                child: TextField(
                  controller: controllers[index],
                  focusNode: focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  onChanged: (value) => onChanged(index, value),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFC9D2DE)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF1D316C),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 14, color: Color(0xFF68717F)),
            const SizedBox(width: 7),
            Text(
              seconds > 0
                  ? 'Resend in 0:${seconds.toString().padLeft(2, '0')}s'
                  : "Didn't receive the code?",
              style: const TextStyle(fontSize: 12, color: Color(0xFF68717F)),
            ),
            if (seconds == 0)
              TextButton(onPressed: onResend, child: const Text('Resend')),
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            errorMessage!,
            style: const TextStyle(color: Color(0xFFB3261E), fontSize: 13),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : onVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D316C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
                    'Verify & Complete Registration',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back to Sign Up'),
          ),
        ),
      ],
    ),
  );
}

class _ProtectedSession extends StatelessWidget {
  const _ProtectedSession();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(
        Icons.verified_user_outlined,
        size: 17,
        color: Color(0xFF36A16B),
      ),
      const SizedBox(width: 7),
      const Text(
        'Protected institutional device session',
        style: TextStyle(color: Color(0xFF68717F), fontSize: 12),
      ),
    ],
  );
}
