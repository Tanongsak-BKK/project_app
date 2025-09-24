// lib/screen/detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/place.dart';

class DetailScreen extends StatefulWidget {
  final Place place;
  const DetailScreen({super.key, required this.place});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _readMore = false;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ใช้ข้อมูลจริงจาก place (non-nullable)
    final imageUrl    = widget.place.imageUrl;
    final title       = widget.place.title;
    final region      = widget.place.region;
    final rating      = widget.place.rating;
    final address     = widget.place.address.trim();
    final description = widget.place.description.trim();
    final popularity  = widget.place.popularity;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // รูปหัว
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl.isNotEmpty)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(),
                        )
                      else
                        _imageFallback(),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black26],
                          ),
                        ),
                      ),
                      // badge ความป๊อป
                      Positioned(
                        right: 10,
                        top: 10,
                        child: _PopularityBadge(popularity: popularity),
                      ),
                    ],
                  ),
                ),

                // การ์ดรายละเอียด
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 12,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ชื่อ
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // ภูมิภาค + ดาว
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              _regionLabel(region),
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const Spacer(),
                            _Stars(rating: rating),
                          ],
                        ),

                        // ที่อยู่ (ถ้ามี)
                        if (address.isNotEmpty) ...[
                          const Divider(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.map_rounded, color: Colors.black54, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  address,
                                  style: const TextStyle(color: Colors.black87, height: 1.3),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                tooltip: 'คัดลอกที่อยู่',
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: address));
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('คัดลอกที่อยู่แล้ว')),
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 18, color: Colors.black54),
                              ),
                            ],
                          ),
                        ],

                        // รายละเอียด (description)
                        if (description.isNotEmpty) ...[
                          const Divider(height: 24),
                          Text(
                            "รายละเอียด",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedCrossFade(
                            firstChild: Text(
                              description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black87, height: 1.4),
                            ),
                            secondChild: Text(
                              description,
                              style: const TextStyle(color: Colors.black87, height: 1.4),
                            ),
                            crossFadeState: _readMore
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                          if (description.length > 140)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () => setState(() => _readMore = !_readMore),
                                child: Text(_readMore ? "Read less" : "Read more"),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ปุ่ม Back
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() => Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, size: 40, color: Colors.black38),
      );

  String _regionLabel(Region r) {
    switch (r) {
      case Region.north: return "North, Thailand";
      case Region.south: return "South, Thailand";
      case Region.east:  return "East, Thailand";
      case Region.west:  return "West, Thailand";
    }
  }
}

/* -------------------------- Widgets -------------------------- */

class _PopularityBadge extends StatelessWidget {
  final int popularity;
  const _PopularityBadge({required this.popularity});

  @override
  Widget build(BuildContext context) {
    if (popularity <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 18),
          const SizedBox(width: 6),
          Text(
            '$popularity',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    return Row(
      children: [
        ...List.generate(5, (i) {
          if (i < full) {
            return const Icon(Icons.star, size: 18, color: Color(0xFFFFD166));
          } else if (i == full && half) {
            return const Icon(Icons.star_half, size: 18, color: Color(0xFFFFD166));
          }
          return const Icon(Icons.star_border, size: 18, color: Color(0xFFFFD166));
        }),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
