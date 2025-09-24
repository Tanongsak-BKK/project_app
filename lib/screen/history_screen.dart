import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      // ❌ ลบที่ Firestore
      await FirebaseFirestore.instance.collection('places').doc(place.id).delete();

      // 🗂️ ลบออกจาก Provider ทันที (ไม่ต้องโหลดใหม่ทั้งก้อน)
      if (mounted) {
        context.read<PlaceProvider>().removeById(place.id);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบเรียบร้อย')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PlaceProvider>();
    final items = prov.places; // ถ้ามี myPlaces() ก็สลับมาใช้ได้

    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติ/รายการของฉัน'),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('ยังไม่มีรายการ'))
              : ListView.separated(
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
                          onPressed: _busy ? null : () => _deletePlace(context, p),
                          tooltip: 'ลบ',
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
