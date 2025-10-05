// lib/screen/login_screen.dart
import 'package:flutter/material.dart';
import 'package:project_app/screen/navbar_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_app/screen/signup_screen.dart';
import 'package:project_app/service/auth_service.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _rememberMe = false;
  bool _obscure = true;
  bool _loading = false;
  final _auth = AuthService();

  late VideoPlayerController _videoCtrl;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _restoreRemembered();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoCtrl = VideoPlayerController.asset('lib/gifs/backlogin.mp4');
    await _videoCtrl.initialize();
    _videoCtrl
      ..setLooping(true)
      ..setVolume(0);
    await _videoCtrl.play();
    if (mounted) setState(() => _videoReady = true);
  }

  Future<void> _restoreRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool('remember_me') ?? false;
    if (remembered) {
      _emailCtrl.text = prefs.getString('remember_email') ?? '';
      _rememberMe = true;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  Future<void> _persistRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', _rememberMe);
    if (_rememberMe) {
      await prefs.setString('remember_email', _emailCtrl.text.trim());
    } else {
      await prefs.remove('remember_email');
    }
  }

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.signInWithEmail(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
      await _persistRememberMe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NavbarScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เข้าสู่ระบบไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกอีเมลก่อน')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่งลิงก์รีเซ็ตรหัสผ่านไปที่ $email แล้ว')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่งอีเมลรีเซ็ตไม่สำเร็จ: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in ล้มเหลว: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGithub() async {
    setState(() => _loading = true);
    try {
      await _auth.signInWithGithub();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เข้าสู่ระบบด้วย GitHub สำเร็จ')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NavbarScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GitHub sign-in ล้มเหลว: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      border: InputBorder.none,
      contentPadding: const EdgeInsets.only(top: 14.0),
      prefixIcon: Icon(icon, color: const Color.fromARGB(255, 3, 136, 154)),
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontFamily: 'OpenSans'),
    );
  }

  /// 🎥 วิดีโอพื้นหลังเต็มจอด้วย FittedBox + AspectRatio
  Widget _buildVideoBackground() {
    if (!_videoReady) return const SizedBox.shrink();
    return Positioned.fill(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoCtrl.value.size.width,
          height: _videoCtrl.value.size.height,
          child: AspectRatio(
            aspectRatio: _videoCtrl.value.aspectRatio,
            child: VideoPlayer(_videoCtrl),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildVideoBackground(),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.45)),
            ),
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 120.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'OpenSans',
                        fontSize: 30.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30.0),

                    // Email
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Email',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'OpenSans',
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Container(
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6.0, offset: Offset(0, 2)),
                            ],
                          ),
                          height: 60.0,
                          child: TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.black87, fontFamily: 'OpenSans'),
                            decoration: _inputDecoration(hint: 'Enter your Email', icon: Icons.email),
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return 'กรุณากรอกอีเมล';
                              final emailRegex = RegExp(r'^.+@.+\..+$');
                              if (!emailRegex.hasMatch(value)) return 'อีเมลไม่ถูกต้อง';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    // Password
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 30.0),
                        const Text(
                          'Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'OpenSans',
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Container(
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6.0, offset: Offset(0, 2)),
                            ],
                          ),
                          height: 60.0,
                          child: TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            style: const TextStyle(color: Colors.black87, fontFamily: 'OpenSans'),
                            decoration: _inputDecoration(
                              hint: 'Enter your Password',
                              icon: Icons.lock,
                              suffix: IconButton(
                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) {
                              final value = v ?? '';
                              if (value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                              if (value.length < 6) return 'รหัสผ่านต้องอย่างน้อย 6 ตัวอักษร';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10.0),

                    // Remember + Forgot
                    Row(
                      children: <Widget>[
                        Theme(
                          data: ThemeData(unselectedWidgetColor: Colors.white),
                          child: Checkbox(
                            value: _rememberMe,
                            checkColor: const Color(0xFF00479A),
                            activeColor: Colors.white,
                            onChanged: (value) => setState(() => _rememberMe = value ?? false),
                          ),
                        ),
                        const Text(
                          'Remember Me',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'OpenSans',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _loading ? null : _onForgotPassword,
                          child: const Text(
                            'Forgot Password?',
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

                    // Login button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 25.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _onLoginPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00479A),
                            padding: const EdgeInsets.all(15.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'LOGIN',
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
                    ),

                    // Divider
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Colors.white70)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text('or continue with', style: TextStyle(color: Colors.white70)),
                        ),
                        Expanded(child: Divider(color: Colors.white70)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // SSO
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _SsoButton(
                          label: 'Google',
                          icon: Icons.g_mobiledata,
                          onTap: _loading ? null : _signInWithGoogle,
                          background: Colors.white,
                          foreground: Colors.black87,
                        ),
                        _SsoButton(
                          label: 'GitHub',
                          icon: Icons.code,
                          onTap: _loading ? null : _signInWithGithub,
                          background: Colors.black,
                          foreground: Colors.white,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20.0),

                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const SignupScreen()),
                              );
                            },
                      child: const Text(
                        'Sign Up',
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
          ],
        ),
      ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
    );
  }
}
