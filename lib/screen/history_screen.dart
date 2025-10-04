// lib/screen/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:project_app/model/place.dart';
import 'package:project_app/provider/place_provider.dart';
import 'package:project_app/screen/detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // ให้แน่ใจว่า provider มีรายการสถานที่ไว้ค้นชื่อ/รูปสำหรับกิจกรรม
    Future.microtask(() => context.read<PlaceProvider>().loadPlaces());
  }

  // ---------- (เดิม) ลบ place ของฉัน ----------
  Future<void> _deletePlace(BuildContext context, Place place) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบรายการนี้?'),
        content: Text('คุณต้องการลบ “${place.title}” จริงหรือไม่'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ลบ')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.collection('places').doc(place.id).delete();
      if (mounted) {
        context.read<PlaceProvider>().removeById(place.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบเรียบร้อย')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือนล่าสุด'),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('กรุณาเข้าสู่ระบบเพื่อดูการแจ้งเตือน'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('activities')
                  .where('ownerId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  debugPrint('ACTIVITIES ERROR: ${snap.error}');
                  return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดกิจกรรม'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // ✅ เรียงล่าสุดก่อนฝั่ง client → ไม่ต้องใช้ composite index
                final docs = snap.data!.docs.toList()
                  ..sort((a, b) {
                    final ta = (a.data()['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final tb = (b.data()['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return tb.compareTo(ta);
                  });

                if (docs.isEmpty) {
                  return const Center(child: Text('ยังไม่มีกิจกรรม'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _ActivityTile(activity: docs[i].data()),
                );
              },
            ),
    );
  }
}

/* -------------------------- Activity Tile -------------------------- */

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});
  final Map<String, dynamic> activity;

  Place? _findPlace(List<Place> list, String id) {
    for (final p in list) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PlaceProvider>();

    final type = (activity['type'] as String?) ?? 'comment';
    final isRating = type == 'rating';
    final displayName = (activity['displayName'] as String?) ?? 'ผู้ใช้';
    final message = (activity['message'] as String?) ?? '';
    final placeId = (activity['placeId'] as String?) ?? '';
    final ts = (activity['createdAt'] as Timestamp?)?.toDate();

    final place = _findPlace(prov.places, placeId);
    final placeTitle = place?.title ?? '(ไม่พบข้อมูลสถานที่)';
    final thumb = place?.imageUrl ?? '';

    final timeStr = ts == null
        ? ''
        : TimeOfDay.fromDateTime(ts).format(context);

    return ListTile(
      onTap: () {
        if (place != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(place: place)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลสถานที่นี้ (อาจถูกลบแล้ว)')),
          );
        }
      },
      leading: _LeadingThumb(thumbUrl: thumb, fallbackIcon: isRating ? Icons.star_rate_rounded : Icons.comment_rounded),
      title: Text(
        '$displayName ${isRating ? "ให้คะแนน" : "แสดงความคิดเห็น"}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // เนื้อความกิจกรรม
          if (message.isNotEmpty)
            Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
          // แสดงว่ามาจากการ์ดไหน
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.place, size: 14, color: Colors.black45),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'จาก: $placeTitle',
                    style: const TextStyle(color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      trailing: Text(
        timeStr,
        style: const TextStyle(color: Colors.black45, fontSize: 12),
      ),
    );
  }
}

class _LeadingThumb extends StatelessWidget {
  const _LeadingThumb({required this.thumbUrl, required this.fallbackIcon});
  final String thumbUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    if (thumbUrl.isEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.black12,
        child: Icon(fallbackIcon, color: fallbackIcon == Icons.star_rate_rounded ? Colors.orangeAccent : Colors.blueAccent),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        thumbUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          backgroundColor: Colors.black12,
          child: Icon(fallbackIcon, color: fallbackIcon == Icons.star_rate_rounded ? Colors.orangeAccent : Colors.blueAccent),
        ),
      ),
    );
    }
}

/* ------------------- (ของเดิม) My Places list ------------------- */
/* ถ้าคุณยังต้องการหน้ารายการสถานที่ของฉันแบบเดิม
   สามารถเก็บ _MyPlacesList ด้านล่างไว้ใช้งานที่อื่นได้ */

class _MyPlacesList extends StatelessWidget {
  final List<Place> items;
  final bool busy;
  final ValueChanged<Place> onDelete;
  const _MyPlacesList({required this.items, required this.busy, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('ยังไม่มีรายการของคุณ'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = items[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                p.imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported, color: Colors.black45),
                ),
              ),
            ),
            title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFFD166), size: 16),
                const SizedBox(width: 4),
                Text(p.rating.toStringAsFixed(1)),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailScreen(place: p)),
              );
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: busy ? null : () => onDelete(p),
              tooltip: 'ลบ',
            ),
          ),
        );
      },
    );
  }
}
