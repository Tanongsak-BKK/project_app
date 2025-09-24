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
    final prov = context.watch<PlaceProvider>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติ/รายการของฉัน'),
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
          ? const Center(child: Text('กรุณาเข้าสู่ระบบเพื่อดูรายการของคุณ'))
          : prov.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _MyPlacesList(
                  items: prov.places.where((p) => p.userId == uid).toList(), // << แสดงเฉพาะของฉัน
                  busy: _busy,
                  onDelete: (p) => _deletePlace(context, p),
                ),
    );
  }
}

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
