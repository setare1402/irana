import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IranaApp());
}

const Color iranaPurple = Color(0xFF7139A8);
const Color iranaPink = Color(0xFFE84B91);
const Color iranaBg = Color(0xFFFAF9FC);
const Color iranaGold = Color(0xFFFFD778);

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
        colorScheme: ColorScheme.fromSeed(seedColor: iranaPurple),
        fontFamily: 'Roboto',
      ),
      home: const IranaHome(),
    );
  }
}

class IranaPost {
  final String id;
  final String username;
  final String caption;
  final String imagePath;
  final DateTime date;
  final bool liked;
  final bool isVideo;

  IranaPost({
    required this.id,
    required this.username,
    required this.caption,
    required this.imagePath,
    required this.date,
    this.liked = false,
    this.isVideo = false,
  });

  IranaPost copyWith({bool? liked}) {
    return IranaPost(
      id: id,
      username: username,
      caption: caption,
      imagePath: imagePath,
      date: date,
      liked: liked ?? this.liked,
      isVideo: isVideo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'caption': caption,
        'imagePath': imagePath,
        'date': date.toIso8601String(),
        'liked': liked,
        'isVideo': isVideo,
      };

  factory IranaPost.fromJson(Map<String, dynamic> json) {
    return IranaPost(
      id: json['id'],
      username: json['username'],
      caption: json['caption'] ?? '',
      imagePath: json['imagePath'],
      date: DateTime.parse(json['date']),
      liked: json['liked'] ?? false,
      isVideo: json['isVideo'] ?? false,
    );
  }
}

class IranaStory {
  final String id;
  final String username;
  final String filePath;
  final bool isVideo;
  final DateTime createdAt;

  IranaStory({
    required this.id,
    required this.username,
    required this.filePath,
    required this.isVideo,
    required this.createdAt,
  });

  bool get expired => DateTime.now().difference(createdAt).inHours >= 24;

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'filePath': filePath,
        'isVideo': isVideo,
        'createdAt': createdAt.toIso8601String(),
      };

  factory IranaStory.fromJson(Map<String, dynamic> json) {
    return IranaStory(
      id: json['id'],
      username: json['username'],
      filePath: json['filePath'],
      isVideo: json['isVideo'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
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
  bool loading = true;
  List<IranaPost> posts = [];
  List<IranaStory> stories = [];

  final ImagePicker picker = ImagePicker();

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
  void initState() {
    super.initState();
    loadData();
  }

  Future<Directory> get mediaDirectory async {
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory('${directory.path}/irana_media');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final postData = prefs.getString('irana_posts');
      final storyData = prefs.getString('irana_stories');

      if (postData != null) {
        posts = (jsonDecode(postData) as List)
            .map((e) => IranaPost.fromJson(e))
            .where((p) => File(p.imagePath).existsSync())
            .toList();
      }

      if (storyData != null) {
        stories = (jsonDecode(storyData) as List)
            .map((e) => IranaStory.fromJson(e))
            .where((s) => !s.expired && File(s.filePath).existsSync())
            .toList();
      }
    } catch (_) {
      posts = [];
      stories = [];
    }

    await saveData();

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'irana_posts',
      jsonEncode(posts.map((e) => e.toJson()).toList()),
    );

    await prefs.setString(
      'irana_stories',
      jsonEncode(stories.map((e) => e.toJson()).toList()),
    );
  }

  Future<String> copyMedia(XFile file) async {
    final folder = await mediaDirectory;
    final extension =
        file.name.contains('.') ? file.name.split('.').last : 'jpg';
    final destination =
        '${folder.path}/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await File(file.path).copy(destination);
    return destination;
  }

  bool isVideoFile(XFile file) {
    final mime = file.mimeType ?? '';
    final name = file.name.toLowerCase();

    return mime.startsWith('video/') ||
        name.endsWith('.mp4') ||
        name.endsWith('.mov') ||
        name.endsWith('.m4v');
  }

  // صفحه جدید ساخت استوری
  Future<void> addStory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryCreatePage(
          onPublish: (file, video) async {
            final path = await copyMedia(file);

            final story = IranaStory(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              username: 'irana_user',
              filePath: path,
              isVideo: video,
              createdAt: DateTime.now(),
            );

            if (!mounted) return;

            setState(() {
              stories.insert(0, story);
            });

            await saveData();
          },
        ),
      ),
    );
  }

  Future<void> addPost(XFile file, String caption, bool video) async {
    try {
      final path = await copyMedia(file);

      final post = IranaPost(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        username: 'irana_user',
        caption: caption,
        imagePath: path,
        date: DateTime.now(),
        isVideo: video,
      );

      setState(() {
        posts.insert(0, post);
        selectedIndex = 0;
      });

      await saveData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پست با موفقیت منتشر شد 💜')),
        );
      }
    } catch (_) {
      showError('انتشار پست انجام نشد');
    }
  }

  void showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> toggleLike(String id) async {
    setState(() {
      posts = posts.map((post) {
        if (post.id == id) {
          return post.copyWith(liked: !post.liked);
        }
        return post;
      }).toList();
    });
    await saveData();
  }

  void openStory(IranaStory story) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryViewer(story: story)),
    );
  }

  void openVideo(IranaPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaVideoViewer(
          path: post.imagePath,
          title: post.username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: iranaPurple),
        ),
      );
    }

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
              icon: const Icon(Icons.favorite_border, color: Colors.black87),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.send_outlined, color: Colors.black87),
            ),
            const SizedBox(width: 5),
          ],
        ),
        body: IndexedStack(
          index: selectedIndex,
          children: [
            FeedPage(
              stories: stories,
              posts: posts,
              onAddStory: addStory,
              onOpenStory: openStory,
              onLike: toggleLike,
              onOpenVideo: openVideo,
            ),
            SearchPage(posts: posts),
            CreatePage(onPublish: addPost),
            VideosPage(
              stories: stories,
              posts: posts,
              onOpenStory: openStory,
              onOpenVideo: openVideo,
            ),
            ProfilePage(posts: posts),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.white,
          selectedIndex: selectedIndex,
          indicatorColor: iranaPurple.withOpacity(0.12),
          onDestinationSelected: (index) {
            setState(() => selectedIndex = index);
          },
          destinations: List.generate(
            pages.length,
            (index) => NavigationDestination(
              icon: Icon(icons[index]),
              selectedIcon: Icon(icons[index], color: iranaPurple),
              label: pages[index],
            ),
          ),
        ),
      ),
    );
  }
}

