enum Region { north, south, east, west }

Region mapRegion(String? s) {
  switch ((s ?? '').toLowerCase()) {
    case 'north': case 'เหนือ': return Region.north;
    case 'south': case 'ใต้': return Region.south;
    case 'east':  case 'ตะวันออก': return Region.east;
    case 'west':  case 'ตะวันตก': return Region.west;
    default: return Region.north;
  }
}

String regionToString(Region r) => switch (r) {
  Region.north => 'north',
  Region.south => 'south',
  Region.east  => 'east',
  Region.west  => 'west',
};

class Place {
  final String id;
  final String title;
  final double rating;
  final String imageUrl;
  final Region region;

  Place({required this.id, required this.title, required this.rating, required this.imageUrl, required this.region});

  factory Place.fromMap(Map<String, dynamic> data, String id) => Place(
    id: id,
    title: data['title'] ?? '',
    rating: (data['rating'] ?? 0).toDouble(),
    imageUrl: data['imageUrl'] ?? '',
    region: mapRegion(data['region']),
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'rating': rating,
    'imageUrl': imageUrl,
    'region': regionToString(region),
  };
}
