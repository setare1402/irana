
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

  bool get expired =>
      DateTime.now().difference(createdAt).inHours >= 24;

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
            .where((s) =>
                !s.expired && File(s.filePath).existsSync())
            .toList();
      }
    } catch (_) {
      posts = [];
      stories = [];
    }

    await saveData();

    if (mounted) {
      setState(() {
        loading = false;
      });
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

    final extension = file.name.contains('.')
        ? file.name.split('.').last
        : 'jpg';

    final destination =
        '${folder.path}/${DateTime.now().microsecondsSinceEpoch}.$extension';

    await File(file.path).copy(destination);
    return destination;
  }

  bool isVideoFile(XFile file) {
    final mime = file.mimeType ?? '';

    return mime.startsWith('video/') ||
        file.name.toLowerCase().endsWith('.mp4') ||
        file.name.toLowerCase().endsWith('.mov') ||
        file.name.toLowerCase().endsWith('.m4v');
  }

  Future<void> addStory() async {
    try {
      final file = await picker.pickMedia();

      if (file == null) return;

      final path = await copyMedia(file);

      final story = IranaStory(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        username: 'irana_user',
        filePath: path,
        isVideo: isVideoFile(file),
        createdAt: DateTime.now(),
      );

      setState(() {
        stories.insert(0, story);
      });

      await saveData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('استوری منتشر شد 💜')),
        );
      }
    } catch (_) {
      showError('انتشار استوری انجام نشد');
    }
  }

  Future<void> addPost(
    XFile file,
    String caption,
    bool video,
  ) async {
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
      MaterialPageRoute(
        builder: (_) => StoryViewer(story: story),
      ),
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
            children: [
              GestureDetector(
                onTap: onAddStory,
                child: const StoryItem(
                  name: 'استوری من',
                  own: true,
                ),
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
              backgroundImage: hasFile && !isVideo
                  ? FileImage(File(filePath!))
                  : null,
              child: own
                  ? const Icon(
                      Icons.add,
                      color: iranaPurple,
                      size: 28,
                    )
                  : isVideo
                      ? const Icon(
                          Icons.play_arrow,
                          color: iranaPurple,
                          size: 32,
                        )
                      : hasFile
                          ? null
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
      controller = VideoPlayerController.file(
        File(widget.story.filePath),
      );

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
            : Image.file(
                File(widget.story.filePath),
                fit: BoxFit.contain,
              ),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    post.liked
                        ? Icons.favorite
                        : Icons.favorite_border,
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            child: Text(
              post.caption,
              style: const TextStyle(fontSize: 14),
            ),
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
            onChanged: (value) {
              setState(() {
                query = value;
              });
            },
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
                ? const Center(
                    child: Text('جهان ایرانا را کشف کن'),
                  )
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

  final TextEditingController captionController =
      TextEditingController();

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

    setState(() {
      publishing = true;
    });

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
      if (mounted) {
        setState(() {
          publishing = false;
        });
      }
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
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
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
          label: Text(
            publishing ? 'در حال انتشار...' : 'انتشار پست',
          ),
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
            Text('هنوز ویدئویی منتشر نشده است'),
          ],
        ),
      );
    }

    return ListView(
      children: [
        ...videos.map((video) {
          return ListTile(
            leading: const Icon(
              Icons.play_circle_fill,
              color: iranaPurple,
              size: 40,
            ),
            title: Text(video.username),
            subtitle: Text(video.caption.isEmpty
                ? 'ویدئوی ایرانا'
                : video.caption),
            onTap: () => onOpenVideo(video),
          );
        }),
        ...storyVideos.map((video) {
          return ListTile(
            leading: const Icon(
              Icons.video_library,
              color: iranaPink,
              size: 40,
            ),
            title: Text(video.username),
            subtitle: const Text('ویدئوی استوری'),
            onTap: () => onOpenStory(video),
          );
        }),
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
      profileName =
          prefs.getString('irana_profile_name') ?? 'کاربر ایرانا';
      username =
          prefs.getString('irana_profile_username') ?? 'irana_user';
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
    final nameController =
        TextEditingController(text: profileName);
    final usernameController =
        TextEditingController(text: username);
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
                  onPressed: () =>
                      Navigator.pop(dialogContext, false),
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
          username = usernameController.text
              .trim()
              .replaceAll('@', '');
          bio = bioController.text.trim();
        });

        await saveProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('پروفایل با موفقیت ذخیره شد 💜'),
            ),
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

      final extension = file.name.contains('.')
          ? file.name.split('.').last
          : 'jpg';

      final destination =
          '${folder.path}/profile_${DateTime.now().microsecondsSinceEpoch}.$extension';

      await File(file.path).copy(destination);

      if (!mounted) return;

      setState(() {
        avatarPath = destination;
      });

      await saveProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('عکس پروفایل تغییر کرد 💜'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تغییر عکس پروفایل انجام نشد'),
        ),
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
          // هدر پروفایل
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.auto_awesome,
                  color: iranaGold,
                  size: 55,
                ),
              ],
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -43),
            child: Column(
              children: [
                // عکس پروفایل
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
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    size: 18,
                  ),
                  label: const Text('تغییر عکس پروفایل'),
                  style: TextButton.styleFrom(
                    foregroundColor: iranaPurple,
                  ),
                ),
                const SizedBox(height: 4),

                // نام و نام کاربری
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
                    const Icon(
                      Icons.verified,
                      color: iranaPurple,
                      size: 19,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '@$username',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),

                // آمار
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ProfileStat(
                        number: widget.posts.length.toString(),
                        label: 'پست',
                      ),
                      const ProfileStat(
                        number: '0',
                        label: 'دنبال‌کننده',
                      ),
                      const ProfileStat(
                        number: '0',
                        label: 'دنبال‌شونده',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // دکمه‌های پروفایل
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
                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
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

                // بیوگرافی
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

                // هایلایت استوری‌ها
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

                // عنوان بخش پست‌ها
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.grid_on,
                        color: iranaPurple,
                      ),
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
                              : Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                ),
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
              color: isNew
                  ? const Color(0xFFEDE2F7)
                  : Colors.white,
              border: Border.all(
                color: isNew ? iranaPurple : iranaGold,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: iranaPurple,
              size: 27,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
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
