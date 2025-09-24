import 'package:flutter/foundation.dart';
import '../model/place.dart';
import '../service/place_service.dart';
import '../service/place_service_firebase.dart';

class PlaceProvider extends ChangeNotifier {
  final PlaceService _service = PlaceServiceFirebase();

  List<Place> _places = [];
  bool _isLoading = false;
  String? _error;

  // เก็บสถานะ bookmark แยกเป็นเซ็ตของ id (ไม่ผูกที่โมเดล)
  final Set<String> _bookmarkedIds = <String>{};

  List<Place> get places => _places;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPlaces() async {
    _isLoading = true;
    notifyListeners();
    try {
      _places = await _service.fetchPlaces();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ ลบจาก state โดยไม่แตะ Firestore (ใช้คู่กับการลบ Firestore ภายนอก)
  void removeById(String id) {
    _places.removeWhere((p) => p.id == id);
    _bookmarkedIds.remove(id); // เคลียร์บุ๊กมาร์กของรายการที่ถูกลบ
    notifyListeners();
    // ไม่เรียก fetch ใหม่ เพื่อให้ UI เร็วและไม่กระพริบ
  }

  /* -------------------- Helpers used by UI -------------------- */

  List<Place> byRegion(Region r) => _places.where((p) => p.region == r).toList();

  List<Place> bookmarked() => _places.where((p) => _bookmarkedIds.contains(p.id)).toList();

  List<Place> bookmarkedByRegion(Region r) =>
      _places.where((p) => _bookmarkedIds.contains(p.id) && p.region == r).toList();

  bool isBookmarked(String id) => _bookmarkedIds.contains(id);

  void toggleBookmark(String id) {
    if (_bookmarkedIds.contains(id)) {
      _bookmarkedIds.remove(id);
    } else {
      _bookmarkedIds.add(id);
    }
    notifyListeners();
  }
}
