import 'dart:async';
import 'place_service.dart';
import '../model/place.dart';

/// TODO: เปิดใช้ cloud_firestore เมื่อพร้อม
/// import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceServiceFirebase implements PlaceService {
  // TODO: เปลี่ยนเป็น CollectionReference เมื่อเชื่อม Firestore
  // final _col = FirebaseFirestore.instance.collection('places');

  @override
  Future<List<Place>> fetchPlaces() async {
    // TODO: ดึงจาก Firestore จริง
    // final snap = await _col.orderBy('updatedAt', descending: true).get();
    // return snap.docs.map((d) => Place.fromMap(d.data(), d.id)).toList();

    // Mock ชั่วคราว (ให้ UI ใช้งานได้)
    return [
      Place(id: '1', title: 'ดอยอินทนนท์', rating: 4.8, imageUrl: 'https://picsum.photos/600/400?1', region: Region.north),
      Place(id: '2', title: 'เกาะหลีเป๊ะ',  rating: 4.6, imageUrl: 'https://picsum.photos/600/400?2', region: Region.south),
      Place(id: '3', title: 'ระยองแคนยอน',  rating: 4.2, imageUrl: 'https://picsum.photos/600/400?3', region: Region.east),
      Place(id: '4', title: 'อัมพวา',       rating: 4.3, imageUrl: 'https://picsum.photos/600/400?4', region: Region.west),
    ];
  }

  @override
  Stream<List<Place>> streamPlaces() async* {
    // TODO: return _col.snapshots().map(...);
    yield await fetchPlaces(); // ชั่วคราว
  }

  @override
  Stream<List<Place>> streamByRegion(Region r) async* {
    // TODO: return _col.where('region', isEqualTo: regionToString(r)).snapshots().map(...);
    final all = await fetchPlaces();
    yield all.where((p) => p.region == r).toList();
  }
}
