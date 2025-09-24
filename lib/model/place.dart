// lib/model/place.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum Region { north, south, east, west }

String regionToKey(Region r) {
  switch (r) {
    case Region.north: return 'north';
    case Region.south: return 'south';
    case Region.east:  return 'east';
    case Region.west:  return 'west';
  }
}

Region keyToRegion(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'north': return Region.north;
    case 'south': return Region.south;
    case 'east':  return Region.east;
    case 'west':  return Region.west;
    default:      return Region.north; // ค่าเริ่มต้นกันพัง
  }
}

class Place {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String imageUrl;
  final String address;
  final Region region;
  final double rating;
  final int popularity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Place({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.address,
    required this.region,
    required this.rating,
    required this.popularity,
    this.createdAt,
    this.updatedAt,
  });

  factory Place.fromMap(Map<String, dynamic> m, String id) {
    // ช่วยแปลง number -> double/int ปลอดภัย
    double _toDouble(dynamic v, {double def = 0}) {
      if (v is int) return v.toDouble();
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return def;
    }

    int _toInt(dynamic v, {int def = 0}) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is num) return v.toInt();
      return def;
    }

    return Place(
      id: id,
      userId: (m['userId'] ?? '') as String,
      title: (m['title'] ?? '') as String,
      description: (m['description'] ?? '') as String,
      imageUrl: (m['imageUrl'] ?? '') as String,
      address: (m['address'] ?? '') as String,
      region: keyToRegion(m['region'] as String?),
      rating: _toDouble(m['rating'], def: 0).clamp(0, 5),
      popularity: _toInt(m['popularity'], def: 0),
      createdAt: (m['createdAt'] is Timestamp) ? (m['createdAt'] as Timestamp).toDate() : null,
      updatedAt: (m['updatedAt'] is Timestamp) ? (m['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'address': address,
      'region': regionToKey(region),
      'rating': rating,
      'popularity': popularity,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
