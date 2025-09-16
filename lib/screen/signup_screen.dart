import 'package:flutter/material.dart';
import 'package:project_app/screen/login_screen.dart';
import 'package:project_app/screen/navbar_screen.dart';
import 'package:project_app/service/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _agreeTos = false;
  bool _loading = false;

  final _auth = AuthService();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDec({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      border: InputBorder.none,
      contentPadding: const EdgeInsets.only(top: 14.0),
      prefixIcon: Icon(icon, color: const Color.fromARGB(255, 3, 136, 154)),
      hintText: hint,
      suffixIcon: suffix,
      hintStyle: const TextStyle(color: Colors.black38, fontFamily: 'OpenSans'),
    );
  }

  Future<void> _onEmailSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณายอมรับข้อกำหนดการใช้งาน')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.signUpWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        displayName: _usernameCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('สมัครสมาชิกสำเร็จ')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign up failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      await _auth.signInWithGoogle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เข้าสู่ระบบด้วย Google สำเร็จ')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NavbarScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google sign-in ล้มเหลว: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithGithub() async {
    setState(() => _loading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed up with GitHub (mock)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('GitHub sign up failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // BG gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 0, 71, 154),
                  Color.fromARGB(255, 3, 136, 154),
                  Color.fromARGB(255, 19, 238, 154),
                ],
                stops: [0.1, 0.4, 0.8],
              ),
            ),
          ),

          // เนื้อหา
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 40.0,
              vertical: 120.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'OpenSans',
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30.0),

                  // Username
                  _buildLabel("Username"),
                  _FieldBox(
                    child: TextFormField(
                      controller: _usernameCtrl,
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                      decoration: _inputDec(
                        hint: 'Enter your Username',
                        icon: Icons.person,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter username'
                          : (v.trim().length < 3
                                ? 'Username must be at least 3 chars'
                                : null),
                    ),
                  ),

                  const SizedBox(height: 10.0),

                  // Email
                  _buildLabel("Email"),
                  _FieldBox(
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDec(
                        hint: 'Enter your Email',
                        icon: Icons.email,
                      ),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Please enter email';
                        final emailRegex = RegExp(
                          r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
                        );
                        if (!emailRegex.hasMatch(value)) return 'Invalid email';
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 10.0),

                  // Password
                  _buildLabel("Password"),
                  _FieldBox(
                    child: TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure1,
                      decoration:
                          _inputDec(
                            hint: 'Enter your Password',
                            icon: Icons.lock,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure1
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure1 = !_obscure1),
                            ),
                          ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Password must be at least 6 chars'
                          : null,
                    ),
                  ),

                  const SizedBox(height: 10.0),

                  // Confirm Password
                  _buildLabel("Confirm Password"),
                  _FieldBox(
                    child: TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscure2,
                      decoration:
                          _inputDec(
                            hint: 'Re-enter your Password',
                            icon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure2
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure2 = !_obscure2),
                            ),
                          ),
                      validator: (v) => (v != _passwordCtrl.text)
                          ? 'Passwords do not match'
                          : null,
                    ),
                  ),

                  const SizedBox(height: 10.0),

                  // Agree TOS
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeTos,
                        onChanged: (v) =>
                            setState(() => _agreeTos = v ?? false),
                        activeColor: Colors.white,
                        checkColor: const Color.fromARGB(255, 0, 71, 154),
                      ),
                      const Expanded(
                        child: Text(
                          'I agree to the Terms of Service and Privacy Policy',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10.0),

                  // Sign up button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _onEmailSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 71, 154),
                        padding: const EdgeInsets.all(15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'SIGN UP',
                              style: TextStyle(
                                color: Colors.white,
                                letterSpacing: 1.5,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Divider
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Colors.white70)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'or sign up with',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white70)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Third-party sign up
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _SsoButton(
                        label: 'Google',
                        icon: Icons.g_mobiledata,
                        onTap: _loading
                            ? null
                            : _signInWithGoogle, // <-- fixed function name
                        background: Colors.white,
                        foreground: Colors.black87,
                      ),
                      _SsoButton(
                        label: 'GitHub',
                        icon: Icons.code,
                        onTap: _loading ? null : _signUpWithGithub,
                        background: Colors.black,
                        foreground: Colors.white,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24.0),

                  // ไปหน้า Login
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                    child: const Text(
                      'Already have an account? Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'OpenSans',
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Back button (กลับไป Login)
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'OpenSans',
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// กล่องครอบ TextField ให้ styling เดียวกัน
class _FieldBox extends StatelessWidget {
  final Widget child;
  const _FieldBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.0,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SsoButton extends StatelessWidget {
  const _SsoButton({
    required this.label,
    required this.icon,
    this.onTap,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
