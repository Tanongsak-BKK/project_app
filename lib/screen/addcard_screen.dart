// lib/screen/addcard_screen.dart
// ✨ Natural-themed visual polish only — no business logic changed.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ คุม status bar
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_app/screen/navbar_screen.dart';

// ถ้า enum Region อยู่ใน model ของคุณ
import 'package:project_app/model/place.dart' show Region;

// หน้าเลือกแผนที่
import 'package:project_app/screen/maps_screen.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  Region _region = Region.north;
  bool _saving = false;

  // เก็บผลจากหน้าแผนที่ เพื่อแสดงสรุป
  MapPickResult? _pickedMap;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _imageUrlCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  String _regionToKey(Region r) {
    switch (r) {
      case Region.north:
        return 'north';
      case Region.south:
        return 'south';
      case Region.east:
        return 'east';
      case Region.west:
        return 'west';
    }
  }

  Future<void> _pickAddressOnMap() async {
    final res = await Navigator.push<MapPickResult>(
      context,
      MaterialPageRoute(builder: (_) => const MapsScreen()),
    );
    if (res != null) {
      setState(() {
        _pickedMap = res;
        final addr = (res.address.isNotEmpty)
            ? res.address
            : '${res.lat.toStringAsFixed(6)}, ${res.lng.toStringAsFixed(6)}';
        _addressCtrl.text = addr; // บันทึกลง field 'address' เดิม
      });
    }
  }

  Future<void> _savePlace() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนบันทึก')),
      );
      return;
    }

    final title = _titleCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final imageUrl = _imageUrlCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    setState(() => _saving = true);
    try {
      final doc = FirebaseFirestore.instance.collection('places').doc();
      await doc.set({
        'id': doc.id,
        'userId': user.uid,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'address': address,
        'region': _regionToKey(_region),
        'rating': 0.0, // ★ ตั้งค่าเรตติ้งเป็น 0 เสมอ
        'popularity': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('บันทึกสถานที่เรียบร้อย')));

      // ไปที่ NavbarScreen (มี HomeScreen อยู่ข้างใน)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NavbarScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------- Nature-flavored UI helpers (visual-only) ----------

  static const _nature = Color(0xFF2F6F4F); // leaf
  static const _natureSoft = Color(0xFFF3F7F5); // mist

  InputDecoration _dec({required String hint, IconData? icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: _nature) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: _natureSoft,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: const Color(0xFFFFFFFF).withOpacity(.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: const Color(0xFFFFFFFF).withOpacity(.06)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: _nature, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    );
  }

  Widget _sectionTitle(String text, {IconData icon = Icons.eco_rounded}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _nature),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // ✅ บังคับ status bar โปร่งใสและไอคอนสว่าง เฉพาะหน้านี้
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android
        statusBarBrightness: Brightness.dark,      // iOS (light)
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        // ✅ ให้คอนเทนต์ล้นหลัง status bar จริง ๆ
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.transparent,

        body: Stack(
          fit: StackFit.expand,
          children: [
            // 🔹 พื้นหลังรูปเต็มจอ
            Positioned.fill(
              child: Image.asset(
                'lib/images/background-onboarding.jpg', // ใช้ path ของคุณ
                fit: BoxFit.cover,
                alignment: Alignment.topCenter, // ดันรูปชิดบน จะไม่เหลือเส้นสีอ่อน
                filterQuality: FilterQuality.high,
              ),
            ),

            // 🔹 Overlay โปร่ง เพื่อให้อ่านข้อความชัดขึ้น
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.25)),
            ),

            // 🔹 เนื้อหา — ปิด SafeArea ด้านบนเพื่อไม่ให้เกิดขอบขาว
            SafeArea(
              top: false, // ✅ สำคัญ! ไม่กันด้านบน (ภาพจะชิดรอยบากจริง ๆ)
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      // ชดเชยระยะรอยบากด้วย media padding เอง
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 12,
                        left: 16,
                        right: 16,
                        bottom: 28,
                      ),
                      child: _GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row
                                Row(
                                  children: [
                                    const Icon(Icons.terrain_rounded,
                                        color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'บันทึกสถานที่ท่องเที่ยว',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(.65),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                            color: Colors.black.withOpacity(.8)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.eco_outlined,
                                              size: 14, color: Colors.white),
                                          const SizedBox(width: 6),
                                          Text(
                                            _regionLabel(_region),
                                            style: const TextStyle(
                                                fontSize: 12, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Preview รูปจาก URL
                                if (_imageUrlCtrl.text.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 250),
                                        child: Image.network(
                                          _imageUrlCtrl.text,
                                          key: ValueKey(_imageUrlCtrl.text),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: Colors.white,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              color: Color(0xFFF0F0F0),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 14),
                                _sectionTitle('รูปภาพ'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _imageUrlCtrl,
                                  decoration: _dec(
                                    hint: 'วาง Image URL',
                                    icon: Icons.link,
                                    suffix: (_imageUrlCtrl.text.isEmpty)
                                        ? null
                                        : Tooltip(
                                            message: 'ล้างลิงก์',
                                            child: IconButton(
                                              onPressed: () {
                                                setState(() => _imageUrlCtrl.clear());
                                              },
                                              icon: const Icon(Icons.close),
                                            ),
                                          ),
                                  ),
                                  keyboardType: TextInputType.url,
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'กรุณาใส่ลิงก์รูป';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),
                                _sectionTitle('รายละเอียดสถานที่',
                                    icon: Icons.place_rounded),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _titleCtrl,
                                  decoration: _dec(
                                      hint: 'ชื่อสถานที่',
                                      icon: Icons.place_rounded),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'กรุณากรอกชื่อสถานที่'
                                      : null,
                                  textInputAction: TextInputAction.next,
                                ),

                                const SizedBox(height: 16),
                                _sectionTitle('ที่อยู่ / พิกัด',
                                    icon: Icons.map_outlined),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _pickAddressOnMap,
                                        icon: const Icon(Icons.map_outlined),
                                        label: const Text('เลือกจากแผนที่'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: const BorderSide(color: Color(0xFFF5F5F5)),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          backgroundColor:
                                              const Color(0xFFF9FFFC).withOpacity(.06),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (_pickedMap != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _natureSoft,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black.withOpacity(.05)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.place,
                                                size: 18, color: Colors.white),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _addressCtrl.text,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'พิกัด: '
                                          '${_pickedMap!.lat.toStringAsFixed(6)}, '
                                          '${_pickedMap!.lng.toStringAsFixed(6)}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDFDFD),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black.withOpacity(.05)),
                                    ),
                                    child: const Text('ยังไม่ได้เลือกตำแหน่งจากแผนที่'),
                                  ),
                                ],

                                const SizedBox(height: 16),
                                _sectionTitle('ภูมิภาค', icon: Icons.forest_rounded),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<Region>(
                                  value: _region,
                                  decoration: _dec(hint: 'ภูมิภาค'),
                                  items: const [
                                    DropdownMenuItem(value: Region.north, child: Text('เหนือ')),
                                    DropdownMenuItem(value: Region.south, child: Text('ใต้')),
                                    DropdownMenuItem(value: Region.east, child: Text('ตะวันออก')),
                                    DropdownMenuItem(value: Region.west, child: Text('ตะวันตก')),
                                  ],
                                  onChanged: (v) => setState(() => _region = v ?? Region.north),
                                ),

                                const SizedBox(height: 16),
                                _sectionTitle('คำอธิบาย', icon: Icons.notes_rounded),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _descCtrl,
                                  decoration: _dec(
                                      hint: 'คำอธิบาย/ไฮไลต์', icon: Icons.notes_rounded),
                                  maxLines: 4,
                                ),

                                const SizedBox(height: 22),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _saving ? null : _savePlace,
                                    icon: _saving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.save_outlined),
                                    label: const Text('บันทึกสถานที่'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _nature,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _regionLabel(Region r) {
    switch (r) {
      case Region.north:
        return 'ภาคเหนือ';
      case Region.south:
        return 'ภาคใต้';
      case Region.east:
        return 'ตะวันออก';
      case Region.west:
        return 'ตะวันตก';
    }
  }
}

/* -------------------- UI helper (Glass) -------------------- */
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.20),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
