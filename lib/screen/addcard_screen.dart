// lib/screen/addcard_screen.dart
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ถ้า enum Region อยู่ใน model ของคุณ
import 'package:project_app/model/place.dart' show Region;

// << NEW: หน้าเลือกแผนที่
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
  final _ratingCtrl = TextEditingController(text: '4.5');

  Region _region = Region.north;
  bool _saving = false;
  bool _uploading = false;
  double _uploadProgress = 0;

  // << NEW: เก็บผลจากหน้าแผนที่ เพื่อแสดงสรุป
  MapPickResult? _pickedMap;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _imageUrlCtrl.dispose();
    _addressCtrl.dispose();
    _ratingCtrl.dispose();
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

  /// บีบอัดภาพ (มือถือจะเห็นผลมากที่สุด)
  Future<Uint8List> _compressBytes(Uint8List data) async {
    if (kIsWeb) {
      // เว็บ: ข้ามการบีบอัด
      return data;
    }
    final out = await FlutterImageCompress.compressWithList(
      data,
      quality: 68,
      minWidth: 960,
      format: CompressFormat.jpeg,
    );
    return out;
  }

  /// เลือกรูป → บีบอัด → putData → ได้ URL → เติมลงช่องภาพอัตโนมัติ
  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 72,
        maxWidth: 1024,
      );
      if (picked == null) return;

      setState(() {
        _uploading = true;
        _uploadProgress = 0;
      });

      final rawBytes = await picked.readAsBytes();
      final bytes = await _compressBytes(rawBytes);

      final ref = FirebaseStorage.instance
          .ref()
          .child('places/img_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public,max-age=3600',
        ),
      );

      uploadTask.snapshotEvents.listen((s) {
        if (s.totalBytes > 0) {
          setState(() => _uploadProgress = s.bytesTransferred / s.totalBytes);
        }
      });

      final snap = await uploadTask.whenComplete(() {});
      final url = await snap.ref.getDownloadURL();

      _imageUrlCtrl.text = url;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปโหลดรูปสำเร็จ')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปโหลดรูปไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  // << NEW: เปิดหน้าแผนที่ แล้วรับค่ากลับมาวางที่ address
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

    // เช็คล็อกอินก่อน
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
    final address = _addressCtrl.text.trim(); // << ใช้ค่าจากปุ่มเลือกแผนที่
    final ratingStr = _ratingCtrl.text.trim();

    double rating = 4.5;
    final parsed = double.tryParse(ratingStr);
    if (parsed != null) rating = parsed.clamp(0, 5);

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
        'rating': rating,
        'popularity': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกสถานที่เรียบร้อย')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec({
    required String hint,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF2F6F4F)) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF3F7F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(.05)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // ไล่โทนธรรมชาติ
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0f9b0f), Color(0xFF3acfd5), Color(0xFF3a7bd5)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                title: const Text('เพิ่มสถานที่', style: TextStyle(color: Colors.white)),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: _GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (_imageUrlCtrl.text.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Image.network(
                                    _imageUrlCtrl.text,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.black12,
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.image_not_supported, color: Colors.black45),
                                    ),
                                  ),
                                ),
                              ),
                            if (_uploading) ...[
                              const SizedBox(height: 12),
                              LinearProgressIndicator(value: _uploadProgress == 0 ? null : _uploadProgress),
                            ],
                            const SizedBox(height: 14),

                            // URL + ปุ่มเลือกรูป (อัปโหลด-บีบอัด)
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _imageUrlCtrl,
                                    decoration: _dec(
                                      hint: 'วาง Image URL (หรือใช้ปุ่มเลือกรูป)',
                                      icon: Icons.link,
                                      suffix: (_imageUrlCtrl.text.isEmpty)
                                          ? null
                                          : IconButton(
                                              onPressed: () {
                                                setState(() => _imageUrlCtrl.clear());
                                              },
                                              icon: const Icon(Icons.close),
                                            ),
                                    ),
                                    keyboardType: TextInputType.url,
                                    onChanged: (_) => setState(() {}),
                                    validator: (v) {
                                      if ((v == null || v.trim().isEmpty) && !_uploading) {
                                        return 'ใส่รูปอย่างน้อย 1 วิธี (URL หรืออัปโหลด)';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: _uploading ? null : _pickAndUploadImage,
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('เลือกรูป'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF2F6F4F),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _titleCtrl,
                              decoration: _dec(hint: 'ชื่อสถานที่', icon: Icons.place_rounded),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อสถานที่' : null,
                              textInputAction: TextInputAction.next,
                            ),

                            const SizedBox(height: 10),

                            // ===== NEW: ปุ่มเลือกตำแหน่งจากแผนที่ + กล่องแสดงผล =====
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('ที่อยู่/พิกัด', style: Theme.of(context).textTheme.bodyMedium),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickAddressOnMap,
                                    icon: const Icon(Icons.map_outlined),
                                    label: const Text('เลือกจากแผนที่'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_pickedMap != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F7F5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.black.withOpacity(.05)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.place, size: 18, color: Color(0xFF2F6F4F)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _addressCtrl.text,
                                            maxLines: 2, overflow: TextOverflow.ellipsis,
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
                            // ===== END NEW =====

                            const SizedBox(height: 10),
                            DropdownButtonFormField<Region>(
                              value: _region,
                              decoration: _dec(hint: 'ภูมิภาค'),
                              items: const [
                                DropdownMenuItem(value: Region.north, child: Text('เหนือ')),
                                DropdownMenuItem(value: Region.south, child: Text('ใต้')),
                                DropdownMenuItem(value: Region.east,  child: Text('ตะวันออก')),
                                DropdownMenuItem(value: Region.west,  child: Text('ตะวันตก')),
                              ],
                              onChanged: (v) => setState(() => _region = v ?? Region.north),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _ratingCtrl,
                              decoration: _dec(hint: 'เรตติ้ง (0–5, ใส่ทศนิยมได้)', icon: Icons.star_rate_rounded),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                final x = double.tryParse(v);
                                if (x == null || x < 0 || x > 5) return 'กรุณากรอก 0–5';
                                return null;
                              },
                              textInputAction: TextInputAction.newline,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _descCtrl,
                              decoration: _dec(hint: 'คำอธิบาย/ไฮไลต์', icon: Icons.notes_rounded),
                              maxLines: 4,
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saving || _uploading ? null : _savePlace,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: const Text('บันทึกสถานที่'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2F6F4F),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      ),
    );
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
