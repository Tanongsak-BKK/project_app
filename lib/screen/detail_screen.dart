// lib/screen/detail_screen.dart
import 'package:flutter/material.dart';
import '../model/place.dart';

class DetailScreen extends StatefulWidget {
  final Place place;
  const DetailScreen({super.key, required this.place, required String placeId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _readMore = false;

  static const _accent = Color(0xFF2F80ED);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // คำบรรยายตัวอย่าง (หากยังไม่มีในโมเดล)
    final aboutText =
        "San Marino is a mountainous microstate surrounded by north-central Italy. "
        "Among the world's oldest republics, it retains much of its historic architecture. "
        "On the slopes of Monte Titano sits the capital, also called San Marino, known for its ...";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // รูปหัว (Hero ถ้าอยากทำต่อ)
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.place.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.black12,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported, size: 40, color: Colors.black38),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black26],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // การ์ดรายละเอียดซ้อนทับ
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
                        // ชื่อ + ที่ตั้ง + ดาว
                        Text(
                          widget.place.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              _regionLabel(widget.place.region),
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _Stars(rating: widget.place.rating),
                        const SizedBox(height: 16),

                        // About
                        Text(
                          "About",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedCrossFade(
                          firstChild: Text(
                            aboutText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black87, height: 1.4),
                          ),
                          secondChild: Text(
                            aboutText,
                            style: const TextStyle(color: Colors.black87, height: 1.4),
                          ),
                          crossFadeState:
                              _readMore ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () => setState(() => _readMore = !_readMore),
                          child: Text(_readMore ? "Read less" : "Read more"),
                        ),

                        const SizedBox(height: 8),

                        // Including Services
                        Text(
                          "Including Services",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _ServiceChip(label: "Air ticket"),
                            _ServiceChip(label: "train ticket"),
                            _ServiceChip(label: "3 star hotel"),
                            _ServiceChip(label: "buffet"),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ราคา + ปุ่ม Book
                        Row(
                          children: [
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: "450",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 28,
                                    ),
                                  ),
                                  TextSpan(
                                    text: " /Package",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                // TODO: hook ฟังก์ชันจองจริงภายหลัง
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Booking not implemented yet.")),
                                );
                              },
                              child: const Text(
                                "BOOK NOW",
                                style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ปุ่ม Back แบบกลมวางบนรูป
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

  String _regionLabel(Region r) {
    switch (r) {
      case Region.north:
        return "North, Thailand";
      case Region.south:
        return "South, Thailand";
      case Region.east:
        return "East, Thailand";
      case Region.west:
        return "West, Thailand";
    }
  }
}

/* -------------------------- Widgets -------------------------- */

class _ServiceChip extends StatelessWidget {
  final String label;
  const _ServiceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF111827), fontSize: 12, fontWeight: FontWeight.w600),
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
