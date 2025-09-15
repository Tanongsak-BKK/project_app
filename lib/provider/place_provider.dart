import 'package:flutter/foundation.dart';
import '../model/place.dart';
import '../service/place_service.dart';
import '../service/place_service_firebase.dart';

class PlaceProvider extends ChangeNotifier {
  final PlaceService _service;
  PlaceProvider({PlaceService? service}) : _service = service ?? PlaceServiceFirebase();

  List<Place> _places = [];
  bool _loading = false;
  String? _error;

  // --- bookmarks (เก็บเฉพาะ id, ยังไม่ persist) ---
  final Set<String> _bookmarks = {};

  List<Place> get places => _places;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> loadPlaces() async {
    _loading = true; _error = null; notifyListeners();
    try {
      _places = await _service.fetchPlaces();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  // Filter ตาม region
  List<Place> byRegion(Region r) => _places.where((p) => p.region == r).toList();

  // --- bookmark helpers ---
  bool isBookmarked(String id) => _bookmarks.contains(id);

  void toggleBookmark(String id) {
    if (_bookmarks.contains(id)) {
      _bookmarks.remove(id);
    } else {
      _bookmarks.add(id);
    }
    notifyListeners();
  }

  List<Place> bookmarked() =>
      _places.where((p) => _bookmarks.contains(p.id)).toList();

  List<Place> bookmarkedByRegion(Region r) =>
      _places.where((p) => p.region == r && _bookmarks.contains(p.id)).toList();
}
