import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'notifications_page.dart';

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

// ---------------- MODELS ----------------

class IranaPost {
  final String id;
  final String username;
  final String caption;
  final String imagePath;
  final DateTime date;
  final bool liked;
  final bool isVideo;
  final bool commentsEnabled;

  IranaPost({
    required this.id,
    required this.username,
    required this.caption,
    required this.imagePath,
    required this.date,
    this.liked = false,
    this.isVideo = false,
    this.commentsEnabled = true,
  });

  IranaPost copyWith({
    bool? liked,
    String? caption,
    bool? commentsEnabled,
  }) =>
      IranaPost(
        id: id,
        username: username,
        caption: caption ?? this.caption,
        imagePath: imagePath,
        date: date,
        liked: liked ?? this.liked,
        isVideo: isVideo,
        commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'caption': caption,
        'imagePath': imagePath,
        'date': date.toIso8601String(),
        'liked': liked,
        'isVideo': isVideo,
        'commentsEnabled': commentsEnabled,
      };

  factory IranaPost.fromJson(Map<String, dynamic> j) => IranaPost(
        id: j['id'],
        username: j['username'],
        caption: j['caption'] ?? '',
        imagePath: j['imagePath'],
        date: DateTime.parse(j['date']),
        liked: j['liked'] ?? false,
        isVideo: j['isVideo'] ?? false,
        commentsEnabled: j['commentsEnabled'] ?? true,
      );
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

  factory IranaStory.fromJson(Map<String, dynamic> j) => IranaStory(
        id: j['id'],
        username: j['username'],
        filePath: j['filePath'],
        isVideo: j['isVideo'] ?? false,
        createdAt: DateTime.parse(j['createdAt']),
      );
}

class IranaComment {
  final String id;
  final String postId;
  final String username;
  final String text;
  final DateTime date;
  final String? parentId;

  IranaComment({
    required this.id,
    required this.postId,
    required this.username,
    required this.text,
    required this.date,
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'username': username,
        'text': text,
        'date': date.toIso8601String(),
        'parentId': parentId,
      };

  factory IranaComment.fromJson(Map<String, dynamic> j) => IranaComment(
        id: j['id'],
        postId: j['postId'],
        username: j['username'],
        text: j['text'],
        date: DateTime.parse(j['date']),
        parentId: j['parentId'],
      );
}

class IranaForward {
  final String id;
  final String postId;
  final String receiver;
  final DateTime date;

  IranaForward({
    required this.id,
    required this.postId,
    required this.receiver,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'receiver': receiver,
        'date': date.toIso8601String(),
      };

  factory IranaForward.fromJson(Map<String, dynamic> j) => IranaForward(
        id: j['id'],
        postId: j['postId'],
        receiver: j['receiver'],
        date: DateTime.parse(j['date']),
      );
}

// ---------------- HOME / DATA ----------------

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
  List<IranaStory> highlightedStories = [];
  List<IranaComment> comments = [];
  List<IranaForward> forwards = [];
  List<String> savedPostIds = [];
  List<String> reportedPostIds = [];
  List<String> hiddenPostIds = [];

  final ImagePicker picker = ImagePicker();

  final List<String> pages = [
    'خانه',
    'جستجو',
    'انتشار',
    'ویدئوها',
    'پروفایل',
    'دایرکت',
  ];

