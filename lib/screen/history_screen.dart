import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_app/model/place.dart';

/// หน้าประวัติการเพิ่มสถานที่ของผู้ใช้
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // ถ้ายังไม่มีผู้ใช้ (ยังไม่ล็อกอิน)
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('กรุณาเข้าสู่ระบบก่อนนะ')),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('places') // เปลี่ยนชื่อคอลเล็กชันให้ตรงโปรเจกต์คุณ
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติของฉัน'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _LoadingList();
          }
          if (snap.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemBuilder: (_, i) => _PlaceCard(doc: docs[i]),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: docs.length,
          );
        },
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.doc});

  final QueryDocumentSnapshot doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final title = (data['name'] ?? data['title'] ?? 'ไม่ระบุชื่อ') as String;
    final subtitle =
        (data['address'] ?? data['location'] ?? data['province'] ?? '')
            as String;
    final imageUrl =
        (data['imageUrl'] ?? data['image'] ?? data['cover'] ?? '') as String;
    final createdAt = (data['createdAt'] ?? data['created_at']);
    DateTime? created;
    if (createdAt is Timestamp) {
      created = createdAt.toDate();
    } else if (createdAt is String) {
      created = DateTime.tryParse(createdAt);
    }
    final dateStr = created != null
        ? DateFormat('dd MMM yyyy • HH:mm', 'th').format(created)
        : 'ไม่ทราบเวลา';

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: ไปหน้า detail_screen.dart ถ้ามี
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailScreen(placeId: doc.id, place: null),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlaceThumb(imageUrl: imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อสถานที่
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // ที่อยู่/ทำเล
                    if (subtitle.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.place, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    // เวลาเพิ่ม
                    Row(
                      children: [
                        const Icon(Icons.history, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'เพิ่มเมื่อ $dateStr',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // เมนูเพิ่มเติม (ถ้าจะลบ/แชร์ในอนาคต)
              PopupMenuButton<String>(
                tooltip: 'เมนู',
                onSelected: (v) async {
                  if (v == 'delete') {
                    await FirebaseFirestore.instance
                        .collection(doc.reference.parent.id)
                        .doc(doc.id)
                        .delete();
                    // ไม่ต้อง setState เพราะ StreamBuilder จะอัปเดตให้เอง
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline),
                        SizedBox(width: 8),
                        Text('ลบรายการนี้'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceThumb extends StatelessWidget {
  const _PlaceThumb({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: 96,
        height: 96,
        child: imageUrl.isEmpty
            ? Container(
                color: Colors.grey[200],
                child: const Icon(Icons.photo, size: 28),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64),
            const SizedBox(height: 12),
            Text(
              'ยังไม่มีประวัติการเพิ่มสถานที่',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'เริ่มเพิ่มสถานที่แรกของคุณได้จากปุ่ม “เพิ่มสถานที่” ในหน้าอื่น ๆ',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  final String placeId;
  final Place? place;

  const DetailScreen({Key? key, required this.placeId, this.place})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement detail screen
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดสถานที่')),
      body: Center(child: Text('รายละเอียดของสถานที่ ID: $placeId')),
    );
  }
}
