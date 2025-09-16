import '../model/place.dart';

abstract class PlaceService {
  Future<List<Place>> fetchPlaces();            // โหลดครั้งเดียว
  Stream<List<Place>> streamPlaces();           // real-time (optional)
  Stream<List<Place>> streamByRegion(Region r); // real-time ต่อแท็บ (optional)
}