  final List<IconData> icons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.add_box_outlined,
    Icons.video_library_outlined,
    Icons.person_outline_rounded,
    Icons.send_outlined,
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<Directory> get mediaDirectory async {
    final d = await getApplicationDocumentsDirectory();
    final folder = Directory('${d.path}/irana_media');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final p = prefs.getString('irana_posts');
      final s = prefs.getString('irana_stories');
      final h = prefs.getString('irana_highlights');
      final c = prefs.getString('irana_comments');
      final f = prefs.getString('irana_forwards');

      if (p != null) {
        posts = (jsonDecode(p) as List)
            .map((e) => IranaPost.fromJson(e))
            .where((e) => File(e.imagePath).existsSync())
            .toList();
      }

      if (s != null) {
        stories = (jsonDecode(s) as List)
            .map((e) => IranaStory.fromJson(e))
            .where((e) => !e.expired && File(e.filePath).existsSync())
            .toList();
      }

      if (h != null) {
        highlightedStories = (jsonDecode(h) as List)
            .map((e) => IranaStory.fromJson(e))
            .where((e) => File(e.filePath).existsSync())
            .toList();
      }

      if (c != null) {
        comments = (jsonDecode(c) as List)
            .map((e) => IranaComment.fromJson(e))
            .toList();
      }

      if (f != null) {
        forwards = (jsonDecode(f) as List)
            .map((e) => IranaForward.fromJson(e))
            .toList();
      }

      savedPostIds = prefs.getStringList('irana_saved_posts') ?? [];
      reportedPostIds =
          prefs.getStringList('irana_reported_posts') ?? [];
      hiddenPostIds = prefs.getStringList('irana_hidden_posts') ?? [];
    } catch (_) {}

