// lib/screen/detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/place.dart';
import 'package:provider/provider.dart';
import 'package:project_app/provider/place_provider.dart';

class DetailScreen extends StatefulWidget {
  final Place place;
  const DetailScreen({super.key, required this.place});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _readMore = false;

  // live rating (อัปเดตหลังให้คะแนน)
  late double _liveRating;

  // คอมเมนต์
  final _cmtCtrl = TextEditingController();
  bool _sending = false;

  User? get _user => FirebaseAuth.instance.currentUser;
  bool get _isOwner => _user?.uid == widget.place.userId;

  @override
  void initState() {
    super.initState();
    _liveRating = widget.place.rating;
  }

  @override
  void dispose() {
    _cmtCtrl.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> get _commentsCol =>
      FirebaseFirestore.instance
          .collection('places')
          .doc(widget.place.id)
          .collection('comments');

  CollectionReference<Map<String, dynamic>> get _ratingsCol =>
      FirebaseFirestore.instance
          .collection('places')
          .doc(widget.place.id)
          .collection('ratings');

  Future<void> _sendComment() async {
    final text = _cmtCtrl.text.trim();
    if (text.isEmpty) return;
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนแสดงความคิดเห็น')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await _commentsCol.add({
        'userId': _user!.uid,
        'displayName': _user!.displayName ?? 'ผู้ใช้',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _cmtCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('ส่งคอมเมนต์ไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openRatingSheet() async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนให้เรตติ้ง')),
      );
      return;
    }
    if (_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เจ้าของไม่สามารถให้เรตโพสต์ของตนเองได้')),
      );
      return;
    }

    double temp = (_liveRating > 0 ? _liveRating : 3.0);
    final val = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ให้คะแนนสถานที่นี้', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setS) => Column(
                  children: [
                    _StarsInteractive(
                      value: temp,
                      onChanged: (v) => setS(() => temp = v),
                    ),
                    const SizedBox(height: 6),
                    Text('${temp.toStringAsFixed(1)} / 5.0'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, temp),
                  icon: const Icon(Icons.check),
                  label: const Text('ยืนยัน'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (val == null) return;
    await _saveRating(val);
  }

  Future<void> _saveRating(double value) async {
    try {
      // 1) เซฟเรตของ user ไว้ที่ subcollection
      await _ratingsCol.doc(_user!.uid).set({
        'value': value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2) คำนวณค่าเฉลี่ยใหม่ทั้งหมด
      final snap = await _ratingsCol.get();
      if (snap.docs.isEmpty) return;

      double sum = 0;
      for (final d in snap.docs) {
        final v = (d.data()['value'] as num?)?.toDouble() ?? 0.0;
        sum += v;
      }
      final avg = double.parse((sum / snap.docs.length).toStringAsFixed(2));

      // 3) อัปเดตที่ places/{id}.rating เพื่อเก็บลงฐาน
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.place.id)
          .update({
        'rating': avg,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4) อัปเดตทันทีใน Provider → ทุกหน้าจะเห็นค่าใหม่ทันที
      if (mounted) {
        context.read<PlaceProvider>().updateRating(widget.place.id, avg);
        setState(() => _liveRating = avg);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกเรตติ้งเรียบร้อย')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('ให้เรตไม่สำเร็จ: $e')));
    }
  }

  // ================== EDIT / DELETE MY COMMENT ==================

  Future<void> _editMyComment({
    required String commentId,
    required Map<String, dynamic> data,
  }) async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')),
      );
      return;
    }
    if ((data['userId'] as String?) != _user!.uid) return;

    final controller = TextEditingController(text: (data['text'] as String?) ?? '');
    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('แก้ไขความคิดเห็น'),
        content: TextField(
          controller: controller,
          minLines: 1,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'พิมพ์ข้อความใหม่...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('บันทึก')),
        ],
      ),
    );
    if (newText == null) return;
    if (newText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ข้อความว่างเปล่า')),
      );
      return;
    }

    try {
      await _commentsCol.doc(commentId).set({
        'userId': data['userId'],
        'displayName': (data['displayName'] ?? _user!.displayName ?? 'ผู้ใช้'),
        'text': newText,
        'createdAt': data['createdAt'],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('แก้ไขความคิดเห็นแล้ว')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('แก้ไขไม่สำเร็จ: $e')));
    }
  }

  Future<void> _deleteMyComment({
    required String commentId,
    required Map<String, dynamic> data,
  }) async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')),
      );
      return;
    }
    if ((data['userId'] as String?) != _user!.uid) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบความคิดเห็นนี้?'),
        content: const Text('คุณต้องการลบความคิดเห็นของคุณจริงหรือไม่'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ลบ')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _commentsCol.doc(commentId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบความคิดเห็นแล้ว')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
    }
  }

  // =============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final imageUrl    = widget.place.imageUrl;
    final title       = widget.place.title;
    final region      = widget.place.region;
    final address     = widget.place.address.trim();
    final description = widget.place.description.trim();
    final popularity  = widget.place.popularity;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // รูปหัว
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl.isNotEmpty)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(),
                        )
                      else
                        _imageFallback(),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black26],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: _PopularityBadge(popularity: popularity),
                      ),
                    ],
                  ),
                ),

                // การ์ดรายละเอียด
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 12,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ชื่อ
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // ภูมิภาค + ดาว (live rating)
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey, size: 18),
                            const SizedBox(width: 6),
                            Text(_regionLabel(region), style: const TextStyle(color: Colors.black54)),
                            const Spacer(),
                            _Stars(rating: _liveRating),
                          ],
                        ),

                        // ที่อยู่ (ถ้ามี)
                        if (address.isNotEmpty) ...[
                          const Divider(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.map_rounded, color: Colors.black54, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  address,
                                  style: const TextStyle(color: Colors.black87, height: 1.3),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                tooltip: 'คัดลอกที่อยู่',
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: address));
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('คัดลอกที่อยู่แล้ว')),
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 18, color: Colors.black54),
                              ),
                            ],
                          ),
                        ],

                        // รายละเอียด (description)
                        if (description.isNotEmpty) ...[
                          const Divider(height: 24),
                          Text(
                            "รายละเอียด",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedCrossFade(
                            firstChild: Text(
                              description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black87, height: 1.4),
                            ),
                            secondChild: Text(
                              description,
                              style: const TextStyle(color: Colors.black87, height: 1.4),
                            ),
                            crossFadeState: _readMore
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                          if (description.length > 140)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => setState(() => _readMore = !_readMore),
                                child: Text(_readMore ? "Read less" : "Read more"),
                              ),
                            ),
                        ],

                        // ======== คอมเมนต์ & ให้เรต ========
                        const Divider(height: 28),
                        Row(
                          children: [
                            const Text('ความคิดเห็น', style: TextStyle(fontWeight: FontWeight.w800)),
                            const Spacer(),
                            if (!_isOwner)
                              OutlinedButton.icon(
                                onPressed: _openRatingSheet,
                                icon: const Icon(Icons.star_rate_rounded),
                                label: const Text('ให้คะแนน'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // กล่องพิมพ์คอมเมนต์
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _cmtCtrl,
                                minLines: 1,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: _isOwner
                                      ? 'แสดงความคิดเห็นของคุณ (เจ้าของโพสต์)'
                                      : 'แสดงความคิดเห็นของคุณ',
                                  filled: true,
                                  fillColor: const Color(0xFFF6F7F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.black.withOpacity(.06)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _sending ? null : _sendComment,
                              icon: _sending
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.send_rounded, size: 18),
                              label: const Text('ส่ง'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // รายการคอมเมนต์
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _commentsCol.orderBy('createdAt', descending: true).snapshots(),
                          builder: (context, snap) {
                            if (snap.hasError) {
                              return const Text('โหลดคอมเมนต์ไม่สำเร็จ', style: TextStyle(color: Colors.red));
                            }
                            if (!snap.hasData) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final docs = snap.data!.docs;
                            if (docs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('ยังไม่มีความคิดเห็น', style: TextStyle(color: Colors.black54)),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: docs.length,
                              separatorBuilder: (_, __) => const Divider(height: 16),
                              itemBuilder: (_, i) {
                                final doc = docs[i];
                                final d = doc.data();
                                final name = (d['displayName'] as String?)?.trim().isNotEmpty == true
                                    ? (d['displayName'] as String)
                                    : 'ผู้ใช้';
                                final text = (d['text'] as String?) ?? '';
                                final isMe = d['userId'] == _user?.uid;

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      child: Text(name.characters.first.toUpperCase()),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                                    if (isMe)
                                                      const Padding(
                                                        padding: EdgeInsets.only(left: 6),
                                                        child: Text('(คุณ)', style: TextStyle(color: Colors.black45, fontSize: 12)),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              if (isMe)
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      visualDensity: VisualDensity.compact,
                                                      tooltip: 'แก้ไข',
                                                      icon: const Icon(Icons.edit, size: 18),
                                                      onPressed: () => _editMyComment(
                                                        commentId: doc.id,
                                                        data: d,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      visualDensity: VisualDensity.compact,
                                                      tooltip: 'ลบ',
                                                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                                      onPressed: () => _deleteMyComment(
                                                        commentId: doc.id,
                                                        data: d,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(text),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        // ======== จบคอมเมนต์ & ให้เรต ========
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ปุ่ม Back
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, size: 40, color: Colors.black38),
      );

  String _regionLabel(Region r) {
    switch (r) {
      case Region.north: return "North, Thailand";
      case Region.south: return "South, Thailand";
      case Region.east:  return "East, Thailand";
      case Region.west:  return "West, Thailand";
    }
  }
}

/* -------------------------- Widgets -------------------------- */

class _PopularityBadge extends StatelessWidget {
  final int popularity;
  const _PopularityBadge({required this.popularity});

  @override
  Widget build(BuildContext context) {
    if (popularity <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 18),
          const SizedBox(width: 6),
          Text(
            '$popularity',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < full) {
            return const Icon(Icons.star, size: 18, color: Color(0xFFFFD166));
          } else if (i == full && half) {
            return const Icon(Icons.star_half, size: 18, color: Color(0xFFFFD166));
          }
          return const Icon(Icons.star_border, size: 18, color: Color(0xFFFFD166));
        }),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// ดาวแบบปรับค่าได้ (0.5 step) — เรียงจาก 0.5 → 5.0
class _StarsInteractive extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _StarsInteractive({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // สร้าง 10 ตำแหน่ง: 0.5, 1.0, 1.5, ... , 5.0
    return Wrap(
      alignment: WrapAlignment.center,
      children: List.generate(10, (i) {
        final rating = (i + 1) * 0.5; // 0.5..5.0
        final isActive = value + 1e-6 >= rating; // กัน floating error เล็กน้อย

        final isWhole = (rating % 1 == 0); // true เมื่อเป็น 1.0, 2.0, ...
        final IconData icon = isWhole
            ? (isActive ? Icons.star : Icons.star_border)
            : (isActive ? Icons.star_half : Icons.star_border);

        return InkWell(
          onTap: () => onChanged(rating),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(icon, size: 32, color: const Color(0xFFFFD166)),
          ),
        );
      }),
    );
  }
}
