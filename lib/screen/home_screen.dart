// lib/screen/home_screen.dart 
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:project_app/model/place.dart'; // ต้องมี enum Region และ class Place
import 'package:project_app/provider/place_provider.dart';
import 'package:project_app/screen/detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PlaceProvider>().loadPlaces());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _card = Color(0xFF151517);
  static const _field = Color(0xFF1A1B1F);
  static const _accent = Color(0xFF2F80ED);

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PlaceProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("lib/images/background-onboarding.jpg"),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: DefaultTabController(
            length: 5, // ← มี 5 แท็บ: ทั้งหมด + 4 ภูมิภาค
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Opacity(
                              opacity: .7,
                              child: Text(
                                "You're in New York",
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: const Color.fromARGB(179, 0, 0, 0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Let's explore!",
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search
                  TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white70,
                    decoration: InputDecoration(
                      hintText: "ค้นหาชื่อสถานที่…",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: _field,
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      suffixIcon: (_query.isEmpty)
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, color: Colors.white70),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (q) => setState(() => _query = q.trim()),
                    onSubmitted: (q) => setState(() => _query = q.trim()),
                  ),

                  const SizedBox(height: 14),

                  // Tabs
                  const _CategoryTabs(),
                  const SizedBox(height: 12),

                  // เนื้อหาแท็บ
                  Expanded(
                    child: prov.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : prov.error != null
                            ? Center(
                                child: Text(
                                  prov.error!,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              )
                            : TabBarView(
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  // ← เพิ่มแท็บ "ทั้งหมด" หน้าแรก
                                  _AllTab(query: _query),
                                  _RegionTab(region: Region.north, query: _query),
                                  _RegionTab(region: Region.south, query: _query),
                                  _RegionTab(region: Region.east,  query: _query),
                                  _RegionTab(region: Region.west,  query: _query),
                                ],
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* --------------------------- Tabs ---------------------------- */

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs();

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: true,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(width: 3, color: _HomeScreenState._accent),
        insets: EdgeInsets.symmetric(horizontal: 8),
      ),
      tabs: const [
        Tab(text: 'ทั้งหมด'), // ← เพิ่มแท็บรวมทั้งหมด
        Tab(text: 'เหนือ'),
        Tab(text: 'ใต้'),
        Tab(text: 'ตะวันออก'),
        Tab(text: 'ตะวันตก'),
      ],
    );
  }
}

/* -------------------- Tab content by region ------------------ */

class _RegionTab extends StatelessWidget {
  final Region region;
  final String query;
  const _RegionTab({required this.region, required this.query});

  @override
  Widget build(BuildContext context) {
    final rawItems = context.select<PlaceProvider, List<Place>>(
      (p) => p.byRegion(region),
    );
    final rawFavs = context.select<PlaceProvider, List<Place>>(
      (p) => p.bookmarkedByRegion(region),
    );

    final q = query.trim().toLowerCase();
    bool matches(Place p) => q.isEmpty || p.title.toLowerCase().contains(q);

    final items = rawItems.where(matches).toList();
    final favs  = rawFavs.where(matches).toList();

    if (items.isEmpty && favs.isEmpty) {
      return Center(
        child: Text(
          q.isEmpty ? 'ยังไม่มีข้อมูลในหมวดนี้' : 'ไม่พบผลลัพธ์สำหรับ “$query”',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    const grid = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.78,
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (items.isNotEmpty)
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: grid,
            itemCount: items.length,
            itemBuilder: (_, i) => _PlaceCard(place: items[i]),
          ),

        if (favs.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Row(
            children: [
              Text("Popular",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              Spacer(),
            ],
          ),
          const SizedBox(height: 8),

          // แถบ Popular แนวนอน (เต็มแถบ)
          LayoutBuilder(
            builder: (context, c) {
              final tileWidth = c.maxWidth;
              return SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: favs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => SizedBox(
                    width: tileWidth,
                    child: _PopularTile(place: favs[i]),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

/* ----------------------- All Tab (new) ----------------------- */

class _AllTab extends StatelessWidget {
  final String query;
  const _AllTab({required this.query});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PlaceProvider>();
    final q = query.trim().toLowerCase();

    bool matches(Place p) => q.isEmpty || p.title.toLowerCase().contains(q);

    final items = prov.places.where(matches).toList();
    final favs  = prov.bookmarked().where(matches).toList();

    if (items.isEmpty && favs.isEmpty) {
      return Center(
        child: Text(
          q.isEmpty ? 'ยังไม่มีข้อมูล' : 'ไม่พบผลลัพธ์สำหรับ “$query”',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    const grid = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.78,
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (items.isNotEmpty)
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: grid,
            itemCount: items.length,
            itemBuilder: (_, i) => _PlaceCard(place: items[i]),
          ),

        if (favs.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Row(
            children: [
              Text("Popular",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              Spacer(),
            ],
          ),
          const SizedBox(height: 8),

          LayoutBuilder(
            builder: (context, c) {
              final tileWidth = c.maxWidth;
              return SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: favs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => SizedBox(
                    width: tileWidth,
                    child: _PopularTile(place: favs[i]),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

/* ----------------------- Components -------------------------- */

class _PlaceCard extends StatelessWidget {
  final Place place;
  const _PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    final isSaved = context.select<PlaceProvider, bool>(
      (p) => p.isBookmarked(place.id),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          // ภาพ
          Positioned.fill(
            child: Image.network(
              place.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, color: Colors.white54),
              ),
            ),
          ),
          // ไล่โทน
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.transparent, Colors.black54],
                  ),
                ),
              ),
            ),
          ),
          // ข้อความ
          Positioned(
            left: 12, right: 12, bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Stars(rating: place.rating),
                const SizedBox(height: 6),
                Text(
                  place.title,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, height: 1.15),
                ),
              ],
            ),
          ),
          // ชั้นกดทั้งการ์ด -> Detail
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => DetailScreen(place: place))),
              ),
            ),
          ),
          // ปุ่มบุ๊กมาร์ก (อยู่บนสุด)
          Positioned(
            top: 10, right: 10,
            child: Container(
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.white),
                onPressed: () => context.read<PlaceProvider>().toggleBookmark(place.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------- Popular Tile ------------------------ */

class _PopularTile extends StatelessWidget {
  final Place place;
  const _PopularTile({required this.place});

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(place: place)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _HomeScreenState._card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetail(context), // แตะทั้งแถบไป detail
        child: SizedBox(
          height: 110, // ให้ตรงกับส่วนที่กำหนดใน ListView
          child: Row(
            children: [
              // รูปซ้ายเต็มช่อง
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: SizedBox(
                  width: 120,
                  height: double.infinity,
                  child: Image.network(
                    place.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black26,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported, color: Colors.white54),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // ข้อความ
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Color(0xFFFFD166)),
                          const SizedBox(width: 4),
                          Text(
                            place.rating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ลูกศร -> ไปหน้า detail เหมือนกัน
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white70),
                onPressed: () => _openDetail(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ----------------------- Stars ------------------------------- */

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
          if (i < full) return const Icon(Icons.star, size: 16, color: Color(0xFFFFD166));
          if (i == full && half) return const Icon(Icons.star_half, size: 16, color: Color(0xFFFFD166));
          return const Icon(Icons.star_border, size: 16, color: Color(0xFFFFD166));
        }),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
