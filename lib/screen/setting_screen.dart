import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({
    super.key,
    this.appVersion = '1.0.0',
    this.onLogout,               // callback ออกจากระบบ (ถ้าไม่ส่ง จะขึ้น SnackBar แทน)
    this.onDeleteAccount,        // callback ลบบัญชี (ถ้าไม่ส่ง จะขึ้น SnackBar แทน)
  });

  final String appVersion;
  final VoidCallback? onLogout;
  final VoidCallback? onDeleteAccount;

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  // -- Mock user (ต่อ backend ได้ภายหลัง) --
  String _name = 'Tanongsak B';
  String _email = 'jateva01@gmail.com';
  Uint8List? _avatarBytes; // ใช้ bytes หรือดึงจาก url จริงได้

  // -- Preferences --
  bool _darkMode = false;
  String _language = 'ไทย';
  bool _pushNoti = true;
  bool _emailNoti = false;

  // -- Privacy --
  bool _shareLocation = false;
  bool _publicProfile = true;

  final _picker = ImagePicker();

  static const _bg = Color(0xFFE7F3EE);
  static const _teal = Color(0xFF1CA8A4);

  Future<void> _pickAvatar() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() => _avatarBytes = bytes);
  }

  Future<void> _changeName() async {
    final ctrl = TextEditingController(text: _name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เปลี่ยนชื่อ'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'กรอกชื่อใหม่'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('บันทึก')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      setState(() => _name = newName);
    }
  }

  Future<void> _changeEmail() async {
    final ctrl = TextEditingController(text: _email);
    final newEmail = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เปลี่ยนอีเมล'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'example@mail.com'),
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('บันทึก')),
        ],
      ),
    );
    if (newEmail != null && newEmail.isNotEmpty) {
      setState(() => _email = newEmail);
    }
  }

  Future<void> _pickLanguage() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('ไทย'),
              onTap: () => Navigator.pop(ctx, 'ไทย'),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('English'),
              onTap: () => Navigator.pop(ctx, 'English'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _language = result);
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ไปหน้าเปลี่ยนรหัสผ่าน (เชื่อมต่อภายหลัง)')),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ออกจากระบบ')),
        ],
      ),
    );
    if (ok == true) {
      if (widget.onLogout != null) {
        widget.onLogout!();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out (mock). Hook your auth here.')),
        );
        Navigator.pop(context); // กลับหน้าเดิม
      }
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบบัญชี'),
        content: const Text('การลบบัญชีจะไม่สามารถย้อนกลับได้ คุณแน่ใจหรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบถาวร'),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (widget.onDeleteAccount != null) {
        widget.onDeleteAccount!();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted (mock). Connect API here.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('การตั้งค่า'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          // ----- โปรไฟล์ -----
          _SectionTitle('บัญชีผู้ใช้'),
          _CardWrap(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: SizedBox(
                            width: 60, height: 60,
                            child: _avatarBytes == null
                                ? const Icon(Icons.account_circle, size: 60, color: Colors.black26)
                                : Image.memory(_avatarBytes!, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0, bottom: 0,
                        child: InkWell(
                          onTap: _pickAvatar,
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black87, shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(_email, style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _Tile(
              icon: Icons.lock_outline,
              title: 'เปลี่ยนรหัสผ่าน',
              onTap: _changePassword,
            ),
          ]),

          // ----- เกี่ยวกับ -----
          const SizedBox(height: 16),
          _SectionTitle('เกี่ยวกับแอป'),
          _CardWrap(children: [
            _Tile(
              icon: Icons.info_outline,
              title: 'เวอร์ชันแอป',
              trailing: Text(widget.appVersion, style: const TextStyle(color: Colors.black54)),
            ),
            const Divider(height: 1),
            _Tile(
              icon: Icons.description_outlined,
              title: 'เงื่อนไขการใช้งาน',
              onTap: () => _openSnack('Terms & Conditions'),
            ),
            const Divider(height: 1),
            _Tile(
              icon: Icons.privacy_tip_outlined,
              title: 'นโยบายความเป็นส่วนตัว',
              onTap: () => _openSnack('Privacy Policy'),
            ),
            const Divider(height: 1),
            _Tile(
              icon: Icons.code_outlined,
              title: 'โอเพนซอร์ซไลเซนส์',
              onTap: () => showLicensePage(context: context, applicationName: 'Your App'),
            ),
          ]),

          // ----- Logout / Delete -----
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('ออกจากระบบ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _confirmDelete,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบบัญชี'),
          ),
        ],
      ),
    );
  }

  void _openSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// ----------------- UI helpers -----------------
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black54),
      ),
    );
  }
}

class _CardWrap extends StatelessWidget {
  const _CardWrap({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
      dense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      secondary: Icon(icon, color: Colors.black54),
      title: Text(title),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}
