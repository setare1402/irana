
import 'package:flutter/material.dart';

void main() {
  runApp(const IranaApp());
}

const Color iranaPurple = Color(0xFF7139A8);
const Color iranaPink = Color(0xFFE84B91);
const Color iranaBg = Color(0xFFFAF9FC);

class IranaApp extends StatelessWidget {
  const IranaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IRANA',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: iranaBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: iranaPurple,
        ),
        fontFamily: 'Roboto',
      ),
      home: const IranaHome(),
    );
  }
}

class IranaHome extends StatefulWidget {
  const IranaHome({super.key});

  @override
  State<IranaHome> createState() => _IranaHomeState();
}

class _IranaHomeState extends State<IranaHome> {
  int selectedIndex = 0;

  final List<String> pages = [
    'خانه',
    'جستجو',
    'انتشار',
    'ویدئوها',
    'پروفایل',
  ];

  final List<IconData> icons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.add_box_outlined,
    Icons.video_library_outlined,
    Icons.person_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'IRANA',
            style: TextStyle(
              color: iranaPurple,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.favorite_border,
                color: Colors.black87,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.send_outlined,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 5),
          ],
        ),
        body: IndexedStack(
          index: selectedIndex,
          children: const [
            FeedPage(),
            SearchPage(),
            CreatePage(),
            VideosPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.white,
          selectedIndex: selectedIndex,
          indicatorColor: iranaPurple.withValues(alpha: 0.12),
          onDestinationSelected: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          destinations: List.generate(
            pages.length,
            (index) => NavigationDestination(
              icon: Icon(icons[index]),
              selectedIcon: Icon(
                icons[index],
                color: iranaPurple,
              ),
              label: pages[index],
            ),
          ),
        ),
      ),
    );
  }
}

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'استوری‌ها',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 105,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: const [
              StoryItem(name: 'استوری من', own: true),
              StoryItem(name: 'آرمان'),
              StoryItem(name: 'سارا'),
              StoryItem(name: 'رضا'),
              StoryItem(name: 'مریم'),
              StoryItem(name: 'علی'),
            ],
          ),
        ),
        const Divider(height: 20),
        const PostCard(
          username: 'irana_official',
          caption: 'به دنیای ایرانا خوش آمدید 💜',
          symbol: Icons.public,
          color: Color(0xFFE9DDF7),
        ),
        const PostCard(
          username: 'irana_world',
          caption: 'اینجا آغاز یک ارتباط تازه است 🌍',
          symbol: Icons.landscape,
          color: Color(0xFFDCEBE7),
        ),
        const PostCard(
          username: 'iranian_people',
          caption: 'با هم دنیای زیباتری می‌سازیم.',
          symbol: Icons.people_alt,
          color: Color(0xFFF6E2EB),
        ),
      ],
    );
  }
}

class StoryItem extends StatelessWidget {
  final String name;
  final bool own;

  const StoryItem({
    super.key,
    required this.name,
    this.own = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [iranaPink, iranaPurple],
              ),
            ),
            child: CircleAvatar(
              radius: 29,
              backgroundColor: Colors.white,
              child: own
                  ? const Icon(
                      Icons.add,
                      color: iranaPurple,
                      size: 28,
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            maxLines: 1,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final String username;
  final String caption;
  final IconData symbol;
  final Color color;

  const PostCard({
    super.key,
    required this.username,
    required this.caption,
    required this.symbol,
    required this.color,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool liked = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEDE2F7),
              child: Icon(Icons.person, color: iranaPurple),
            ),
            title: Text(
              widget.username,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            trailing: const Icon(Icons.more_vert),
          ),
          Container(
            height: 260,
            width: double.infinity,
            color: widget.color,
            child: Icon(
              widget.symbol,
              size: 95,
              color: iranaPurple.withValues(alpha: 0.65),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      liked = !liked;
                    });
                  },
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.red : Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.mode_comment_outlined),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.send_outlined),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            child: Text(
              widget.caption,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'جستجوی افراد و موضوعات...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Icon(
            Icons.travel_explore,
            size: 75,
            color: iranaPurple,
          ),
          const SizedBox(height: 12),
          const Text(
            'جهان ایرانا را کشف کن',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class CreatePage extends StatelessWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_circle_outline,
            size: 90,
            color: iranaPurple,
          ),
          const SizedBox(height: 16),
          const Text(
            'ساخت پست جدید',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text('به‌زودی امکان انتشار عکس و ویدئو'),
        ],
      ),
    );
  }
}

class VideosPage extends StatelessWidget {
  const VideosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 90,
            color: iranaPurple,
          ),
          SizedBox(height: 16),
          Text(
            'ویدئوهای ایرانا',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text('دنیایی از ویدئوها در راه است'),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        const CircleAvatar(
          radius: 48,
          backgroundColor: Color(0xFFE9DDF7),
          child: Icon(
            Icons.person,
            size: 55,
            color: iranaPurple,
          ),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            'کاربر ایرانا',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Center(
          child: Text(
            '@irana_user',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 25),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ProfileStat(number: '0', label: 'پست'),
            ProfileStat(number: '0', label: 'دنبال‌کننده'),
            ProfileStat(number: '0', label: 'دنبال‌شونده'),
          ],
        ),
        const SizedBox(height: 25),
        OutlinedButton(
          onPressed: () {},
          child: const Text('ویرایش پروفایل'),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const Center(
          child: Text(
            'به خانواده بزرگ ایرانا خوش آمدید 💜',
          ),
        ),
      ],
    );
  }
}

class ProfileStat extends StatelessWidget {
  final String number;
  final String label;

  const ProfileStat({
    super.key,
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }
}
