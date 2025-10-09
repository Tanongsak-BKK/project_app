// lib/service/place_service_firebase.dart
import 'dart:async';
import 'place_service.dart';
import '../model/place.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceServiceFirebase implements PlaceService {
  final _col = FirebaseFirestore.instance.collection('places');

  @override
  Future<List<Place>> fetchPlaces() async {
    final snap = await _col.orderBy('updatedAt', descending: true).get();
    return snap.docs.map((d) => Place.fromMap(d.data(), d.id)).toList();
  }

  @override
  Stream<List<Place>> streamPlaces() {
    return _col.orderBy('updatedAt', descending: true).snapshots().map(
          (qs) => qs.docs.map((d) => Place.fromMap(d.data(), d.id)).toList(),
        );
  }

  @override
  Stream<List<Place>> streamByRegion(Region r) {
    return _col
        .where('region', isEqualTo: regionToKey(r))
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map((d) => Place.fromMap(d.data(), d.id)).toList());
  }
}