    await saveData();
    if (mounted) setState(() => loading = false);
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
    await prefs.setString(
      'irana_highlights',
      jsonEncode(highlightedStories.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'irana_comments',
      jsonEncode(comments.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'irana_forwards',
      jsonEncode(forwards.map((e) => e.toJson()).toList()),
    );

    await prefs.setStringList('irana_saved_posts', savedPostIds);
    await prefs.setStringList('irana_reported_posts', reportedPostIds);
    await prefs.setStringList('irana_hidden_posts', hiddenPostIds);
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

  Future<void> addStory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryCreatePage(
          onPublish: (file, video) async {
            final path = await copyMedia(file);
            setState(() {
              stories.insert(
                0,
                IranaStory(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  username: 'irana_user',
                  filePath: path,
                  isVideo: video,
                  createdAt: DateTime.now(),
                ),
              );
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
      showMessage('انتشار پست انجام نشد');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> toggleLike(String id) async {
    setState(() {
      posts = posts.map((p) {
        return p.id == id ? p.copyWith(liked: !p.liked) : p;
      }).toList();
    });
    await saveData();
  }

  Future<void> toggleSave(String id) async {
    setState(() {
      if (savedPostIds.contains(id)) {
        savedPostIds.remove(id);
      } else {
        savedPostIds.add(id);
      }
    });
    await saveData();
    showMessage(
      savedPostIds.contains(id)
          ? 'پست ذخیره شد'
          : 'پست از ذخیره‌شده‌ها حذف شد',
    );
  }

  // ---------------- POST MENU ACTIONS ----------------

  Future<void> editPost(IranaPost post) async {
    final controller = TextEditingController(text: post.caption);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('ویرایش پست'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'متن پست را ویرایش کن',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (result == null) return;

    setState(() {
      posts = posts
          .map((p) => p.id == post.id ? p.copyWith(caption: result) : p)
          .toList();
    });

    await saveData();
    showMessage('پست ویرایش شد');
  }

  Future<void> deletePost(IranaPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف پست'),
          content: const Text('آیا مطمئنی می‌خواهی این پست حذف شود؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('بله، حذف شود'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() {
      posts.removeWhere((p) => p.id == post.id);
      comments.removeWhere((c) => c.postId == post.id);
      forwards.removeWhere((f) => f.postId == post.id);
      savedPostIds.remove(post.id);
      hiddenPostIds.remove(post.id);
      reportedPostIds.remove(post.id);
    });

    await saveData();
    showMessage('پست حذف شد');
  }

  Future<void> toggleComments(IranaPost post) async {
    setState(() {
      posts = posts
          .map((p) => p.id == post.id
              ? p.copyWith(commentsEnabled: !p.commentsEnabled)
              : p)
          .toList();
    });

    await saveData();

    final updated = posts.firstWhere((p) => p.id == post.id);
    showMessage(
      updated.commentsEnabled ? 'نظرات باز شدند' : 'نظرات بسته شدند',
    );
  }

  Future<void> manageComments(IranaPost post) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, refresh) {
            final postComments =
                comments.where((c) => c.postId == post.id).toList();

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'مدیریت نظرات',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: postComments.isEmpty
                        ? const Center(child: Text('نظری ثبت نشده است'))
                        : ListView.builder(
                            itemCount: postComments.length,
                            itemBuilder: (context, index) {
                              final comment = postComments[index];

                              return ListTile(
                                title: Text(comment.username),
                                subtitle: Text(comment.text),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    setState(() {
                                      comments.removeWhere(
                                        (c) => c.id == comment.id,
                                      );
                                    });
                                    await saveData();
                                    refresh(() {});
                                    showMessage('نظر حذف شد');
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> reportPost(IranaPost post) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SimpleDialog(
          title: const Text('گزارش پست'),
          children: [
            for (final item in [
              'اسپم',
              'محتوای نامناسب',
              'مزاحمت',
              'سایر',
            ])
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, item),
                child: Text(item),
              ),
          ],
        ),
      ),
    );

    if (reason == null) return;

    if (!reportedPostIds.contains(post.id)) {
      reportedPostIds.add(post.id);
      await saveData();
    }

    showMessage('گزارش با موضوع «$reason» در دستگاه ثبت شد');
  }

  Future<void> notInterested(IranaPost post) async {
    if (!hiddenPostIds.contains(post.id)) {
      setState(() => hiddenPostIds.add(post.id));
      await saveData();
    }

    showMessage('این پست دیگر در صفحه خانه نمایش داده نمی‌شود');
  }

  Future<void> copyPostLink(IranaPost post) async {
    await Clipboard.setData(
      ClipboardData(text: 'irana://post/${post.id}'),
    );
    showMessage('شناسه لینک محلی پست کپی شد');
  }

  Future<void> sharePost(IranaPost post) async {
    await Clipboard.setData(
      ClipboardData(
        text: '${post.caption}\nirana://post/${post.id}',
      ),
    );
    showMessage(
      'متن و لینک محلی کپی شد؛ اشتراک‌گذاری عمومی هنوز فعال نیست',
    );
  }

  Future<void> showPostMenu(IranaPost post) async {
    final isOwner = post.username == 'irana_user';

    final options = <Map<String, dynamic>>[
      if (isOwner)
        {
          'title': 'ویرایش پست',
          'icon': Icons.edit_outlined,
          'action': 'edit',
        },
      if (isOwner)
        {
          'title': 'حذف پست',
          'icon': Icons.delete_outline,
          'action': 'delete',
        },
      {
        'title': savedPostIds.contains(post.id)
            ? 'حذف از ذخیره‌شده‌ها'
            : 'ذخیره پست',
        'icon': Icons.bookmark_border,
        'action': 'save',
      },
      {
        'title': 'کپی لینک',
        'icon': Icons.link,
        'action': 'copy',
      },
      {
        'title': 'اشتراک‌گذاری',
        'icon': Icons.share_outlined,
        'action': 'share',
      },
      if (isOwner)
        {
          'title': post.commentsEnabled ? 'بستن نظرات' : 'بازکردن نظرات',
          'icon': Icons.comment_outlined,
          'action': 'comments',
        },
      if (isOwner)
        {
          'title': 'مدیریت نظرات',
          'icon': Icons.comment_bank_outlined,
          'action': 'manage',
        },
      if (!isOwner)
        {
          'title': 'گزارش پست',
          'icon': Icons.flag_outlined,
          'action': 'report',
        },
      if (!isOwner)
        {
          'title': 'علاقه‌مند نیستم',
          'icon': Icons.visibility_off_outlined,
          'action': 'hide',
        },
    ];

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return ListTile(
                leading: Icon(option['icon'] as IconData),
                title: Text(option['title'] as String),
                onTap: () => Navigator.pop(
                  sheetContext,
                  option['action'] as String,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'edit':
        await editPost(post);
        break;
      case 'delete':
        await deletePost(post);
        break;
      case 'save':
        await toggleSave(post.id);
        break;
      case 'copy':
        await copyPostLink(post);
        break;
      case 'share':
        await sharePost(post);
        break;
      case 'comments':
        await toggleComments(post);
        break;
      case 'manage':
        await manageComments(post);
        break;
      case 'report':
        await reportPost(post);
        break;
      case 'hide':
        await notInterested(post);
        break;
    }
  }

  void openStory(IranaStory story) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryViewer(story: story)),
    );
  }

  Future<void> addStoryToHighlights() async {
    // فقط استوری‌هایی که قبلاً منتشر شده‌اند و هنوز ۲۴ ساعتشان تمام نشده.
    final availableStories = stories
        .where((story) =>
            !story.expired && File(story.filePath).existsSync())
        .toList();

    if (availableStories.isEmpty) {
      showMessage('ابتدا یک استوری منتشر کن؛ سپس می‌توانی آن را هایلایت کنی');
      return;
    }

    final selected = await showDialog<IranaStory>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('انتخاب استوری برای هایلایت'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableStories.length,
              itemBuilder: (context, index) {
                final story = availableStories[index];
                final alreadyAdded =
                    highlightedStories.any((item) => item.id == story.id);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: story.isVideo
                        ? null
                        : FileImage(File(story.filePath)),
                    child: story.isVideo
                        ? const Icon(Icons.play_arrow)
                        : null,
                  ),
                  title: Text('استوری ${index + 1}'),
                  subtitle: Text(
                    alreadyAdded ? 'قبلاً به هایلایت اضافه شده' : 'افزودن به هایلایت',
                  ),
                  trailing: alreadyAdded
                      ? const Icon(Icons.check_circle, color: iranaPurple)
                      : const Icon(Icons.add_circle_outline, color: iranaPurple),
                  onTap: alreadyAdded
                      ? null
                      : () => Navigator.pop(dialogContext, story),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('انصراف'),
            ),
          ],
        ),
      ),
    );

