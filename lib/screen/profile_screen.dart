// lib/screen/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:project_app/screen/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // ฟอร์มแก้ไขโปรไฟล์
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  /// stream เอกสารผู้ใช้ (สร้างถ้ายังไม่มี)
  /// stream เอกสารผู้ใช้ (สร้างถ้ายังไม่มี)
Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream(User user) async* {
  final ref = _db.collection('users').doc(user.uid);
  final snap = await ref.get();
  if (!snap.exists) {
    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? user.email?.split('@').first ?? 'User',
      'photoUrl': user.photoURL,
      'bio': '',
      'location': '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  yield* ref.snapshots();
}


  Future<void> _openEditSheet(Map<String, dynamic> data) async {
    _nameCtrl.text = (data['displayName'] ?? '').toString();
    _bioCtrl.text = (data['bio'] ?? '').toString();
    _locCtrl.text = (data['location'] ?? '').toString();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: _EditCard(
            nameCtrl: _nameCtrl,
            bioCtrl: _bioCtrl,
            locCtrl: _locCtrl,
            onSave: _saveProfile,
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final displayName = _nameCtrl.text.trim();
      final bio = _bioCtrl.text.trim();
      final location = _locCtrl.text.trim();

      // อัปเดต Auth displayName
      if (displayName.isNotEmpty && displayName != (user.displayName ?? '')) {
        await user.updateDisplayName(displayName);
      }

      // อัปเดต Firestore
      final ref = _db.collection('users').doc(user.uid);
      await ref.set({
        'displayName': displayName.isEmpty ? (user.email ?? '') : displayName,
        'bio': bio,
        'location': location,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.of(context).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตโปรไฟล์สำเร็จ')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // โทนธรรมชาติ (เขียว-ฟ้า ไล่เฉด + ลายใบไม้เบา ๆ ด้วย gradient)
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0f9b0f), // green
              Color(0xFF3acfd5), // teal
              Color(0xFF3a7bd5), // blue
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: user == null
              ? const Center(
                  child: Text(
                    'ยังไม่ได้เข้าสู่ระบบ',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                )
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _userDocStream(user),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text('เกิดข้อผิดพลาด: ${snap.error}',
                            style: const TextStyle(color: Colors.white)),
                      );
                    }
                    final data = snap.data?.data() ?? {};
                    final displayName =
                        (data['displayName'] ?? user.displayName ?? 'Your Name').toString();
                    final email = (data['email'] ?? user.email ?? '').toString();
                    final photo = (data['photoUrl'] ?? user.photoURL)?.toString();
                    final bio = (data['bio'] ?? '').toString();
                    final location = (data['location'] ?? '').toString();
                    final ts = data['createdAt'];
                    String since = '';
                    if (ts is Timestamp) {
                      try {
                        since = DateFormat('d MMM y').format(ts.toDate());
                      } catch (_) {}
                    }

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverAppBar(
                          backgroundColor: Colors.transparent,
                          pinned: true,
                          elevation: 0,
                          title: const Text('Profile', style: TextStyle(color: Colors.white)),
                          
                        ),

                        // Header card
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: _GlassCard(
                              child: Column(
                                children: [
                                  const SizedBox(height: 18),
                                  CircleAvatar(
                                    radius: 44,
                                    backgroundColor: Colors.white.withOpacity(.2),
                                    backgroundImage:
                                        photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
                                    child: (photo == null || photo.isEmpty)
                                        ? const Icon(Icons.person, color: Colors.white, size: 48)
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Opacity(
                                    opacity: .85,
                                    child: Text(
                                      email,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  if (since.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Opacity(
                                      opacity: .8,
                                      child: Text(
                                        'เข้าร่วมเมื่อ $since',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                   
                                  ),
                                  const SizedBox(height: 12),
                                
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _saving ? null : () => _openEditSheet(data),
                                            icon: const Icon(Icons.edit),
                                            label: const Text('แก้ไขโปรไฟล์'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white.withOpacity(.15),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // รายการอื่น ๆ
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'การตั้งค่า',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _GlassCard(
                                  child: Column(
                                    children: [
                                      _SettingTile(
                                        icon: Icons.bookmark_rounded,
                                        title: 'บุ๊กมาร์กของฉัน',
                                        subtitle: 'รายการสถานที่ที่บันทึกไว้',
                                        onTap: () {
                                          // TODO: นำทางไปหน้าบุ๊กมาร์กของคุณ
                                        },
                                      ),
                                      
                                      const Divider(height: 0, color: Colors.white12),
                                      _SettingTile(
                                        icon: Icons.privacy_tip_rounded,
                                        title: 'ความเป็นส่วนตัว',
                                        subtitle: 'จัดการข้อมูลและสิทธิ์',
                                        onTap: () {
                                          // TODO: ไปหน้าความเป็นส่วนตัว
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _GlassCard(
                                  child: ListTile(
                                    leading: const Icon(Icons.logout, color: Colors.white),
                                    title: const Text('ออกจากระบบ',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                    subtitle: const Text('ออกจากระบบและกลับไปหน้าเข้าสู่ระบบ',
                                        style: TextStyle(color: Colors.white70)),
                                    onTap: () async {
                                      try {
                                        await _auth.signOut();
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('ออกจากระบบไม่สำเร็จ: $e')),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/* ---------------------- UI Components ---------------------- */

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.2),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.local_florist, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: .85,
                  child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillInfo extends StatelessWidget {
  const _PillInfo({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withOpacity(.15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(.95), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(.18)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      onTap: onTap,
    );
  }
}

/* ---------------------- Edit Sheet ------------------------ */

class _EditCard extends StatelessWidget {
  const _EditCard({
    required this.nameCtrl,
    required this.bioCtrl,
    required this.locCtrl,
    required this.onSave,
  });

  final TextEditingController nameCtrl;
  final TextEditingController bioCtrl;
  final TextEditingController locCtrl;
  final VoidCallback onSave;

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2F6F4F)),
        filled: true,
        fillColor: const Color(0xFFF3F7F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(.05)),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        // โค้งมนด้านบน + เงา
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.12),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'แก้ไขโปรไฟล์',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            decoration: _dec('ชื่อที่แสดง', Icons.person),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: bioCtrl,
            decoration: _dec('คำอธิบายสั้น ๆ เกี่ยวกับคุณ', Icons.nature_people),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: locCtrl,
            decoration: _dec('ที่อยู่/จังหวัด', Icons.place),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save),
              label: const Text('บันทึก'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F6F4F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
