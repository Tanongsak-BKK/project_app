import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:project_app/service/auth_service.dart';
import 'package:project_app/screen/login_screen.dart';
import 'package:project_app/model/place.dart';
import 'package:project_app/provider/place_provider.dart';
import 'package:project_app/screen/detail_screen.dart';
import 'package:project_app/screen/navbar_screen.dart'; // ✅ ใช้สำหรับปุ่มกลับบ้านผ่าน Navbar

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    Future.microtask(() => context.read<PlaceProvider>().loadPlaces());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

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

  Stream<QuerySnapshot<Map<String, dynamic>>> _myPlacesStream(String uid) {
    return _db.collection('places').where('userId', isEqualTo: uid).snapshots();
  }

  Future<void> _openEditProfile(Map<String, dynamic> data) async {
    final nameCtrl = TextEditingController(
      text: (data['displayName'] ?? _auth.currentUser?.displayName ?? '').toString(),
    );
    final bioCtrl = TextEditingController(text: (data['bio'] ?? '').toString());
    final photoCtrl =
        TextEditingController(text: (data['photoUrl'] ?? _auth.currentUser?.photoURL ?? '').toString());

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: _EditProfileSheet(
            nameCtrl: nameCtrl,
            bioCtrl: bioCtrl,
            photoCtrl: photoCtrl,
            onSave: () async {
              final user = _auth.currentUser;
              if (user == null) return;
              final name = nameCtrl.text.trim();
              final bio = bioCtrl.text.trim();
              final photoUrl = photoCtrl.text.trim();

              try {
                if (name.isNotEmpty && name != (user.displayName ?? '')) {
                  await user.updateDisplayName(name);
                }
                if (photoUrl.isNotEmpty && photoUrl != (user.photoURL ?? '')) {
                  await user.updatePhotoURL(photoUrl);
                }

                await _db.collection('users').doc(user.uid).set({
                  'displayName': name.isEmpty ? (user.email ?? '') : name,
                  'bio': bio,
                  'photoUrl': photoUrl,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('อัปเดตโปรไฟล์สำเร็จ')),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
                );
              }
            },
          ),
        );
      },
    );
  }

  /// ✅ กลับบ้านผ่าน NavbarScreen(initialIndex: 0)
  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const NavbarScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: Text('ยังไม่ได้เข้าสู่ระบบ')),
        ),
      );
    }

    final prov = context.watch<PlaceProvider>();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: _IgAppBar(
        onBackTap: () => _goHome(context), // ✅ ใช้ฟังก์ชันกลับบ้าน
        titleStream: _userDocStream(user).map((e) {
          final data = e.data() ?? {};
          return (data['displayName'] ?? user.displayName ?? 'Profile').toString();
        }),
        onMenuTap: () async {
          final data = (await _db.collection('users').doc(user.uid).get()).data() ?? {};
          final selected = await showModalBottomSheet<_SettingAction>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => const _SettingsSheet(),
          );
          if (selected == _SettingAction.edit) {
            _openEditProfile(data);
          } else if (selected == _SettingAction.logout) {
            try {
              await AuthService().signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ออกจากระบบไม่สำเร็จ: $e')),
              );
            }
          }
        },
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userDocStream(user),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() ?? {};
          final displayName =
              (data['displayName'] ?? user.displayName ?? 'Your Name').toString();
          final email = (data['email'] ?? user.email ?? '').toString();
          final photo = (data['photoUrl'] ?? user.photoURL)?.toString();
          final bio = (data['bio'] ?? '').toString();
          final ts = data['createdAt'];
          String since = '';
          if (ts is Timestamp) {
            try {
              since = DateFormat('d MMM y').format(ts.toDate());
            } catch (_) {}
          }

          return Column(
            children: [
              // ---------- Header ----------
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StoryRing(
                      size: 94,
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
                        child: (photo == null || photo.isEmpty)
                            ? const Icon(Icons.person, size: 42, color: Colors.black54)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _myPlacesStream(user.uid),
                        builder: (context, placeSnap) {
                          final posts = placeSnap.data?.size ?? 0;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _Stat(number: posts, label: 'Posts'),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- Name / Bio ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16, height: 1.1)),
                    if (bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(bio, style: const TextStyle(height: 1.25)),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Opacity(
                        opacity: .8,
                        child: Text(email, style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    if (since.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('เข้าร่วมเมื่อ $since',
                            style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ),
                    const SizedBox(height: 10),

                    // ปุ่มแก้ไขโปรไฟล์ (สไตล์ IG – ปุ่มขอบมน)
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () => _openEditProfile(data),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: Colors.grey.shade300),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('แก้ไขโปรไฟล์', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ---------- Tabs ----------
              TabBar(
                controller: _tab,
                indicatorColor: Colors.black,
                indicatorWeight: 1.8,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black45,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on_rounded, size: 22)),
                  Tab(icon: Icon(Icons.bookmark_border, size: 22)),
                ],
              ),

              // ---------- Tab Views ----------
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    // Grid: โพสต์ของเรา
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _myPlacesStream(user.uid),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return const Center(child: Text('โหลดโพสต์ไม่สำเร็จ'));
                        }
                        if (!snap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = snap.data!.docs;
                        if (docs.isEmpty) {
                          return const Center(child: Text('ยังไม่มีโพสต์'));
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.all(1),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 1,
                            crossAxisSpacing: 1,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final d = docs[i].data();
                            final place = Place(
                              id: d['id'] ?? docs[i].id,
                              userId: d['userId'] ?? '',
                              title: d['title'] ?? '',
                              description: d['description'] ?? '',
                              imageUrl: d['imageUrl'] ?? '',
                              address: d['address'] ?? '',
                              region: _parseRegion(d['region']),
                              rating: (d['rating'] as num?)?.toDouble() ?? 0,
                              popularity: (d['popularity'] as num?)?.toInt() ?? 0,
                              createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
                              updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
                            );
                            return _GridTile(place: place);
                          },
                        );
                      },
                    ),

                    // Saved / Bookmarked
                    Builder(
                      builder: (context) {
                        final saved = prov.bookmarked();
                        if (saved.isEmpty) {
                          return const Center(child: Text('ยังไม่มีที่บันทึกไว้'));
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.all(1),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 1,
                            crossAxisSpacing: 1,
                          ),
                          itemCount: saved.length,
                          itemBuilder: (_, i) => _GridTile(place: saved[i]),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Region _parseRegion(dynamic v) {
    switch (v) {
      case 'north':
        return Region.north;
      case 'south':
        return Region.south;
      case 'east':
        return Region.east;
      case 'west':
        return Region.west;
      default:
        return Region.north;
    }
  }
}

/* ======================= IG-styled Widgets ======================= */

class _IgAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _IgAppBar({
    required this.titleStream,
    required this.onMenuTap,
    required this.onBackTap, // ✅ เพิ่ม
  });

  final Stream<String> titleStream;
  final VoidCallback onMenuTap;
  final VoidCallback onBackTap; // ✅ เพิ่ม

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: onBackTap, // ✅ กลับผ่าน NavbarScreen(initialIndex: 0)
        tooltip: 'กลับหน้าแรก',
      ),
      title: StreamBuilder<String>(
        stream: titleStream,
        builder: (context, snap) {
          final t = (snap.data ?? '').trim();
          return Text(
            t.isEmpty ? 'Profile' : t,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: .2,
            ),
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: onMenuTap,
          tooltip: 'ตั้งค่า',
        ),
      ],
    );
  }
}

