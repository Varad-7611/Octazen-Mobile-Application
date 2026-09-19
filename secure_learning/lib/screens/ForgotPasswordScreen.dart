import 'package:flutter/material.dart';

import 'login.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F8FC),
    body: SafeArea(
      child: Column(
        children: [
          const _ForgotHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
              child: Column(
                children: [
                  const _LockIllustration(),
                  const SizedBox(height: 23),
                  const Text(
                    'Password reset is handled by\nyour institute',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF172034),
                      fontSize: 20,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Self-service password resets are disabled for\nsecurity. Please contact your administration\noffice to verify credentials and receive an access\nkey.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF69717F),
                      fontSize: 13,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 21),
                  const _InstituteCard(),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 39,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.phone_outlined, size: 17),
                      label: const Text(
                        'Call Institute',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF173263),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFD7DDE8)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                    ),
                    child: const Text(
                      '← Back to Student Login',
                      style: TextStyle(color: Color(0xFF28719F), fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 15,
                        color: Color(0xFF269B78),
                      ),
                      SizedBox(width: 26),
                      Text(
                        'Protected institutional device\nsession',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF788291),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ForgotHeader extends StatelessWidget {
  const _ForgotHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 78,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFDDE2EA))),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, size: 26),
          color: const Color(0xFF263753),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28),
          tooltip: 'Back',
        ),
        const SizedBox(width: 12),
        const Text(
          'Forgot Password',
          style: TextStyle(
            color: Color(0xFF1D2B49),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _LockIllustration extends StatelessWidget {
  const _LockIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 104,
    height: 91,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFFF0F2F8),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF6F7DA1),
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A596783),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.lock_outline, color: Colors.white, size: 34),
        ),
        Positioned(
          right: 1,
          bottom: 2,
          child: Container(
            width: 25,
            height: 25,
            decoration: const BoxDecoration(
              color: Color(0xFFFFA719),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.priority_high,
              color: Colors.white,
              size: 17,
            ),
          ),
        ),
      ],
    ),
  );
}

class _InstituteCard extends StatelessWidget {
  const _InstituteCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFFD5DCE7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D102343),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            const _ContactIcon(icon: Icons.shield_outlined),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INSTITUTIONAL AUTHORITY',
                  style: TextStyle(
                    color: Color(0xFF858F9F),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'EduTrust Academy Office',
                  style: TextStyle(
                    color: Color(0xFF243453),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 13),
          child: Divider(height: 1, color: Color(0xFFE8ECF2)),
        ),
        const _ContactRow(
          icon: Icons.phone_outlined,
          label: 'Administration Helpline',
          value: '+1 (800) 555-0199',
          badge: 'Open 8am-5pm',
        ),
        const SizedBox(height: 13),
        const _ContactRow(
          icon: Icons.mail_outline,
          label: 'Student Helpdesk Email',
          value: 'support@edutrust.edu',
        ),
      ],
    ),
  );
}

class _ContactIcon extends StatelessWidget {
  const _ContactIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 35,
    height: 35,
    decoration: BoxDecoration(
      color: const Color(0xFFF0F4FA),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, size: 19, color: const Color(0xFF243E77)),
  );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? badge;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _ContactIcon(icon: icon),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF7A8494), fontSize: 10),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF243453),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      if (badge != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE7FAF1),
            border: Border.all(color: const Color(0xFFBCEED8)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            badge!,
            style: const TextStyle(
              color: Color(0xFF23966F),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    ],
  );
}