    if (selected == null) return;

    if (highlightedStories.any((item) => item.id == selected.id)) {
      showMessage('این استوری قبلاً به هایلایت اضافه شده است');
      return;
    }

    setState(() {
      // فقط نسخه هایلایت ذخیره می‌شود؛ استوری تازه‌ای منتشر نمی‌شود.
      highlightedStories.insert(0, selected);
    });
    await saveData();
    showMessage('به هایلایت اضافه شد؛ پس از ۲۴ ساعت از نوار استوری حذف می‌شود 💜');
  }

  Future<void> removeStoryFromHighlights(IranaStory story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف از هایلایت'),
          content: const Text('این استوری فقط از هایلایت حذف شود؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    setState(() {
      highlightedStories.removeWhere((item) => item.id == story.id);
    });
    await saveData();
    showMessage('استوری از هایلایت حذف شد');
  }

  void openImage(IranaPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaImageViewer(
          path: post.imagePath,
          title: post.username,
        ),
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

  Future<void> openComments(IranaPost post) async {
    if (!post.commentsEnabled) {
      showMessage('نظرهای این پست بسته است');
      return;
    }

    final controller = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, refresh) {
              final postComments =
                  comments.where((c) => c.postId == post.id).toList();

              void sendComment({String? parentId}) {
                final text = controller.text.trim();
                if (text.isEmpty) return;

                setState(() {
                  comments.add(
                    IranaComment(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      postId: post.id,
                      username: 'irana_user',
                      text: text,
                      date: DateTime.now(),
                      parentId: parentId,
                    ),
                  );
                });

                controller.clear();
                saveData();
                refresh(() {});
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'نظرات پست',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: postComments.isEmpty
                            ? const Center(
                                child: Text('هنوز نظری ثبت نشده است'),
                              )
                            : ListView.builder(
                                itemCount: postComments.length,
                                itemBuilder: (context, index) {
                                  final comment = postComments[index];
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                                    title: Text(comment.username),
                                    subtitle: Text(comment.text),
                                    trailing: IconButton(
                                      tooltip: 'پاسخ',
                                      icon: const Icon(Icons.reply),
                                      onPressed: () {
                                        controller.text =
                                            '@${comment.username} ';
                                        FocusScope.of(context).unfocus();
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => sendComment(),
                                decoration: InputDecoration(
                                  hintText: 'نظر خود را بنویس...',
                                  filled: true,
                                  fillColor: iranaBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(22),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => sendComment(),
                              icon: const Icon(
                                Icons.send,
                                color: iranaPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    controller.dispose();
  }

  Future<void> forwardPost(IranaPost post) async {
    final receiverController = TextEditingController();

    final receiver = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('فوروارد پست'),
          content: TextField(
            controller: receiverController,
            decoration: const InputDecoration(
              labelText: 'نام کاربری گیرنده',
              hintText: 'مثلاً user123',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = receiverController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(dialogContext, name);
                }
              },
              child: const Text('ارسال'),
            ),
          ],
        ),
      ),
    );

    receiverController.dispose();
    if (receiver == null || receiver.isEmpty) return;

    setState(() {
      forwards.add(
        IranaForward(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          postId: post.id,
          receiver: receiver,
          date: DateTime.now(),
        ),
      );
    });

    await saveData();
    showMessage('فوروارد در فهرست محلی ثبت شد');
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
        appBar: selectedIndex == 4
            ? null
            : AppBar(
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IranaNotificationsPage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.favorite_border,
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
              savedPostIds: savedPostIds,
              hiddenPostIds: hiddenPostIds,
              onAddStory: addStory,
              onOpenStory: openStory,
              onLike: toggleLike,
              onOpenVideo: openVideo,
              onOpenImage: openImage,
              onComments: openComments,
              onForward: forwardPost,
              onSave: toggleSave,
              onPostMenu: showPostMenu,
            ),
            SearchPage(posts: posts),
            CreatePage(onPublish: addPost),
            VideosPage(
              stories: stories,
              posts: posts,
              onOpenStory: openStory,
              onOpenVideo: openVideo,
            ),
            ProfilePage(
              posts: posts,
              highlights: highlightedStories,
              onAddHighlight: addStoryToHighlights,
              onOpenHighlight: openStory,
              onRemoveHighlight: removeStoryFromHighlights,
            ),
            const DirectMessagesPage(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          selectedItemColor: iranaPurple,
          unselectedItemColor: Colors.black54,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          onTap: (index) {
            setState(() => selectedIndex = index);
          },
          items: List.generate(
            pages.length,
            (index) => BottomNavigationBarItem(
              icon: Icon(icons[index]),
              label: pages[index],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- DIRECT MESSAGES ----------------

class DirectMessagesPage extends StatelessWidget {
  const DirectMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: iranaBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.send_outlined,
                  size: 58,
                  color: iranaPurple,
                ),
                const SizedBox(height: 14),
                const Text(
                  'دایرکت‌های ایرانا',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: iranaPurple,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'صندوق پیام‌ها در مرحله بعد تکمیل می‌شود.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- FEED ----------------

class FeedPage extends StatelessWidget {
  final List<IranaStory> stories;
  final List<IranaPost> posts;
  final List<String> savedPostIds;
  final List<String> hiddenPostIds;
  final VoidCallback onAddStory;
  final Function(IranaStory) onOpenStory;
  final Function(String) onLike;
  final Function(IranaPost) onOpenVideo;
  final Function(IranaPost) onOpenImage;
  final Function(IranaPost) onComments;
  final Function(IranaPost) onForward;
  final Function(String) onSave;
  final Function(IranaPost) onPostMenu;

  const FeedPage({
    super.key,
    required this.stories,
    required this.posts,
    required this.savedPostIds,
    required this.hiddenPostIds,
    required this.onAddStory,
    required this.onOpenStory,
    required this.onLike,
    required this.onOpenVideo,
    required this.onOpenImage,
    required this.onComments,
    required this.onForward,
    required this.onSave,
    required this.onPostMenu,
  });

  @override
  Widget build(BuildContext context) {
    final visiblePosts =
        posts.where((p) => !hiddenPostIds.contains(p.id)).toList();

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
        if (visiblePosts.isEmpty)
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
        ...visiblePosts.map(
          (post) => PostCard(
            post: post,
            isSaved: savedPostIds.contains(post.id),
            onLike: () => onLike(post.id),
            onOpenVideo: () => onOpenVideo(post),
            onOpenImage: () => onOpenImage(post),
            onComments: () => onComments(post),
            onForward: () => onForward(post),
            onSave: () => onSave(post.id),
            onMenu: () => onPostMenu(post),
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

// ---------------- IMAGE VIEWER ----------------

class MediaImageViewer extends StatelessWidget {
  final String path;
  final String title;

  const MediaImageViewer({
    super.key,
    required this.path,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: File(path).existsSync()
            ? InteractiveViewer(
                minScale: 0.7,
                maxScale: 5,
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 70,
                  ),
                ),
              )
            : const Text(
                'تصویر پیدا نشد',
                style: TextStyle(color: Colors.white),
              ),
      ),
    );
  }
}

// ---------------- VIDEO VIEWER ----------------

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
      controller.setLooping(false);
      controller.play();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String timeText(Duration duration) {
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: FutureBuilder<void>(
            future: initializeFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'پخش ویدئو امکان‌پذیر نیست',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  return Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: value.aspectRatio == 0
                                ? 16 / 9
                                : value.aspectRatio,
                            child: VideoPlayer(controller),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: iranaPink,
                            bufferedColor: Colors.white38,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              timeText(value.position),
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              color: Colors.white,
                              iconSize: 48,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 52,
                                minHeight: 52,
                              ),
                              onPressed: () {
                                if (value.isPlaying) {
                                  controller.pause();
                                } else {
                                  if (value.duration > Duration.zero &&
                                      value.position >= value.duration) {
                                    controller.seekTo(Duration.zero);
                                  }
                                  controller.play();
                                }
                              },
                              icon: Icon(
                                value.isPlaying
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              timeText(value.duration),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------- STORY VIEWER ----------------

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
                  return ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: controller!,
                    builder: (context, value, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: value.aspectRatio,
                            child: VideoPlayer(controller!),
                          ),
                          VideoProgressIndicator(
                            controller!,
                            allowScrubbing: true,
                          ),
                          IconButton(
                            color: Colors.white,
                            iconSize: 45,
                            onPressed: () {
                              value.isPlaying
                                  ? controller!.pause()
                                  : controller!.play();
                            },
                            icon: Icon(
                              value.isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                          ),
                        ],
                      );
                    },
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

// ---------------- POST CARD ----------------

class PostCard extends StatelessWidget {
  final IranaPost post;
  final bool isSaved;
  final VoidCallback onLike;
  final VoidCallback onOpenVideo;
  final VoidCallback onOpenImage;
  final VoidCallback onComments;
  final VoidCallback onForward;
  final VoidCallback onSave;
  final VoidCallback onMenu;

  const PostCard({
    super.key,
    required this.post,
    required this.isSaved,
    required this.onLike,
    required this.onOpenVideo,
    required this.onOpenImage,
    required this.onComments,
    required this.onForward,
    required this.onSave,
    required this.onMenu,
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
            trailing: IconButton(
              tooltip: 'گزینه‌های پست',
              onPressed: onMenu,
              icon: const Icon(Icons.more_vert),
            ),
          ),
          if (file.existsSync())
            GestureDetector(
              onTap: post.isVideo ? onOpenVideo : onOpenImage,
              child: post.isVideo
                  ? Container(
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
                    )
                  : Image.file(
                      file,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        height: 200,
                        child: Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
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
                  onPressed: onComments,
                  icon: Icon(
                    Icons.mode_comment_outlined,
                    color: post.commentsEnabled ? Colors.black87 : Colors.grey,
                  ),
                ),
                IconButton(
                  onPressed: onForward,
                  icon: const Icon(Icons.send_outlined),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onSave,
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? iranaPurple : Colors.black87,
                  ),
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

// ---------------- SEARCH ----------------

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

// ---------------- CREATE POST ----------------

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

// ---------------- VIDEOS ----------------

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
  final List<IranaStory> highlights;
  final VoidCallback onAddHighlight;
  final Function(IranaStory) onOpenHighlight;
  final Function(IranaStory) onRemoveHighlight;

  const ProfilePage({
    super.key,
    required this.posts,
    required this.highlights,
    required this.onAddHighlight,
    required this.onOpenHighlight,
    required this.onRemoveHighlight,
  });

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
          SizedBox(
            height: 330,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 285,
                  child: ClipPath(
                    clipper: _ProfileBannerClipper(),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF10002E),
                                Color(0xFF30005F),
                                Color(0xFF650A9C),
                                Color(0xFF26004F),
                              ],
                              stops: [0, 0.38, 0.72, 1],
                            ),
                          ),
                        ),
                        const CustomPaint(
                          painter: _ProfileBannerPainter(),
                        ),
                        Positioned(
                          top: 10,
                          left: 18,
                          right: 18,
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Image.asset(
                                      'assets/images/irana_brand_header.jpg',
                                      width: 205,
                                      height: 58,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.centerLeft,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Column(
                                  children: [
                                  IconButton(
                                    tooltip: 'انتشار محتوای جدید',
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'برای انتشار محتوا، بخش انتشار را از نوار پایین انتخاب کنید',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.white,
                                      size: 31,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'منوی تنظیمات',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const IranaSettingsPage(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.menu_rounded,
                                      color: Colors.white,
                                      size: 31,
                                    ),
                                  ),
                                ],
                              ),
                              ],
                            ),
                          ),
                        ),
                        const Positioned(
                          right: 28,
                          top: 105,
                          child: Text(
                            'جهان زیبای ایرانا',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  top: 115,
                  child: GestureDetector(
                    onTap: changeAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFFD45E),
                            Color(0xFFFFF1B5),
                            Color(0xFFC58A22),
                            Color(0xFFFFD45E),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 67,
                        backgroundColor: const Color(0xFF3B126C),
                        backgroundImage: image ??
                            const AssetImage(
                              'assets/images/irana_default_avatar.jpg',
                            ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 25,
                  top: 225,
                  child: GestureDetector(
                    onTap: changeAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Color(0xFF4C087D),
                        size: 23,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 128,
                  width: 230,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: const Text(
                              'IRANA',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF12A9F5),
                            size: 27,
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        profileName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _BannerStat(
                              value: widget.posts.length.toString(),
                              label: 'پست‌ها',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 44,
                            color: Colors.white70,
                          ),
                          const Expanded(
                            child: _BannerStat(
                              value: '0',
                              label: 'دنبال‌کننده',
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 44,
                            color: Colors.white70,
                          ),
                          const Expanded(
                            child: _BannerStat(
                              value: '0',
                              label: 'دنبال‌شونده',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              bio.isEmpty ? 'به دنیای زیبای ایران خوش آمدید 💜' : bio,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF21152C),
                fontSize: 15,
                height: 1.9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 3, 24, 12),
            child: Row(
              children: [
                Icon(Icons.link, color: Color(0xFF5A128C), size: 24),
                SizedBox(width: 7),
                Text(
                  'https://irana.app',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: Color(0xFF5A128C),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: editProfile,
                    icon: const Icon(Icons.edit_rounded, size: 19),
                    label: const Text('ویرایش پروفایل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A078D),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'اشتراک‌گذاری پروفایل در نسخه بعدی فعال می‌شود',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 19),
                    label: const Text('اشتراک‌گذاری پروفایل'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4C087D),
                      side: const BorderSide(
                        color: Color(0xFF4C087D),
                        width: 1.4,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                const Text(
                  'هایلایت‌ها',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  'داستان‌های منتخب',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 112,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _ProfileAddHighlight(onTap: widget.onAddHighlight),
                ...widget.highlights.map(
                  (story) => _ProfileHighlight(
                    story: story,
                    onTap: () => widget.onOpenHighlight(story),
                    onDelete: () => widget.onRemoveHighlight(story),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Icon(Icons.grid_on_rounded, color: Color(0xFF5A078D), size: 27),
                Icon(Icons.video_library_outlined, size: 27),
                Icon(Icons.play_circle_outline_rounded, size: 29),
                Icon(Icons.person_pin_outlined, size: 28),
              ],
            ),
          ),
          Container(
            height: 3,
            alignment: Alignment.centerRight,
            child: Container(
              width: MediaQuery.of(context).size.width / 4,
              decoration: BoxDecoration(
                color: const Color(0xFF5A078D),
                borderRadius: BorderRadius.circular(4),
              ),
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
    );
  }
}

class _ProfileAddHighlight extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileAddHighlight({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 94,
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBDBDBD), width: 1.5),
              ),
              child: const Icon(Icons.add, color: Color(0xFF5A128C), size: 34),
            ),
            const SizedBox(height: 5),
            const Text(
              'جدید',
              maxLines: 1,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHighlight extends StatelessWidget {
  final IranaStory story;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProfileHighlight({
    required this.story,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(story.filePath);
    return SizedBox(
      width: 94,
      child: Column(
        children: [
          SizedBox(
            width: 82,
            height: 76,
            child: Stack(
              children: [
                Positioned(
                  left: 3,
                  top: 0,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFFFD45E),
                            Color(0xFFFFF3C1),
                            Color(0xFFC58A22),
                          ],
                        ),
                      ),
                      child: ClipOval(
                        child: story.isVideo
                            ? Container(
                                color: const Color(0xFF3B126C),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              )
                            : (file.existsSync()
                                ? Image.file(file, fit: BoxFit.cover)
                                : const ColoredBox(
                                    color: Color(0xFFEDE2F7),
                                    child: Icon(Icons.broken_image),
                                  )),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onDelete,
                      child: const Padding(
                        padding: EdgeInsets.all(3),
                        child: Icon(Icons.close, size: 15, color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${story.createdAt.day}/${story.createdAt.month}',
            maxLines: 1,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String value;
  final String label;

  const _BannerStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ],
    );
  }
}

class _ProfileBannerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 42)
      ..quadraticBezierTo(
        size.width * 0.76,
        size.height + 10,
        size.width * 0.48,
        size.height - 5,
      )
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height + 13,
        0,
        size.height - 48,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ProfileBannerPainter extends CustomPainter {
  const _ProfileBannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = const Color(0xFFFFD76A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final glow = Paint()
      ..color = const Color(0x66D89BFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final wave = Path()
      ..moveTo(-10, size.height * 0.52)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.28,
        size.width * 0.42,
        size.height * 0.72,
        size.width * 0.62,
        size.height * 0.38,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.12,
        size.width * 0.9,
        size.height * 0.24,
        size.width + 10,
        size.height * 0.06,
      );
    canvas.drawPath(wave, glow);
    canvas.drawPath(wave, gold);

    final thinWave = Path()
      ..moveTo(-5, size.height * 0.7)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.48,
        size.width * 0.34,
        size.height * 0.84,
        size.width * 0.56,
        size.height * 0.58,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.35,
        size.width * 0.9,
        size.height * 0.55,
        size.width + 5,
        size.height * 0.32,
      );
    canvas.drawPath(thinWave, gold);

    final starPaint = Paint()..color = const Color(0xFFFFD76A);
    for (final point in <Offset>[
      Offset(size.width * 0.08, size.height * 0.18),
      Offset(size.width * 0.58, size.height * 0.12),
      Offset(size.width * 0.82, size.height * 0.2),
      Offset(size.width * 0.94, size.height * 0.42),
    ]) {
      final path = Path()
        ..moveTo(point.dx, point.dy - 6)
        ..lineTo(point.dx + 2, point.dy - 2)
        ..lineTo(point.dx + 6, point.dy)
        ..lineTo(point.dx + 2, point.dy + 2)
        ..lineTo(point.dx, point.dy + 6)
        ..lineTo(point.dx - 2, point.dy + 2)
        ..lineTo(point.dx - 6, point.dy)
        ..lineTo(point.dx - 2, point.dy - 2)
        ..close();
      canvas.drawPath(path, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

// ---------------- SETTINGS MENU ----------------

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

// ---------------- SETTINGS DETAIL ----------------

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

// ---------------- STORY CREATE ----------------

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
                                publishing
                                    ? 'در حال انتشار...'
                                    : 'انتشار استوری',
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