enum _SettingAction { edit, logout }

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('แก้ไขโปรไฟล์', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, _SettingAction.edit),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('ออกจากระบบ', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, _SettingAction.logout),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryRing extends StatelessWidget {
  const _StoryRing({required this.child, this.size = 92});
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [
          Color(0xFFFF6A00),
          Color(0xFFFF006A),
          Color(0xFF7B61FF),
          Color(0xFFFF6A00),
        ]),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.number, required this.label});
  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$number', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(place: place)),
      ),
      child: Ink(
        decoration: BoxDecoration(color: Colors.grey.shade200),
        child: place.imageUrl.isEmpty
            ? const Icon(Icons.image_not_supported)
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Image.network(
                  key: ValueKey(place.imageUrl),
                  place.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }
}

/* ---------------------- Edit Profile Sheet ------------------------ */

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({
    required this.nameCtrl,
    required this.bioCtrl,
    required this.photoCtrl,
    required this.onSave,
  });

  final TextEditingController nameCtrl;
  final TextEditingController bioCtrl;
  final TextEditingController photoCtrl;
  final VoidCallback onSave;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.black87),
        filled: true,
        fillColor: const Color(0xFFF6F7F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          const Text('แก้ไขโปรไฟล์',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 12),

          // พรีวิวรูป
          _StoryRing(
            size: 86,
            child: CircleAvatar(
              radius: 34,
              backgroundImage: widget.photoCtrl.text.trim().isNotEmpty
                  ? NetworkImage(widget.photoCtrl.text.trim())
                  : null,
              child: widget.photoCtrl.text.trim().isEmpty
                  ? const Icon(Icons.person, size: 32, color: Colors.black54)
                  : null,
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: widget.photoCtrl,
            decoration: _dec('ลิงก์รูปโปรไฟล์ (URL)', Icons.link),
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: widget.nameCtrl,
            decoration: _dec('ชื่อที่แสดง', Icons.person_outline),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),

          TextField(
            controller: widget.bioCtrl,
            decoration: _dec('Bio (แนะนำตัวสั้น ๆ)', Icons.notes_rounded),
            maxLines: 3,
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('บันทึก', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
