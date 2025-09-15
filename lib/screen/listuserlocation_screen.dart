import 'dart:typed_data';
import 'package:flutter/material.dart';

class ListUserLocationScreen extends StatelessWidget {
  const ListUserLocationScreen({
    super.key,
    this.items,
    this.title = 'สถานที่ของคุณ',
  });

  /// ส่งรายการจริงเข้ามาได้; ถ้า null จะสร้างตัวอย่างจาก mock
  final List<UserLocationItem>? items;
  final String title;

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFE7F3EE);
    final data = items ?? _mockItems;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
      
        title: Text(title),
        
      ),
      body: data.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: data.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) => _UserLocationCard(item: data[i]),
            ),
    );
  }
}

/// ----- Card -----
class _UserLocationCard extends StatelessWidget {
  const _UserLocationCard({required this.item});
  final UserLocationItem item;

  @override
  Widget build(BuildContext context) {
    final white = Colors.white;
    final shadow =
        const BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4));
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [shadow],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name/email + menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(bytes: item.userAvatarBytes, url: item.userAvatarUrl, name: item.userName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis),
                    Text(item.userEmail,
                        style: const TextStyle(color: Colors.black54),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              
            ],
          ),
          const SizedBox(height: 12),

          // Photo (optional)
          if (item.photoBytes != null || item.photoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _Photo(bytes: item.photoBytes, url: item.photoUrl),
            ),

          if (item.photoBytes != null || item.photoUrl != null)
            const SizedBox(height: 10),

          // Info row: left = 3 pills, right = date text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _Pill(icon: Icons.edit_outlined, text: item.locationName),
                    const SizedBox(height: 6),
                    _Pill(icon: Icons.place_outlined, text: item.place),
                    const SizedBox(height: 6),
                    _Pill(icon: Icons.event_note_outlined, text: _formatThaiDateShort(item.date)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// avatar จาก bytes/url หรืออักษรย่อ
class _Avatar extends StatelessWidget {
  const _Avatar({this.bytes, this.url, required this.name});
  final Uint8List? bytes;
  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (bytes != null) {
      child = Image.memory(bytes!, fit: BoxFit.cover);
    } else if (url != null && url!.isNotEmpty) {
      child = Image.network(url!, fit: BoxFit.cover);
    } else {
      final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
      child = Center(
        child: Text(initial,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.white,
      child: ClipOval(
        child: SizedBox(width: 46, height: 46, child: child),
      ),
    );
  }
}

/// รูปแนวนอนสูง ~180 ถ้าไม่มีจะไม่แสดง
class _Photo extends StatelessWidget {
  const _Photo({this.bytes, this.url});
  final Uint8List? bytes;
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      return Image.memory(bytes!, height: 180, width: double.infinity, fit: BoxFit.cover);
    }
    return Image.network(url!, height: 180, width: double.infinity, fit: BoxFit.cover);
  }
}

/// pill กล่องมน ๆ สีอ่อน
class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final bgPill = const Color(0xFFE7F3EE);
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: bgPill,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_rounded, size: 48, color: Colors.black26),
          SizedBox(height: 8),
          Text('ยังไม่มีรายการ', style: TextStyle(color: Colors.black45)),
          SizedBox(height: 2),
          Text('เริ่มแชร์สถานที่ของคุณกันเถอะ', style: TextStyle(color: Colors.black38)),
        ],
      ),
    );
  }
}

/// ----- Model -----
class UserLocationItem {
  final String userId;
  final String userName;
  final String userEmail;
  final Uint8List? userAvatarBytes;
  final String? userAvatarUrl;

  final String locationName; // ชื่อสถานที่
  final String place;        // จังหวัด/อำเภอ/ฯลฯ
  final DateTime date;
  final Uint8List? photoBytes;
  final String? photoUrl;

  final int likeCount;
  final int commentCount;

  UserLocationItem({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.locationName,
    required this.place,
    required this.date,
    this.userAvatarBytes,
    this.userAvatarUrl,
    this.photoBytes,
    this.photoUrl,
    this.likeCount = 0,
    this.commentCount = 0,
  });
}

/// ----- Thai date helpers -----
const _thaiMonthsShort = [
  '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
];

String _formatThaiDateShort(DateTime d) {
  final yBE = d.year + 543;
  return '${d.day} ${_thaiMonthsShort[d.month]} $yBE';
}



/// ----- Mock data (ลบได้เมื่อเชื่อมจริง) -----
final _mockItems = <UserLocationItem>[
  UserLocationItem(
    userId: 'u1',
    userName: 'Tanongsak B',
    userEmail: 'jateva01@gmail.com',
    locationName: 'น้ำตกสวย',
    place: 'ยะลา',
    date: DateTime.now(),
    photoUrl: 'https://picsum.photos/id/1018/800/460',
    likeCount: 2,
    commentCount: 3,
  ),
  UserLocationItem(
    userId: 'u2',
    userName: 'Vanessa',
    userEmail: 'vanessa@example.com',
    locationName: 'จุดชมวิวเขาใหญ่',
    place: 'นครราชสีมา',
    date: DateTime.now().subtract(const Duration(days: 2)),
    photoUrl: 'https://picsum.photos/id/1025/800/460',
    likeCount: 5,
    commentCount: 1,
  ),
];