class FeedPage extends StatelessWidget {
  final List<IranaStory> stories;
  final List<IranaPost> posts;
  final VoidCallback onAddStory;
  final Function(IranaStory) onOpenStory;
  final Function(String) onLike;
  final Function(IranaPost) onOpenVideo;

  const FeedPage({
    super.key,
    required this.stories,
    required this.posts,
    required this.onAddStory,
    required this.onOpenStory,
    required this.onLike,
    required this.onOpenVideo,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'استوری‌ها',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 105,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              GestureDetector(
                onTap: onAddStory,
                child: const StoryItem(name: 'استوری من', own: true),
              ),
              ...stories.map(
                (story) => GestureDetector(
                  onTap: () => onOpenStory(story),
                  child: StoryItem(
                    name: story.username,
                    filePath: story.filePath,
                    isVideo: story.isVideo,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 20),
        if (posts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(35),
            child: Center(
              child: Text(
                'هنوز پستی منتشر نشده است.\nاولین پست ایرانا را منتشر کن 💜',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ...posts.map(
          (post) => PostCard(
            post: post,
            onLike: () => onLike(post.id),
            onOpenVideo: () => onOpenVideo(post),
          ),
        ),
      ],
    );
  }
}

class StoryItem extends StatelessWidget {
  final String name;
  final bool own;
  final String? filePath;
  final bool isVideo;

  const StoryItem({
    super.key,
    required this.name,
    this.own = false,
    this.filePath,
    this.isVideo = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = filePath != null && File(filePath!).existsSync();

    return Container(
      width: 76,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [iranaPink, iranaPurple],
              ),
            ),
            child: CircleAvatar(
              radius: 29,
              backgroundColor: Colors.white,
              backgroundImage:
                  hasFile && !isVideo ? FileImage(File(filePath!)) : null,
              child: own
                  ? const Icon(Icons.add, color: iranaPurple, size: 28)
                  : isVideo
                      ? const Icon(Icons.play_arrow,
                          color: iranaPurple, size: 32)
                      : hasFile
                          ? null
                          : const Icon(Icons.person,
                              color: Colors.grey, size: 32),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class StoryViewer extends StatefulWidget {
  final IranaStory story;
  const StoryViewer({super.key, required this.story});

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  VideoPlayerController? controller;
  Future<void>? initializeFuture;

  @override
  void initState() {
    super.initState();
    if (widget.story.isVideo) {
      controller = VideoPlayerController.file(File(widget.story.filePath));
      initializeFuture = controller!.initialize().then((_) {
        controller!.setLooping(true);
        controller!.play();
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.story.username),
      ),
      body: Center(
        child: widget.story.isVideo
            ? FutureBuilder<void>(
                future: initializeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const CircularProgressIndicator(
                      color: Colors.white,
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'پخش ویدئو امکان‌پذیر نیست',
                      style: TextStyle(color: Colors.white),
                    );
                  }
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: controller!.value.aspectRatio,
                        child: VideoPlayer(controller!),
                      ),
                      IconButton(
                        color: Colors.white,
                        iconSize: 40,
                        onPressed: () {
                          setState(() {
                            if (controller!.value.isPlaying) {
                              controller!.pause();
                            } else {
                              controller!.play();
                            }
                          });
                        },
                        icon: Icon(
                          controller!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                      ),
                    ],
                  );
                },
              )
            : Image.file(File(widget.story.filePath), fit: BoxFit.contain),
      ),
    );
  }
}

class MediaVideoViewer extends StatefulWidget {
  final String path;
  final String title;

  const MediaVideoViewer({
    super.key,
    required this.path,
    required this.title,
  });

  @override
  State<MediaVideoViewer> createState() => _MediaVideoViewerState();
}

class _MediaVideoViewerState extends State<MediaVideoViewer> {
  late final VideoPlayerController controller;
  late final Future<void> initializeFuture;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.file(File(widget.path));
    initializeFuture = controller.initialize().then((_) {
      controller.setLooping(true);
      controller.play();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: Center(
        child: FutureBuilder<void>(
          future: initializeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator(color: Colors.white);
            }
            if (snapshot.hasError) {
              return const Text(
                'پخش ویدئو امکان‌پذیر نیست',
                style: TextStyle(color: Colors.white),
              );
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
                IconButton(
                  color: Colors.white,
                  iconSize: 45,
                  onPressed: () {
                    setState(() {
                      if (controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                    });
                  },
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final IranaPost post;
  final VoidCallback onLike;
  final VoidCallback onOpenVideo;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onOpenVideo,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(post.imagePath);

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
              post.username,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            trailing: const Icon(Icons.more_vert),
          ),
          if (file.existsSync())
            post.isVideo
                ? GestureDetector(
                    onTap: onOpenVideo,
                    child: Container(
                      width: double.infinity,
                      height: 300,
                      color: Colors.black,
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 75,
                        ),
                      ),
                    ),
                  )
                : Image.file(
                    file,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    post.liked ? Icons.favorite : Icons.favorite_border,
                    color: post.liked ? Colors.red : Colors.black87,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(post.caption, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  final List<IranaPost> posts;
  const SearchPage({super.key, required this.posts});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final results = widget.posts.where((post) {
      return post.username.toLowerCase().contains(query.toLowerCase()) ||
          post.caption.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => query = value),
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
          const SizedBox(height: 15),
          Expanded(
            child: query.isEmpty
                ? const Center(child: Text('جهان ایرانا را کشف کن'))
                : results.isEmpty
                    ? const Center(child: Text('نتیجه‌ای پیدا نشد'))
                    : ListView(
                        children: results.map((post) {
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(post.username),
                            subtitle: Text(
                              post.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }
}

class CreatePage extends StatefulWidget {
  final Future<void> Function(XFile, String, bool) onPublish;
  const CreatePage({super.key, required this.onPublish});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final ImagePicker picker = ImagePicker();
  final TextEditingController captionController = TextEditingController();

  XFile? selectedMedia;
  bool selectedVideo = false;
  bool publishing = false;

  Future<void> chooseMedia() async {
    try {
      final file = await picker.pickMedia();
      if (file != null) {
        final isVideo = file.mimeType?.startsWith('video/') ??
            (file.name.toLowerCase().endsWith('.mp4') ||
                file.name.toLowerCase().endsWith('.mov'));

        setState(() {
          selectedMedia = file;
          selectedVideo = isVideo;
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتخاب فایل انجام نشد')),
      );
    }
  }

  Future<void> publish() async {
    if (selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا عکس یا ویدئو انتخاب کن')),
      );
      return;
    }

    setState(() => publishing = true);

    try {
      await widget.onPublish(
        selectedMedia!,
        captionController.text.trim(),
        selectedVideo,
      );

      captionController.clear();

      if (mounted) {
        setState(() {
          selectedMedia = null;
          selectedVideo = false;
        });
      }
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  @override
  void dispose() {
    captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'ساخت پست جدید',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: chooseMedia,
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: iranaPurple.withOpacity(0.3)),
            ),
            child: selectedMedia == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 75,
                        color: iranaPurple,
                      ),
                      SizedBox(height: 12),
                      Text('انتخاب عکس یا ویدئو از گالری'),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: selectedVideo
                        ? const ColoredBox(
                            color: Colors.black,
                            child: Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Image.file(
                            File(selectedMedia!.path),
                            fit: BoxFit.cover,
                          ),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: captionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'متن و کپشن پست خود را بنویس...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: publishing ? null : publish,
          icon: const Icon(Icons.publish),
          label: Text(publishing ? 'در حال انتشار...' : 'انتشار پست'),
          style: ElevatedButton.styleFrom(
            backgroundColor: iranaPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(15),
          ),
        ),
      ],
    );
  }
}

class VideosPage extends StatelessWidget {
  final List<IranaStory> stories;
  final List<IranaPost> posts;
  final Function(IranaStory) onOpenStory;
  final Function(IranaPost) onOpenVideo;

  const VideosPage({
    super.key,
    required this.stories,
    required this.posts,
    required this.onOpenStory,
    required this.onOpenVideo,
  });

  @override
  Widget build(BuildContext context) {
    final videos = posts.where((p) => p.isVideo).toList();
    final storyVideos = stories.where((s) => s.isVideo).toList();

    if (videos.isEmpty && storyVideos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 90, color: iranaPurple),
            SizedBox(height: 16),
            Text(
              'ویدئوهای ایرانا',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('هنوز ویدئویی منتشر نشده است'),
          ],
        ),
      );
    }

    return ListView(
      children: [
        ...videos.map(
          (video) => ListTile(
            leading: const Icon(
              Icons.play_circle_fill,
              color: iranaPurple,
              size: 40,
            ),
            title: Text(video.username),
            subtitle: Text(
              video.caption.isEmpty ? 'ویدئوی ایرانا' : video.caption,
            ),
            onTap: () => onOpenVideo(video),
          ),
        ),
        ...storyVideos.map(
          (video) => ListTile(
            leading: const Icon(
              Icons.video_library,
              color: iranaPink,
              size: 40,
            ),
            title: Text(video.username),
            subtitle: const Text('ویدئوی استوری'),
            onTap: () => onOpenStory(video),
          ),
        ),
      ],
    );
  }
}

// ---------------- PROFILE ----------------

class ProfilePage extends StatefulWidget {
  final List<IranaPost> posts;
  const ProfilePage({super.key, required this.posts});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker picker = ImagePicker();

  String profileName = 'کاربر ایرانا';
  String username = 'irana_user';
  String bio = 'به خانواده بزرگ ایرانا خوش آمدید 💜';
  String avatarPath = '';
  bool loadingProfile = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      profileName = prefs.getString('irana_profile_name') ?? 'کاربر ایرانا';
      username = prefs.getString('irana_profile_username') ?? 'irana_user';
      bio = prefs.getString('irana_profile_bio') ??
          'به خانواده بزرگ ایرانا خوش آمدید 💜';
      avatarPath = prefs.getString('irana_profile_avatar') ?? '';
      loadingProfile = false;
    });
  }

  Future<void> saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('irana_profile_name', profileName);
    await prefs.setString('irana_profile_username', username);
    await prefs.setString('irana_profile_bio', bio);
    await prefs.setString('irana_profile_avatar', avatarPath);
  }

  Future<void> editProfile() async {
    final nameController = TextEditingController(text: profileName);
    final usernameController = TextEditingController(text: username);
    final bioController = TextEditingController(text: bio);

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('ویرایش پروفایل'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'نام نمایشی',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'نام کاربری',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'بیوگرافی',
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('انصراف'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iranaPurple,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (nameController.text.trim().isEmpty ||
                        usernameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'نام و نام کاربری نمی‌توانند خالی باشند',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('ذخیره تغییرات'),
                ),
              ],
            ),
          );
        },
      );

      if (result == true && mounted) {
        setState(() {
          profileName = nameController.text.trim();
          username = usernameController.text.trim().replaceAll('@', '');
          bio = bioController.text.trim();
        });

        await saveProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('پروفایل با موفقیت ذخیره شد 💜')),
          );
        }
      }
    } finally {
      nameController.dispose();
      usernameController.dispose();
      bioController.dispose();
    }
  }

  Future<void> changeAvatar() async {
    try {
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final folder = Directory('${directory.path}/irana_media');

      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final extension =
          file.name.contains('.') ? file.name.split('.').last : 'jpg';
      final destination =
          '${folder.path}/profile_${DateTime.now().microsecondsSinceEpoch}.$extension';

      await File(file.path).copy(destination);
      if (!mounted) return;

      setState(() => avatarPath = destination);
      await saveProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عکس پروفایل تغییر کرد 💜')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تغییر عکس پروفایل انجام نشد')),
      );
    }
  }

  ImageProvider? get avatarImage {
    if (avatarPath.isNotEmpty && File(avatarPath).existsSync()) {
      return FileImage(File(avatarPath));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (loadingProfile) {
      return const Center(
        child: CircularProgressIndicator(color: iranaPurple),
      );
    }

    final image = avatarImage;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 145,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF7139A8),
                  Color(0xFF9B55C5),
                  Color(0xFFE84B91),
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IRANA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'پروفایل من',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'منوی تنظیمات',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IranaSettingsPage(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const Icon(
                      Icons.auto_awesome,
                      color: iranaGold,
                      size: 45,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -43),
            child: Column(
              children: [
                GestureDetector(
                  onTap: changeAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: iranaGold,
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: const Color(0xFFE9DDF7),
                      backgroundImage: image,
                      child: image == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: iranaPurple,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                TextButton.icon(
                  onPressed: changeAvatar,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('تغییر عکس پروفایل'),
                  style: TextButton.styleFrom(foregroundColor: iranaPurple),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profileName,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.verified, color: iranaPurple, size: 19),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '@$username',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ProfileStat(
                        number: widget.posts.length.toString(),
                        label: 'پست',
                      ),
                      const ProfileStat(number: '0', label: 'دنبال‌کننده'),
                      const ProfileStat(number: '0', label: 'دنبال‌شونده'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: editProfile,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('ویرایش پروفایل'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: iranaPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'اشتراک‌گذاری پروفایل در نسخه بعدی فعال می‌شود',
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: iranaPurple,
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                            horizontal: 14,
                          ),
                          side: const BorderSide(color: iranaPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.share_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    bio.isEmpty ? 'هنوز بیوگرافی ثبت نشده است' : bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'هایلایت‌ها',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    children: const [
                      _ProfileHighlight(
                        icon: Icons.add,
                        title: 'جدید',
                        isNew: true,
                      ),
                      _ProfileHighlight(
                        icon: Icons.photo_library_outlined,
                        title: 'لحظه‌ها',
                      ),
                      _ProfileHighlight(
                        icon: Icons.favorite_border,
                        title: 'علاقه‌ها',
                      ),
                      _ProfileHighlight(
                        icon: Icons.star_border,
                        title: 'منتخب',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  child: Row(
                    children: [
                      Icon(Icons.grid_on, color: iranaPurple),
                      SizedBox(width: 9),
                      Text(
                        'پست‌های من',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.posts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 35),
                    child: Column(
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 55,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text('هنوز پستی منتشر نکرده‌ای'),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(2),
                    itemCount: widget.posts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemBuilder: (context, index) {
                      final post = widget.posts[index];
                      final file = File(post.imagePath);

                      if (!file.existsSync()) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image),
                        );
                      }

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          post.isVideo
                              ? Container(
                                  color: Colors.black87,
                                  child: const Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                )
                              : Image.file(file, fit: BoxFit.cover),
                          if (post.isVideo)
                            const Positioned(
                              top: 5,
                              left: 5,
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHighlight extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isNew;

  const _ProfileHighlight({
    required this.icon,
    required this.title,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isNew ? const Color(0xFFEDE2F7) : Colors.white,
              border: Border.all(
                color: isNew ? iranaPurple : iranaGold,
                width: 2,
              ),
            ),
            child: Icon(icon, color: iranaPurple, size: 27),
          ),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }
}

// ---------------- IRANA SETTINGS MENU ----------------

class IranaMenuItem {
  final String title;
  final IconData icon;
  final String description;

  const IranaMenuItem({
    required this.title,
    required this.icon,
    required this.description,
  });
}

class IranaSettingsPage extends StatelessWidget {
  const IranaSettingsPage({super.key});

  static const List<IranaMenuItem> menuItems = [
    IranaMenuItem(
      title: 'پست کردن هم‌زمان',
      icon: Icons.dashboard_customize_outlined,
      description: 'مدیریت انتشار هم‌زمان محتوا در بخش‌های مختلف ایرانا',
    ),
    IranaMenuItem(
      title: 'مسدودشده‌ها',
      icon: Icons.block,
      description: 'فهرست حساب‌هایی که مسدود کرده‌اید',
    ),
    IranaMenuItem(
      title: 'پنهان کردن داستان و پخش زنده',
      icon: Icons.notifications_off_outlined,
      description: 'مدیریت افرادی که نمی‌خواهید داستان یا پخش زنده‌شان را ببینید',
    ),
    IranaMenuItem(
      title: 'فعالیت در فهرست دوستان',
      icon: Icons.people_outline,
      description: 'تنظیم نمایش فعالیت شما برای دوستان',
    ),
    IranaMenuItem(
      title: 'پیام‌ها و پاسخ‌ها به داستان',
      icon: Icons.send_outlined,
      description: 'تنظیم پیام‌ها و پاسخ‌های دریافتی',
    ),
    IranaMenuItem(
      title: 'نشان‌ها و ذکر نام‌ها',
      icon: Icons.alternate_email,
      description: 'مدیریت اشاره‌ها و برچسب‌گذاری حساب شما',
    ),
    IranaMenuItem(
      title: 'نظرات',
      icon: Icons.chat_bubble_outline,
      description: 'مدیریت نظرات و پاسخ‌ها',
    ),
    IranaMenuItem(
      title: 'اشتراک‌گذاری',
      icon: Icons.repeat,
      description: 'تنظیم نحوه اشتراک‌گذاری محتوا',
    ),
    IranaMenuItem(
      title: 'محدودشده‌ها',
      icon: Icons.person_off_outlined,
      description: 'مدیریت حساب‌های محدودشده',
    ),
    IranaMenuItem(
      title: 'محدود کردن تعاملات',
      icon: Icons.report_gmailerrorred_outlined,
      description: 'کنترل تعاملات و ارتباطات ناخواسته',
    ),
    IranaMenuItem(
      title: 'کلمات پنهان‌شده',
      icon: Icons.text_fields,
      description: 'مدیریت کلمات و عبارت‌های پنهان‌شده',
    ),
    IranaMenuItem(
      title: 'دنبال کردن و دعوت از دوستان',
      icon: Icons.person_add_alt_1,
      description: 'دعوت دوستان برای پیوستن به ایرانا',
    ),
    IranaMenuItem(
      title: 'موارد دلخواه',
      icon: Icons.star_border,
      description: 'دسترسی به محتواهای مورد علاقه شما',
    ),
    IranaMenuItem(
      title: 'حساب‌های بی‌صداشده',
      icon: Icons.volume_off_outlined,
      description: 'مدیریت حساب‌هایی که بی‌صدا کرده‌اید',
    ),
    IranaMenuItem(
      title: 'اولویت‌های محتوا',
      icon: Icons.tune,
      description: 'تنظیم محتواهایی که بیشتر به شما نمایش داده می‌شوند',
    ),
    IranaMenuItem(
      title: 'تعداد پسندیدن‌ها و اشتراک‌گذاری‌ها',
      icon: Icons.favorite_border,
      description: 'تنظیم نمایش آمار پسندیدن و اشتراک‌گذاری',
    ),
    IranaMenuItem(
      title: 'حساب Meta',
      icon: Icons.all_inclusive,
      description: 'تنظیمات حساب و خدمات مرتبط با Meta در آینده',
    ),
    IranaMenuItem(
      title: 'ذخیره‌شده',
      icon: Icons.bookmark_border,
      description: 'محتواهایی که ذخیره کرده‌اید',
    ),
    IranaMenuItem(
      title: 'بایگانی',
      icon: Icons.history,
      description: 'مشاهده محتواهای بایگانی‌شده',
    ),
    IranaMenuItem(
      title: 'فعالیت شما',
      icon: Icons.monitor_heart_outlined,
      description: 'بررسی فعالیت‌های انجام‌شده در ایرانا',
    ),
    IranaMenuItem(
      title: 'اعلان‌ها',
      icon: Icons.notifications_none,
      description: 'مدیریت اعلان‌ها و هشدارهای ایرانا',
    ),
    IranaMenuItem(
      title: 'مدیریت زمان',
      icon: Icons.access_time,
      description: 'مدیریت مدت‌زمان استفاده از ایرانا',
    ),
    IranaMenuItem(
      title: 'Instagram ویژه رایانه لوحی',
      icon: Icons.tablet_android_outlined,
      description: 'اطلاعات مربوط به نمایش در دستگاه‌های مختلف',
    ),
    IranaMenuItem(
      title: 'Meta Verified',
      icon: Icons.verified_outlined,
      description: 'اطلاعات مربوط به تأیید حساب',
    ),
    IranaMenuItem(
      title: 'حریم خصوصی حساب',
      icon: Icons.lock_outline,
      description: 'مدیریت خصوصی یا عمومی بودن حساب',
    ),
    IranaMenuItem(
      title: 'دوستان صمیمی',
      icon: Icons.stars_outlined,
      description: 'مدیریت فهرست دوستان صمیمی',
    ),
    IranaMenuItem(
      title: 'مجوزهای دستگاه',
      icon: Icons.phone_android,
      description: 'دسترسی‌های برنامه به امکانات دستگاه',
    ),
    IranaMenuItem(
      title: 'بایگانی کردن و دانلود کردن',
      icon: Icons.download_outlined,
      description: 'مدیریت بایگانی و دریافت اطلاعات',
    ),
    IranaMenuItem(
      title: 'دسترس‌پذیری',
      icon: Icons.accessibility_new,
      description: 'تنظیم امکانات دسترس‌پذیری',
    ),
    IranaMenuItem(
      title: 'زبان و ترجمه‌ها',
      icon: Icons.translate,
      description: 'تنظیم زبان برنامه و ترجمه محتوا',
    ),
    IranaMenuItem(
      title: 'مصرف داده و کیفیت رسانه',
      icon: Icons.signal_cellular_alt,
      description: 'تنظیم مصرف اینترنت و کیفیت عکس و ویدئو',
    ),
    IranaMenuItem(
      title: 'مجوزهای وب‌سایت',
      icon: Icons.devices,
      description: 'مدیریت دسترسی‌های وب‌سایت',
    ),
    IranaMenuItem(
      title: 'نظرات در «حساب‌های نه‌چندان...»',
      icon: Icons.home_outlined,
      description: 'تنظیمات مربوط به تعاملات و نمایش محتوا',
    ),
  ];

  void openItem(BuildContext context, IranaMenuItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IranaSettingDetailPage(item: item),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget menuTile(BuildContext context, IranaMenuItem item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
      leading: Icon(item.icon, color: Colors.black87, size: 26),
      title: Text(
        item.title,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
      trailing: const Icon(Icons.chevron_left, color: Colors.grey),
      onTap: () => openItem(context, item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          title: const Text(
            'تنظیمات و فعالیت',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        body: ListView(
          children: [
            sectionTitle('نحوه تعامل شما با دیگران'),
            ...menuItems.take(12).map((item) => menuTile(context, item)),
            const Divider(thickness: 7, color: Color(0xFFF1F1F5)),
            sectionTitle('آنچه می‌بینید'),
            ...menuItems.skip(12).take(5).map((item) => menuTile(context, item)),
            const Divider(thickness: 7, color: Color(0xFFF1F1F5)),
            sectionTitle('حساب و تنظیمات'),
            ...menuItems.skip(17).take(7).map((item) => menuTile(context, item)),
            const Divider(thickness: 7, color: Color(0xFFF1F1F5)),
            sectionTitle('برنامه و رسانه‌های شما'),
            ...menuItems.skip(24).map((item) => menuTile(context, item)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ---------------- INDIVIDUAL SETTINGS PAGES ----------------

class IranaSettingDetailPage extends StatefulWidget {
  final IranaMenuItem item;

  const IranaSettingDetailPage({super.key, required this.item});

  @override
  State<IranaSettingDetailPage> createState() =>
      _IranaSettingDetailPageState();
}

class _IranaSettingDetailPageState extends State<IranaSettingDetailPage> {
  bool mainSwitch = true;
  bool secondSwitch = false;
  String selectedOption = 'پیش‌فرض';
  final TextEditingController textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget settingSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      activeColor: iranaPurple,
      title: Text(title),
      onChanged: onChanged,
    );
  }

  Widget optionTile(String title, String value) {
    return RadioListTile<String>(
      value: value,
      groupValue: selectedOption,
      activeColor: iranaPurple,
      title: Text(title),
      onChanged: (newValue) {
        if (newValue == null) return;
        setState(() => selectedOption = newValue);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.item.title;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: const Color(0xFFEDE2F7),
                    child: Icon(
                      widget.item.icon,
                      size: 34,
                      color: iranaPurple,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.item.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, height: 1.8),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 7, color: Color(0xFFF1F1F5)),
            if (title == 'حریم خصوصی حساب') ...[
              settingSwitch(
                title: 'حساب خصوصی',
                value: mainSwitch,
                onChanged: (value) => setState(() => mainSwitch = value),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'با فعال‌کردن این گزینه، در نسخه فعلی فقط وضعیت نمایشی حریم خصوصی تغییر می‌کند. اتصال و اعمال این تنظیم برای کاربران دیگر به زیرساخت حساب کاربری و سرور نیاز دارد.',
                  style: TextStyle(color: Colors.grey, height: 1.7),
                ),
              ),
            ] else if (title == 'اعلان‌ها') ...[
              settingSwitch(
                title: 'فعال‌بودن اعلان‌ها',
                value: mainSwitch,
                onChanged: (value) => setState(() => mainSwitch = value),
              ),
              settingSwitch(
                title: 'اعلان پیام‌ها',
                value: secondSwitch,
                onChanged: (value) => setState(() => secondSwitch = value),
              ),
            ] else if (title == 'زبان و ترجمه‌ها') ...[
              optionTile('فارسی', 'فارسی'),
              optionTile('English', 'English'),
              optionTile('العربية', 'العربية'),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    showMessage(
                      'زبان انتخابی در این نسخه نمایشی ذخیره نشده است',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iranaPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ثبت انتخاب'),
                ),
              ),
            ] else if (title == 'مصرف داده و کیفیت رسانه') ...[
              optionTile('کیفیت خودکار', 'پیش‌فرض'),
              optionTile('کیفیت بالا', 'کیفیت بالا'),
              optionTile('صرفه‌جویی در مصرف داده', 'صرفه‌جویی'),
            ] else if (title == 'مدیریت زمان') ...[
              settingSwitch(
                title: 'یادآوری زمان استفاده',
                value: mainSwitch,
                onChanged: (value) => setState(() => mainSwitch = value),
              ),
              const ListTile(
                title: Text('مدت‌زمان روزانه'),
                subtitle: Text('بعداً امکان تعیین محدودیت زمانی اضافه می‌شود'),
              ),
            ] else if (title == 'کلمات پنهان‌شده') ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'افزودن کلمه یا عبارت',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    if (textController.text.trim().isEmpty) {
                      showMessage('ابتدا یک کلمه وارد کن');
                    } else {
                      showMessage(
                        'ثبت کلمه در نسخه بعدی به فهرست ذخیره‌شده متصل می‌شود',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iranaPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('افزودن کلمه'),
                ),
              ),
            ] else if (title == 'نظرات') ...[
              settingSwitch(
                title: 'اجازه دریافت نظر',
                value: mainSwitch,
                onChanged: (value) => setState(() => mainSwitch = value),
              ),
              settingSwitch(
                title: 'فیلتر نظرات نامناسب',
                value: secondSwitch,
                onChanged: (value) => setState(() => secondSwitch = value),
              ),
            ] else if (title == 'دوستان صمیمی') ...[
              const ListTile(
                leading: Icon(Icons.people_outline),
                title: Text('فهرست دوستان صمیمی'),
                subtitle: Text(
                  'برای افزودن دوستان، ابتدا قابلیت دنبال‌کردن و حساب‌های کاربری باید به سرور متصل شوند.',
                ),
              ),
            ] else if (title == 'مجوزهای دستگاه') ...[
              const ListTile(
                leading: Icon(Icons.photo_outlined),
                title: Text('دسترسی به عکس‌ها و ویدئوها'),
                subtitle: Text('برای انتخاب رسانه از گالری استفاده می‌شود'),
              ),
              const ListTile(
                leading: Icon(Icons.camera_alt_outlined),
                title: Text('دوربین'),
                subtitle: Text('در صورت نیاز به قابلیت عکس‌برداری'),
              ),
            ] else if (title == 'ذخیره‌شده') ...[
              const ListTile(
                leading: Icon(Icons.bookmark_border),
                title: Text('محتوای ذخیره‌شده'),
                subtitle: Text(
                  'بخش ذخیره پست‌ها در نسخه بعدی به فهرست ذخیره‌شده متصل می‌شود.',
                ),
              ),
            ] else if (title == 'بایگانی') ...[
              const ListTile(
                leading: Icon(Icons.archive_outlined),
                title: Text('بایگانی محتوا'),
                subtitle: Text(
                  'در این نسخه هنوز محتوایی به بایگانی منتقل نمی‌شود.',
                ),
              ),
            ] else if (title == 'فعالیت شما') ...[
              const ListTile(
                leading: Icon(Icons.favorite_border),
                title: Text('فعالیت‌ها'),
                subtitle: Text(
                  'سوابق پسندیدن، نظرها و تعاملات در نسخه بعدی نمایش داده می‌شود.',
                ),
              ),
            ] else if (title == 'موارد دلخواه') ...[
              const ListTile(
                leading: Icon(Icons.star_border),
                title: Text('فهرست موارد دلخواه'),
                subtitle: Text(
                  'با اضافه‌شدن قابلیت دنبال‌کردن و ذخیره‌سازی، این بخش کامل می‌شود.',
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.construction_outlined,
                      size: 48,
                      color: iranaPurple,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'صفحه اختصاصی این بخش ایجاد شد',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'عملکرد کامل این گزینه در مرحله بعد به ایرانا اضافه می‌شود. تنظیمات فعلی برنامه و اطلاعات شما دست‌نخورده باقی می‌مانند.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, height: 1.8),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------- STORY CREATION PAGE ----------------

class StoryCreatePage extends StatefulWidget {
  final Future<void> Function(XFile file, bool isVideo) onPublish;

  const StoryCreatePage({
    super.key,
    required this.onPublish,
  });

  @override
  State<StoryCreatePage> createState() => _StoryCreatePageState();
}

class _StoryCreatePageState extends State<StoryCreatePage> {
  final ImagePicker picker = ImagePicker();

  XFile? selectedFile;
  bool selectedVideo = false;
  bool publishing = false;

  bool isVideoFile(XFile file) {
    final mime = file.mimeType ?? '';
    final name = file.name.toLowerCase();

    return mime.startsWith('video/') ||
        name.endsWith('.mp4') ||
        name.endsWith('.mov') ||
        name.endsWith('.m4v');
  }

  Future<void> chooseGallery() async {
    try {
      final file = await picker.pickMedia();
      if (file == null || !mounted) return;

      setState(() {
        selectedFile = file;
        selectedVideo = isVideoFile(file);
      });
    } catch (_) {
      showMessage('بازکردن گالری انجام نشد');
    }
  }

  Future<void> takePhoto() async {
    try {
      final file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (file == null || !mounted) return;

      setState(() {
        selectedFile = file;
        selectedVideo = false;
      });
    } catch (_) {
      showMessage('بازکردن دوربین انجام نشد');
    }
  }

  Future<void> recordVideo() async {
    try {
      final file = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 60),
      );

      if (file == null || !mounted) return;

      setState(() {
        selectedFile = file;
        selectedVideo = true;
      });
    } catch (_) {
      showMessage('ضبط ویدئو انجام نشد');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void showComingSoon(String feature) {
    showMessage('$feature در مرحله بعد فعال می‌شود 💜');
  }

  Future<void> publishStory() async {
    if (selectedFile == null) {
      showMessage('ابتدا عکس یا ویدئو انتخاب کن');
      return;
    }

    setState(() => publishing = true);

    try {
      await widget.onPublish(selectedFile!, selectedVideo);

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('استوری منتشر شد 💜')),
      );
    } catch (_) {
      if (mounted) showMessage('انتشار استوری انجام نشد');
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  Widget actionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: (color ?? iranaPurple).withOpacity(0.10),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                icon,
                color: color ?? iranaPurple,
                size: 27,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF17131D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF17131D),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'افزودن به داستان',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              tooltip: 'تنظیمات استوری',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StorySettingsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: selectedFile == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 145,
                              height: 145,
                              decoration: BoxDecoration(
                                color: iranaPurple.withOpacity(0.22),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Colors.white,
                                size: 75,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'داستان جدید خود را بساز',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'یک عکس یا ویدئو انتخاب کن',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: selectedVideo
                              ? Container(
                                  width: double.infinity,
                                  color: Colors.black,
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.white,
                                        size: 90,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'ویدئوی انتخاب‌شده',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                )
                              : Image.file(
                                  File(selectedFile!.path),
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                decoration: const BoxDecoration(
                  color: Color(0xFF24202B),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: Column(
                  children: [
                    if (selectedFile == null) ...[
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'ساخت داستان',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        actionItem(
                          icon: Icons.camera_alt_outlined,
                          title: 'دوربین',
                          onTap: takePhoto,
                        ),
                        actionItem(
                          icon: Icons.photo_library_outlined,
                          title: 'گالری',
                          onTap: chooseGallery,
                        ),
                        actionItem(
                          icon: Icons.music_note,
                          title: 'موسیقی',
                          onTap: () => showComingSoon('موسیقی'),
                          color: iranaPink,
                        ),
                        actionItem(
                          icon: Icons.grid_view_rounded,
                          title: 'کلاژ',
                          onTap: () => showComingSoon('کلاژ'),
                        ),
                        actionItem(
                          icon: Icons.dashboard_outlined,
                          title: 'قالب‌ها',
                          onTap: () => showComingSoon('قالب‌ها'),
                          color: iranaGold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (selectedFile == null)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: recordVideo,
                          icon: const Icon(Icons.videocam_outlined),
                          label: const Text('ضبط ویدئو با دوربین'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.all(13),
                          ),
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  selectedFile = null;
                                  selectedVideo = false;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                padding: const EdgeInsets.all(14),
                              ),
                              child: const Text('انتخاب مجدد'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: publishing ? null : publishStory,
                              icon: const Icon(Icons.send),
                              label: Text(
                                publishing ? 'در حال انتشار...' : 'انتشار استوری',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: iranaPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- STORY SETTINGS ----------------

class StorySettingsPage extends StatefulWidget {
  const StorySettingsPage({super.key});

  @override
  State<StorySettingsPage> createState() => _StorySettingsPageState();
}

class _StorySettingsPageState extends State<StorySettingsPage> {
  bool hideFromSelected = false;
  bool allowReplies = true;
  bool allowSharing = true;
  bool saveToGallery = false;

  Widget settingSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: iranaPurple,
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: const Text(
            'تنظیمات داستان',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 20, 18, 10),
              child: Text(
                'حریم خصوصی داستان',
                style: TextStyle(
                  color: iranaPurple,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            settingSwitch(
              title: 'مخفی کردن داستان از افراد انتخاب‌شده',
              subtitle: 'انتخاب افراد در نسخه بعدی اضافه می‌شود',
              value: hideFromSelected,
              onChanged: (value) {
                setState(() => hideFromSelected = value);
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 15, 18, 10),
              child: Text(
                'پاسخ‌ها و اشتراک‌گذاری',
                style: TextStyle(
                  color: iranaPurple,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            settingSwitch(
              title: 'اجازه پاسخ به داستان',
              subtitle: 'تنظیم نمایشی در نسخه فعلی',
              value: allowReplies,
              onChanged: (value) {
                setState(() => allowReplies = value);
              },
            ),
            settingSwitch(
              title: 'اجازه اشتراک‌گذاری داستان',
              subtitle: 'تنظیم نمایشی در نسخه فعلی',
              value: allowSharing,
              onChanged: (value) {
                setState(() => allowSharing = value);
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 15, 18, 10),
              child: Text(
                'ذخیره‌سازی',
                style: TextStyle(
                  color: iranaPurple,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            settingSwitch(
              title: 'ذخیره داستان در گالری',
              subtitle: 'ذخیره خودکار در گالری در مرحله بعد فعال می‌شود',
              value: saveToGallery,
              onChanged: (value) {
                setState(() => saveToGallery = value);
              },
            ),
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'این صفحه فعلاً ساختار اولیه تنظیمات استوری را دارد. گزینه‌های کامل‌تر را بعداً مطابق طرحی که می‌خواهی اضافه می‌کنیم.',
                style: TextStyle(color: Colors.grey, height: 1.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}