import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFFE7F3EE);
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: _bg,
        body: const TabBarView(
          children: [
            _FeedTab(),
          ],
        ),
      ),
    );
  }
}

class _FeedTab extends StatefulWidget {
  const _FeedTab();

  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> {
  final posts = <_Post>[
    _Post(
      userName: 'Kanchaphon Joysoungnarn',
      userAvatar:
          'https://i.pravatar.cc/100?img=12', // ใช้เน็ตเวิร์กแทน asset ให้รันทันที
      timeAgo: '1 วันที่แล้ว',
      text: 'เขาตีนไก่\nมาวิ่งเทรลที่เขาตีนไก่',
      mainPhoto: 'https://picsum.photos/id/1018/1000/700',
      photos: const [
        'https://picsum.photos/id/1006/500/400',
        'https://picsum.photos/id/1003/500/400',
        'https://picsum.photos/id/1011/500/400',
      ],
      likes: 1,
      comments: 0,
    ),
    _Post(
      userName: 'สุลต่านบ้านตลาด',
      userAvatar: 'https://i.pravatar.cc/100?img=5',
      timeAgo: '2 วันที่แล้ว',
      text: 'เวโรน่า @ ทับลาน',
      mainPhoto: 'https://picsum.photos/id/1020/1000/700',
      photos: const [
        'https://picsum.photos/id/1024/500/400',
        'https://picsum.photos/id/1027/500/400',
        'https://picsum.photos/id/1035/500/400',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: posts.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return const _Composer();
        return _PostCard(post: posts[i - 1]);
      },
    );
  }
}

/// กล่อง “เล่าเรื่องราวของคุณที่นี่” + ปุ่มค้นหา
class _Composer extends StatelessWidget {
  const _Composer();

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(color: Colors.black.withOpacity(.08)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              readOnly: true,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ไปหน้าเขียนเรื่องราว…')),
              ),
              decoration: InputDecoration(
                hintText: 'เล่าเรื่องราวของคุณที่นี่',
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon:
                    const Icon(Icons.edit_outlined, color: Colors.black45),
                enabledBorder: border,
                focusedBorder: border,
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ค้นหาเรื่องราว')),
            ),
            borderRadius: BorderRadius.circular(28),
            child: Ink(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.search, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

/// การ์ดโพสต์ตามภาพ
class _PostCard extends StatefulWidget {
  const _PostCard({required this.post});
  final _Post post;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool liked = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final card = Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(p.userAvatar),
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(p.timeAgo,
                          style: const TextStyle(
                              color: Colors.black45, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Text
          if (p.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(p.text, style: const TextStyle(fontSize: 15)),
            ),

          // Main photo
          if (p.mainPhoto != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                p.mainPhoto!,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
              ),
            ),
          ],

          // Thumbnails row
          if (p.photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 74,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: p.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(p.photos[i],
                      width: 110, height: 74, fit: BoxFit.cover),
                ),
              ),
            ),
          ],

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Row(
              children: [
                InkWell(
                  onTap: () => setState(() => liked = !liked),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          liked
                              ? Icons.favorite
                              : Icons.favorite_border_outlined,
                          size: 20,
                          color: liked ? Colors.pink : Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(p.likes) + (liked ? 1 : 0)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไปหน้าคอมเมนต์'))),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: const [
                        Icon(Icons.mode_comment_outlined,
                            size: 20, color: Colors.black54),
                        SizedBox(width: 6),
                        Text('คอมเมนต์',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return card;
  }
}



/// Simple model for feed
class _Post {
  final String userName;
  final String userAvatar;
  final String timeAgo;
  final String text;
  final String? mainPhoto;
  final List<String> photos;
  final int likes;
  final int comments;

  _Post({
    required this.userName,
    required this.userAvatar,
    required this.timeAgo,
    required this.text,
    this.mainPhoto,
    this.photos = const [],
    this.likes = 0,
    this.comments = 0,
  });
}
