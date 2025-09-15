import 'dart:ui' show Offset;
import 'package:flutter/material.dart';

class ListLocationPage extends StatelessWidget {
  const ListLocationPage({
    super.key,
    required this.provinceId,
    required this.provinceName,
    required this.points,
    // ถ้ามีข้อมูลจริง (ชื่อ/วันที่/สถานที่) สามารถส่ง items เข้ามาแทนการสร้างจาก points ได้
    this.items,
  });

  final String provinceId;
  final String provinceName;
  final List<Offset> points;

  /// รายการจริง (ถ้ามี). ถ้า null จะสร้างจาก points อัตโนมัติ
  final List<LocationItem>? items;

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFE7F3EE);

    // สร้างรายการจาก points ถ้าไม่ส่ง items มา
    final list = items ??
        points.asMap().entries.map((e) {
          final i = e.key + 1;
          return LocationItem(
            name: 'สถานที่ #$i',
            place: provinceName,
            date: DateTime.now(),
          );
        }).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(provinceName),
        centerTitle: true,
      ),
      body: list.isEmpty
          ? const Center(child: Text('ยังไม่มีสถานที่ในจังหวัดนี้'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final item = list[i];
                return _LocationCard(item: item);
              },
            ),
    );
  }
}

/// การ์ด 1 แถว ตามภาพ: ด้านซ้าย 3 pills, ด้านขวาเมนู ... และวันที่ตัวใหญ่
class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.item});
  final LocationItem item;

  @override
  Widget build(BuildContext context) {
    final white = Colors.white;
    final shadow = const BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4));
    final dateText = _formatThaiDateLong(item.date);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [shadow],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: 3 pills
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Pill(icon: Icons.edit_outlined, text: item.name),
                const SizedBox(height: 6),
                _Pill(icon: Icons.place_outlined, text: item.place),
                const SizedBox(height: 6),
                _Pill(icon: Icons.event_note_outlined, text: _formatThaiDateShort(item.date)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right: menu + big date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('แก้ไขรายการ')),
                  PopupMenuItem(value: 'delete', child: Text('ลบ')),
                ],
                onSelected: (v) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เลือกเมนู: $v')),
                  );
                },
                padding: EdgeInsets.zero,
                child: const Icon(Icons.more_vert, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                dateText,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// pill กล่องมน ๆ สีอ่อน มีไอคอนซ้าย
class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final bgPill = const Color(0xFFE7F3EE); // สีเดียวกับพื้น ให้ดูจาง
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

/// ข้อมูล 1 รายการ
class LocationItem {
  final String name;
  final String place;
  final DateTime date;

  LocationItem({
    required this.name,
    required this.place,
    required this.date,
  });
}

/// ---- Format helpers (Thai date) ----
const _thaiMonthsShort = [
  '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
];

String _formatThaiDateShort(DateTime d) {
  final yBE = d.year + 543;
  return '${d.day} ${_thaiMonthsShort[d.month]} $yBE';
}

String _formatThaiDateLong(DateTime d) => _formatThaiDateShort(d);
