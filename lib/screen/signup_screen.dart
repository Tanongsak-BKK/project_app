import 'package:flutter/material.dart';
import 'package:project_app/screen/login_screen.dart';

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
  }) {
    return InputDecoration(
      border: InputBorder.none,
      contentPadding: const EdgeInsets.only(top: 14.0),
      prefixIcon: Icon(icon, color: const Color.fromARGB(255, 3, 136, 154)),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontFamily: 'OpenSans'),
    );
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
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 120.0),
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
                      decoration: _inputDec(hint: 'Enter your Username', icon: Icons.person),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please enter username' : null,
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
                      decoration: _inputDec(hint: 'Enter your Email', icon: Icons.email),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Invalid email' : null,
                    ),
                  ),

                  const SizedBox(height: 10.0),

                  // Password
                  _buildLabel("Password"),
                  _FieldBox(
                    child: TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure1,
                      decoration: _inputDec(hint: 'Enter your Password', icon: Icons.lock).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure1 = !_obscure1),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'Password too short' : null,
                    ),
                  ),

                  const SizedBox(height: 10.0),

                  // Confirm Password
                  _buildLabel("Confirm Password"),
                  _FieldBox(
                    child: TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscure2,
                      decoration: _inputDec(
                              hint: 'Re-enter your Password', icon: Icons.lock_outline)
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure2 = !_obscure2),
                        ),
                      ),
                      validator: (v) =>
                          (v != _passwordCtrl.text) ? 'Passwords do not match' : null,
                    ),
                  ),

                  const SizedBox(height: 20.0),

                  // Sign up button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          // TODO: call API / Firebase Signup
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Signing up...')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 71, 154),
                        padding: const EdgeInsets.all(15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: const Text(
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
                ],
              ),
            ),
          ),

          // Back button (ไปหน้า Login)
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
          BoxShadow(color: Colors.black12, blurRadius: 6.0, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}
