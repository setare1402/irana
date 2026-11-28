import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'notifications_page.dart';
import 'features_hub_page.dart';

final ValueNotifier<Locale> iranaLocale = ValueNotifier(const Locale('fa'));

const Map<String, String> iranaLanguageNames = {
  'fa': 'فارسی',
  'en': 'English',
  'ar': 'العربية',
};

TextDirection directionForLanguage(String code) =>
    const {'fa', 'ar'}.contains(code)
        ? TextDirection.rtl
        : TextDirection.ltr;

TextDirection get iranaTextDirection =>
    directionForLanguage(iranaLocale.value.languageCode);

Widget _iranaDiagnosticErrorWidget(FlutterErrorDetails details) {
  final errorText = '${details.exceptionAsString()}\n\n${details.stack ?? ''}';
  return Directionality(
    textDirection: TextDirection.rtl,
    child: Material(
      color: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'ایرانا هنگام نمایش این بخش با خطا روبه‌رو شد',
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            const Text('متن خطا را برای بررسی نگه دار:'),
            const SizedBox(height: 10),
            SelectableText(
              errorText,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = _iranaDiagnosticErrorWidget;

  // Start the app immediately; loading a saved language must not block startup.
  runApp(const IranaApp());

  try {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('irana_language') ?? 'fa';
    if (iranaLanguageNames.containsKey(savedLanguage)) {
      iranaLocale.value = Locale(savedLanguage);
    }
    final savedTheme = prefs.getString('irana_theme') ?? 'پیش‌فرض ایرانا';
    if (iranaThemePalettes.containsKey(savedTheme)) {
      iranaThemeName.value = savedTheme;
    }
  } catch (_) {
    // Keep default language and appearance if saved settings cannot be read.
  }
}

const Color iranaPurple = Color(0xFF7139A8);
const Color iranaPink = Color(0xFFE84B91);
const Color iranaBg = Color(0xFFFAF9FC);
const Color iranaGold = Color(0xFFFFD778);

final ValueNotifier<String> iranaThemeName =
    ValueNotifier<String>('پیش‌فرض ایرانا');

class IranaThemePalette {
  final Color primary;
  final Color background;
  final Color surface;
  final Brightness brightness;

  const IranaThemePalette({
    required this.primary,
    required this.background,
    required this.surface,
    this.brightness = Brightness.light,
  });
}

const Map<String, IranaThemePalette> iranaThemePalettes = {
  'پیش‌فرض ایرانا': IranaThemePalette(
    primary: iranaPurple,
    background: Color(0xFFFAF9FC),
    surface: Colors.white,
  ),
  'شکوفه صورتی': IranaThemePalette(
    primary: Color(0xFFC44D85),
    background: Color(0xFFFFF7FA),
    surface: Color(0xFFFFEDF4),
  ),
  'باغ گل‌ها': IranaThemePalette(
    primary: Color(0xFF7A9564),
    background: Color(0xFFF6FAF3),
    surface: Color(0xFFEBF3E5),
  ),
  'غروب بنفش': IranaThemePalette(
    primary: Color(0xFF7553A6),
    background: Color(0xFFF8F5FC),
    surface: Color(0xFFEFE8F8),
  ),
  'دریای آرام': IranaThemePalette(
    primary: Color(0xFF287E91),
    background: Color(0xFFF2FAFC),
    surface: Color(0xFFE4F3F6),
  ),
  'شب پرستاره': IranaThemePalette(
    primary: Color(0xFF829CE0),
    background: Color(0xFF111827),
    surface: Color(0xFF202C43),
    brightness: Brightness.dark,
  ),
  'جاده و طبیعت': IranaThemePalette(
    primary: Color(0xFF638653),
    background: Color(0xFFF5F8F1),
    surface: Color(0xFFEAF1E4),
  ),
};

ThemeData iranaThemeData(String name) {
  final palette = iranaThemePalettes[name] ??
      iranaThemePalettes['پیش‌فرض ایرانا']!;
  final scheme = ColorScheme.fromSeed(
    seedColor: palette.primary,
    brightness: palette.brightness,
    surface: palette.surface,
  );

  // Each theme changes the actual component geometry as well as its colors.
  final radius = switch (name) {
    'شکوفه صورتی' => 26.0,
    'باغ گل‌ها' => 20.0,
    'غروب بنفش' => 12.0,
    'دریای آرام' => 30.0,
    'شب پرستاره' => 8.0,
    'جاده و طبیعت' => 16.0,
    _ => 18.0,
  };
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
  );
  final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius + 2),
    side: BorderSide(color: palette.primary.withOpacity(0.16)),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    scaffoldBackgroundColor: name == 'شب پرستاره' ? Colors.transparent : palette.background,
    canvasColor: palette.background,
    colorScheme: scheme,
    primaryColor: palette.primary,
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      backgroundColor: palette.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: palette.surface,
      selectedItemColor: palette.primary,
      unselectedItemColor: scheme.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 5,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.surface,
      indicatorColor: palette.primary.withOpacity(0.14),
      iconTheme: MaterialStateProperty.resolveWith((states) =>
          IconThemeData(color: states.contains(MaterialState.selected)
              ? palette.primary : scheme.onSurfaceVariant)),
      labelTextStyle: MaterialStateProperty.all(
        TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: palette.brightness == Brightness.dark
            ? scheme.onPrimary : Colors.white,
        shape: buttonShape,
        elevation: name == 'شب پرستاره' ? 0 : 2,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.primary,
        side: BorderSide(color: palette.primary.withOpacity(0.7), width: 1.5),
        shape: buttonShape,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.primary,
        shape: buttonShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: palette.primary,
        shape: buttonShape,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.primary,
      foregroundColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: name == 'شب پرستاره' ? 0 : 2,
      shape: cardShape,
      margin: const EdgeInsets.all(6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: palette.primary.withOpacity(0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: palette.primary.withOpacity(0.28)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: palette.primary, width: 2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius + 4),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.surface,
      selectedColor: palette.primary.withOpacity(0.18),
      side: BorderSide(color: palette.primary.withOpacity(0.3)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      labelStyle: TextStyle(color: scheme.onSurface),
    ),
    dividerTheme: DividerThemeData(
      color: palette.primary.withOpacity(0.18),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

Future<void> applyIranaTheme(String name) async {
  if (!iranaThemePalettes.containsKey(name)) return;
  iranaThemeName.value = name;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('irana_theme', name);
}

class IranaApp extends StatelessWidget {
  const IranaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: iranaLocale,
      builder: (context, locale, child) {
        return ValueListenableBuilder<String>(
          valueListenable: iranaThemeName,
          builder: (context, themeName, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'IRANA',
              locale: locale,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en')],
              localeResolutionCallback: (deviceLocale, supportedLocales) =>
                  const Locale('en'),
              theme: iranaThemeData(themeName),
              builder: (context, child) {
                if (themeName == 'پیش‌فرض ایرانا') {
                  return child ?? const SizedBox.shrink();
                }
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: IranaThemeBackgroundPainter(themeName),
                    ),
                    child ?? const SizedBox.shrink(),
                  ],
                );
              },
              home: Directionality(
                textDirection: directionForLanguage(locale.languageCode),
                child: const IranaHome(),
              ),
            );
          },
        );
      },
    );
  }
}

class IranaThemeBackgroundPainter extends CustomPainter {
  final String themeName;
  const IranaThemeBackgroundPainter(this.themeName);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = switch (themeName) {
      'شکوفه صورتی' => [const Color(0xFF35172D), const Color(0xFF7B315C), const Color(0xFF241426)],
      'باغ گل‌ها' => [const Color(0xFF172C22), const Color(0xFF35583D), const Color(0xFF15251D)],
      'غروب بنفش' => [const Color(0xFF21163D), const Color(0xFF684080), const Color(0xFFCE795F)],
      'دریای آرام' => [const Color(0xFF092B42), const Color(0xFF17627A), const Color(0xFF102D45)],
      'شب پرستاره' => [const Color(0xFF080D24), const Color(0xFF151A3B), const Color(0xFF090F22)],
      'جاده و طبیعت' => [const Color(0xFF172B32), const Color(0xFF3E604E), const Color(0xFF182A2A)],
      _ => [const Color(0xFF202033), const Color(0xFF303044), const Color(0xFF202033)],
    };
    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(rect);
    canvas.drawRect(rect, base);

    final softGlow = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.12), Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * .78, size.height * .17),
        radius: size.width * .65,
      ));
    canvas.drawRect(rect, softGlow);

    if (themeName == 'شب پرستاره') {
      const points = [
        Offset(.08,.08), Offset(.22,.15), Offset(.39,.07), Offset(.57,.19),
        Offset(.73,.08), Offset(.91,.22), Offset(.14,.34), Offset(.31,.28),
        Offset(.49,.39), Offset(.67,.32), Offset(.86,.43), Offset(.06,.57),
        Offset(.25,.51), Offset(.44,.62), Offset(.62,.54), Offset(.81,.65),
        Offset(.95,.76), Offset(.13,.82), Offset(.35,.76), Offset(.55,.88),
        Offset(.75,.84), Offset(.91,.94), Offset(.04,.95), Offset(.48,.12),
      ];
      final star = Paint()..color = const Color(0xFFE9E5FF);
      for (var i = 0; i < points.length; i++) {
        final p = Offset(points[i].dx * size.width, points[i].dy * size.height);
        canvas.drawCircle(p, i % 5 == 0 ? 1.8 : 1.0, star);
      }
      final moon = Offset(size.width * .82, size.height * .12);
      canvas.drawCircle(moon, 23, Paint()..color = const Color(0xFFFFE8A6));
      canvas.drawCircle(moon.translate(10, -8), 22,
          Paint()..color = const Color(0xFF151A3B));
    } else if (themeName == 'شکوفه صورتی') {
      final petal = Paint()..color = const Color(0x55FFC4DE);
      for (final p in [Offset(.12,.18), Offset(.82,.27), Offset(.25,.73), Offset(.91,.83)]) {
        final center = Offset(p.dx * size.width, p.dy * size.height);
        for (var i = 0; i < 5; i++) {
          final a = i * math.pi * 2 / 5;
          canvas.drawCircle(center.translate(math.cos(a)*10, math.sin(a)*10), 8, petal);
        }
        canvas.drawCircle(center, 4, Paint()..color = const Color(0x99FFE6A8));
      }
    } else if (themeName == 'باغ گل‌ها') {
      final leaf = Paint()..color = const Color(0x4439C77A);
      for (final p in [Offset(.08,.24), Offset(.9,.36), Offset(.18,.78), Offset(.82,.86)]) {
        final center = Offset(p.dx * size.width, p.dy * size.height);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(-.55);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 42, height: 18), leaf);
        canvas.drawLine(const Offset(-20,0), const Offset(20,0),
            Paint()..color = const Color(0x557DD99B)..strokeWidth = 1);
        canvas.restore();
      }
    } else if (themeName == 'غروب بنفش') {
      final sun = Offset(size.width*.78, size.height*.22);
      canvas.drawCircle(sun, 38, Paint()..color = const Color(0x88FFC58D));
      final hill = Paint()..color = const Color(0x44301B55);
      final path = Path()
        ..moveTo(0, size.height*.48)
        ..quadraticBezierTo(size.width*.35, size.height*.25, size.width*.58, size.height*.48)
        ..quadraticBezierTo(size.width*.8, size.height*.65, size.width, size.height*.42)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)..close();
      canvas.drawPath(path, hill);
    } else if (themeName == 'دریای آرام') {
      final wave = Paint()
        ..color = const Color(0x4437C5D9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      for (var i = 0; i < 5; i++) {
        final y = size.height * (.35 + i * .12);
        final path = Path()
          ..moveTo(0, y)
          ..quadraticBezierTo(size.width*.25, y-22, size.width*.5, y)
          ..quadraticBezierTo(size.width*.75, y+22, size.width, y);
        canvas.drawPath(path, wave);
      }
    } else if (themeName == 'جاده و طبیعت') {
      final hill = Paint()..color = const Color(0x554E8865);
      final path = Path()
        ..moveTo(0, size.height*.52)
        ..quadraticBezierTo(size.width*.22, size.height*.22, size.width*.45, size.height*.52)
        ..quadraticBezierTo(size.width*.72, size.height*.18, size.width, size.height*.48)
        ..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
      canvas.drawPath(path, hill);
      final road = Path()
        ..moveTo(size.width*.43, size.height)
        ..quadraticBezierTo(size.width*.52, size.height*.68, size.width*.49, size.height*.48)
        ..lineTo(size.width*.58, size.height*.48)
        ..quadraticBezierTo(size.width*.56, size.height*.72, size.width*.7, size.height)
        ..close();
      canvas.drawPath(road, Paint()..color = const Color(0x553D4140));
    }
  }

  @override
  bool shouldRepaint(covariant IranaThemeBackgroundPainter oldDelegate) =>
      oldDelegate.themeName != themeName;
}

class IranaStarryBackgroundPainter extends CustomPainter {
  const IranaStarryBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF080D24), Color(0xFF151A3B), Color(0xFF090F22)],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6250A8).withOpacity(0.30),
          const Color(0xFF6250A8).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.78, size.height * 0.16),
        radius: size.width * 0.58,
      ));
    canvas.drawRect(rect, glow);

    final stars = <Offset>[
      const Offset(.08,.08), const Offset(.22,.15), const Offset(.39,.07),
      const Offset(.57,.19), const Offset(.73,.08), const Offset(.91,.22),
      const Offset(.14,.34), const Offset(.31,.28), const Offset(.49,.39),
      const Offset(.67,.32), const Offset(.86,.43), const Offset(.06,.57),
      const Offset(.25,.51), const Offset(.44,.62), const Offset(.62,.54),
      const Offset(.81,.65), const Offset(.95,.76), const Offset(.13,.82),
      const Offset(.35,.76), const Offset(.55,.88), const Offset(.75,.84),
      const Offset(.91,.94), const Offset(.04,.95), const Offset(.48,.12),
    ];
    final starPaint = Paint()..color = const Color(0xFFE8E6FF);
    for (var i = 0; i < stars.length; i++) {
      final p = Offset(stars[i].dx * size.width, stars[i].dy * size.height);
      final radius = i % 5 == 0 ? 1.8 : (i % 3 == 0 ? 1.25 : 0.8);
      canvas.drawCircle(p, radius, starPaint);
      if (i % 5 == 0) {
        final ray = Paint()
          ..color = const Color(0x99D8D0FF)
          ..strokeWidth = 0.7;
        canvas.drawLine(p.translate(-4, 0), p.translate(4, 0), ray);
        canvas.drawLine(p.translate(0, -4), p.translate(0, 4), ray);
      }
    }

    final moonCenter = Offset(size.width * .82, size.height * .12);
    canvas.drawCircle(
      moonCenter,
      23,
      Paint()..color = const Color(0xFFFFE8A6),
    );
    canvas.drawCircle(
      moonCenter.translate(10, -8),
      22,
      Paint()..color = const Color(0xFF151A3B),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  final bool isStory;

  IranaForward({
    required this.id,
    required this.postId,
    required this.receiver,
    required this.date,
    this.isStory = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'receiver': receiver,
        'date': date.toIso8601String(),
        'isStory': isStory,
      };

  factory IranaForward.fromJson(Map<String, dynamic> j) => IranaForward(
        id: j['id'],
        postId: j['postId'],
        receiver: j['receiver'],
        date: DateTime.parse(j['date']),
        isStory: j['isStory'] ?? false,
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
  IranaPost? pendingForwardPost;
  IranaStory? pendingForwardStory;

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
    try {
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

    } catch (error, stackTrace) {
      debugPrint('IRANA loadData error: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
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
      MaterialPageRoute(
        builder: (_) => StoryViewer(
          story: story,
          onForward: () {
            Navigator.pop(context);
            setState(() {
              pendingForwardPost = null;
              pendingForwardStory = story;
              selectedIndex = 5;
            });
          },
        ),
      ),
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
    setState(() {
      pendingForwardPost = post;
      selectedIndex = 5;
    });
  }

  Future<void> sendForwardTo(String receiver) async {
    final post = pendingForwardPost;
    final story = pendingForwardStory;
    final target = receiver.trim().replaceFirst(RegExp(r'^@'), '');
    if ((post == null && story == null) || target.isEmpty) return;

    final sendingStory = story != null;
    setState(() {
      forwards.add(
        IranaForward(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          postId: sendingStory ? story.id : post!.id,
          receiver: target,
          date: DateTime.now(),
          isStory: sendingStory,
        ),
      );
      pendingForwardPost = null;
      pendingForwardStory = null;
    });

    await saveData();
    showMessage('${sendingStory ? 'استوری' : 'پست'} برای @$target در فهرست محلی ثبت شد');
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
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                elevation: 0,
                title: Text(
                  'IRANA',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'امکانات IRANA',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IranaFeaturesHubPage(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.grid_view_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IranaNotificationsPage(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.favorite_border,
                      color: Theme.of(context).colorScheme.onSurface,
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
            DirectMessagesPage(
              posts: posts,
              forwards: forwards,
              pendingPost: pendingForwardPost,
              pendingStory: pendingForwardStory,
              onSendPost: sendForwardTo,
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
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

class DirectMessagesPage extends StatefulWidget {
  final List<IranaPost> posts;
  final List<IranaForward> forwards;
  final IranaPost? pendingPost;
  final IranaStory? pendingStory;
  final Future<void> Function(String) onSendPost;

  const DirectMessagesPage({
    super.key,
    required this.posts,
    required this.forwards,
    required this.pendingPost,
    required this.pendingStory,
    required this.onSendPost,
  });

  @override
  State<DirectMessagesPage> createState() => _DirectMessagesPageState();
}

class _DirectMessagesPageState extends State<DirectMessagesPage> {
  final TextEditingController searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentRecipients = <String>[];
    for (final item in widget.forwards.reversed) {
      if (!recentRecipients.contains(item.receiver)) {
        recentRecipients.add(item.receiver);
      }
    }

    final knownUsers = widget.posts
        .map((post) => post.username)
        .where((name) => name.isNotEmpty && name != 'irana_user')
        .toSet()
        .toList()
      ..sort();

    final normalizedQuery = query.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    final filteredRecent = recentRecipients
        .where((name) => name.toLowerCase().contains(normalizedQuery))
        .toList();
    final filteredUsers = knownUsers
        .where((name) =>
            name.toLowerCase().contains(normalizedQuery) &&
            !recentRecipients.contains(name))
        .toList();

    Future<void> sendTo(String username) async {
      await widget.onSendPost(username);
      if (mounted) {
        searchController.clear();
        setState(() => query = '');
      }
    }

    void openRecipient(String username) {
      if (widget.pendingPost != null || widget.pendingStory != null) {
        sendTo(username);
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IranaPrivateChatPage(username: username),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: iranaBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'دایرکت‌ها',
            style: TextStyle(color: iranaPurple, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'چت گروهی',
              icon: const Icon(Icons.groups_rounded, color: iranaPurple),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const IranaFeaturePage(
                    feature: IranaFeatureInfo(
                      title: 'چت گروهی',
                      subtitle: 'گفت‌وگو در گروه‌ها',
                      description: 'ساخت گروه، مدیریت اعضا و گفت‌وگوی گروهی؛ اتصال و پیام‌رسانی واقعی پس از راه‌اندازی سرور فعال می‌شود.',
                      icon: Icons.groups_rounded,
                      items: [
                        'ساخت گروه جدید',
                        'مدیریت اعضا و مدیران',
                        'پیام متنی و رسانه',
                        'تنظیمات و حریم خصوصی گروه',
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Column(
          children: [
            if (widget.pendingPost != null || widget.pendingStory != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.forward_to_inbox, color: iranaPurple),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.pendingStory != null
                            ? 'انتخاب گیرنده برای ارسال این استوری'
                            : 'انتخاب گیرنده برای ارسال این پست',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Keep the post selected until the user chooses a recipient.
                      },
                      child: Text(widget.pendingStory != null ? 'استوری' : 'پست'),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: TextField(
                controller: searchController,
                onChanged: (value) => setState(() => query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'جستجو با نام کاربری یا آیدی...',
                  prefixIcon: const Icon(Icons.search, color: iranaPurple),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() => query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (normalizedQuery.isNotEmpty &&
                      filteredRecent.isEmpty &&
                      filteredUsers.isEmpty)
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEDE2F7),
                        child: Icon(Icons.person_search, color: iranaPurple),
                      ),
                      title: Text('@${searchController.text.trim().replaceFirst(RegExp(r'^@'), '')}'),
                      subtitle: const Text('ارسال به این آیدی'),
                      trailing: const Icon(Icons.send, color: iranaPurple),
                      onTap: () => sendTo(searchController.text),
                    ),
                  if (filteredRecent.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Text(
                        'گیرنده‌های اخیر',
                        style: TextStyle(fontWeight: FontWeight.bold, color: iranaPurple),
                      ),
                    ),
                    ...filteredRecent.map(
                      (name) => ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEDE2F7),
                          child: Icon(Icons.person, color: iranaPurple),
                        ),
                        title: Text('@$name'),
                        subtitle: const Text('ارسال قبلی'),
                        trailing: const Icon(Icons.send_outlined, color: iranaPurple),
                        onTap: () => openRecipient(name),
                      ),
                    ),
                  ],
                  if (filteredUsers.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Text(
                        'حساب‌های شناخته‌شده در این نسخه',
                        style: TextStyle(fontWeight: FontWeight.bold, color: iranaPurple),
                      ),
                    ),
                    ...filteredUsers.map(
                      (name) => ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEDE2F7),
                          child: Icon(Icons.person_outline, color: iranaPurple),
                        ),
                        title: Text('@$name'),
                        trailing: const Icon(Icons.send_outlined, color: iranaPurple),
                        onTap: () => openRecipient(name),
                      ),
                    ),
                  ],
                  if (normalizedQuery.isEmpty &&
                      recentRecipients.isEmpty &&
                      knownUsers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          'هنوز گیرنده‌ای در این نسخه ثبت نشده است.\nبرای ارسال، آیدی شخص را در کادر جستجو وارد کن.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, height: 1.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- PRIVATE CHAT ----------------

class IranaPrivateChatPage extends StatelessWidget {
  final String username;

  const IranaPrivateChatPage({super.key, required this.username});

  void _showServerNotice(BuildContext context, String feature) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(feature),
        content: const Text(
          'ظاهر این قابلیت آماده شده است؛ برقراری تماس و ارسال پیام واقعی پس از اتصال سرور فعال می‌شود.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: iranaBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: iranaPurple,
          elevation: 0,
          title: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEDE2F7),
                child: Icon(Icons.person, color: iranaPurple),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  '@$username',
                  style: const TextStyle(
                    color: iranaPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'تماس صوتی',
              onPressed: () => _showServerNotice(context, 'تماس صوتی'),
              icon: const Icon(Icons.call_rounded),
            ),
            IconButton(
              tooltip: 'تماس تصویری',
              onPressed: () => _showServerNotice(context, 'تماس تصویری'),
              icon: const Icon(Icons.videocam_rounded),
            ),
            IconButton(
              tooltip: 'تماس تصویری گروهی (حداکثر ۵ نفر)',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const IranaGroupVideoCallPage(),
                ),
              ),
              icon: const Icon(Icons.groups_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'گفت‌وگوی خصوصی با این کاربر\n\nپس از اتصال سرور، پیام‌ها و تاریخچه گفتگو در این صفحه نمایش داده می‌شوند.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, height: 1.8),
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: TextField(
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: 'پیام بنویسید...',
                        filled: true,
                        fillColor: Color(0xFFF5F1F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22)),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'ارسال پیام پس از اتصال سرور',
                    onPressed: () => _showServerNotice(context, 'ارسال پیام'),
                    icon: const Icon(Icons.send_rounded, color: iranaPurple),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- GROUP VIDEO CALL ----------------

class IranaGroupVideoCallPage extends StatelessWidget {
  const IranaGroupVideoCallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final participants = List.generate(5, (index) => index + 1);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF17131D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF24202B),
          foregroundColor: Colors.white,
          title: const Text('مکالمه تصویری گروهی'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  '۰ از ۵',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'امکان حضور حداکثر ۵ نفر به‌صورت همزمان در تماس تصویری گروهی',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.7),
              ),
            ),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.all(12),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: participants.map((number) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF332B3D),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 34,
                          backgroundColor: Color(0xFF59436F),
                          child: Icon(Icons.person, color: Colors.white, size: 38),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'جایگاه نفر $number',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: Column(
                children: [
                  const Text(
                    'این صفحه نمایشی است؛ تماس گروهی واقعی پس از اتصال سرور و سرویس تماس فعال می‌شود.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('تماس تصویری گروهی'),
                          content: const Text(
                            'حداکثر ۵ نفر همزمان پشتیبانی می‌شوند. دعوت و برقراری تماس واقعی در مرحله اتصال سرور فعال خواهد شد.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('متوجه شدم'),
                            ),
                          ],
                        ),
                      ),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('دعوت از افراد (پس از اتصال سرور)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iranaPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
  final VoidCallback onForward;
  const StoryViewer({
    super.key,
    required this.story,
    required this.onForward,
  });

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
        actions: [
          IconButton(
            tooltip: 'فوروارد استوری',
            onPressed: widget.onForward,
            icon: const Icon(Icons.send_outlined),
          ),
        ],
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
                  icon: const Icon(Icons.repeat_rounded),
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
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const IranaThemeShopPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.palette_outlined, size: 22),
                label: const Text(
                  'تغییر ظاهر برنامه',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5A078D),
                  backgroundColor: const Color(0xFFF5ECFC),
                  side: const BorderSide(color: Color(0xFFD8B8EC), width: 1.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
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
    IranaMenuItem(
      title: 'فروشگاه پوسته‌ها و ظاهر برنامه',
      icon: Icons.palette_outlined,
      description: 'انتخاب طرح‌های رایگان و خرید پوسته‌های ویژه و پس‌زمینه دلخواه',
    ),
  ];

  void openItem(BuildContext context, IranaMenuItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => item.title == 'فروشگاه پوسته‌ها و ظاهر برنامه'
            ? const IranaThemeShopPage()
            : IranaSettingDetailPage(item: item),
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
      textDirection: iranaTextDirection,
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

// ---------------- THEME SHOP ----------------

class IranaThemeShopPage extends StatefulWidget {
  const IranaThemeShopPage({super.key});

  @override
  State<IranaThemeShopPage> createState() => _IranaThemeShopPageState();
}

class _IranaThemeShopPageState extends State<IranaThemeShopPage> {
  String category = 'همه طرح‌ها';

  final List<Map<String, dynamic>> freeThemes = const [
    {'name': 'مزرعه آفتابگردان', 'icon': Icons.wb_sunny_rounded, 'colors': [Color(0xFFFFC857), Color(0xFFED7B24)], 'group': 'دخترانه'},
    {'name': 'دخترانه رویایی', 'icon': Icons.auto_awesome, 'colors': [Color(0xFFFFA6D5), Color(0xFF8548D8)], 'group': 'دخترانه'},
    {'name': 'شکوفه‌های صورتی', 'icon': Icons.local_florist_rounded, 'colors': [Color(0xFFFF9BCB), Color(0xFF9B3E9D)], 'group': 'دخترانه'},
    {'name': 'ماه و دریاچه', 'icon': Icons.nightlight_round, 'colors': [Color(0xFF164E91), Color(0xFF07152F)], 'group': 'پسرانه'},
    {'name': 'شب مدرن', 'icon': Icons.directions_car_filled_rounded, 'colors': [Color(0xFF35208D), Color(0xFF080B28)], 'group': 'پسرانه'},
    {'name': 'شیر شاه', 'icon': Icons.pets_rounded, 'colors': [Color(0xFFB97828), Color(0xFF352016)], 'group': 'پسرانه'},
  ];

  final List<Map<String, dynamic>> premiumThemes = const [
    {'name': 'پروانه بنفش', 'icon': Icons.flutter_dash_rounded, 'colors': [Color(0xFF7B1FA2), Color(0xFF210047)]},
    {'name': 'قلب‌های نئونی', 'icon': Icons.favorite_rounded, 'colors': [Color(0xFFFF238D), Color(0xFF3B003C)]},
    {'name': 'عمارت طلایی', 'icon': Icons.castle_rounded, 'colors': [Color(0xFFD69B28), Color(0xFF17294B)]},
    {'name': 'رزهای عاشقانه', 'icon': Icons.local_florist_rounded, 'colors': [Color(0xFFE83E83), Color(0xFF35102E)]},
    {'name': 'پاریس شبانه', 'icon': Icons.location_city_rounded, 'colors': [Color(0xFFB832B8), Color(0xFF101A50)]},
    {'name': 'قصر ماه', 'icon': Icons.nightlight_round, 'colors': [Color(0xFF315BBE), Color(0xFF130B42)]},
    {'name': 'کهکشان', 'icon': Icons.auto_awesome_rounded, 'colors': [Color(0xFF8D26E8), Color(0xFF07143B)]},
  ];

  Future<void> selectFreeTheme(String name) async {
    try {
      await applyIranaTheme(name);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('طرح «$name» روی برنامه اعمال و ذخیره شد.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ذخیره طرح انجام نشد؛ دوباره تلاش کن.')),
      );
    }
  }

  void showPurchaseNotice() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('نسخه ویژه IRANA'),
        content: const Text(
          'این پوسته و انتخاب تصویر از گالری، قابلیت پولی هستند. قفل و صفحه خرید در این نسخه نمایشی است؛ فعال‌سازی و ثبت دائمی خرید پس از اتصال درگاه پرداخت و سرور انجام می‌شود.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }

  Widget categoryChip(String title, IconData icon) {
    final selected = category == title;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => category = title),
        avatar: Icon(icon, size: 17, color: selected ? Colors.white : const Color(0xFF512080)),
        label: Text(title),
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF32134E),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        selectedColor: const Color(0xFF7A16E8),
        backgroundColor: const Color(0xFFEAD8FF),
        side: BorderSide(color: selected ? const Color(0xFFFFB8FF) : Colors.white70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        showCheckmark: false,
      ),
    );
  }

  Widget themeCard(Map<String, dynamic> theme, {required bool premium}) {
    final name = theme['name'] as String;
    final colors = (theme['colors'] as List<Color>);
    final icon = theme['icon'] as IconData;
    final selected = iranaThemeName.value == name;
    return GestureDetector(
      onTap: premium ? showPurchaseNotice : () => selectFreeTheme(name),
      child: Container(
        width: 126,
        height: 188,
        margin: const EdgeInsetsDirectional.only(end: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          border: Border.all(
            color: selected ? const Color(0xFFFFE77A) : Colors.white.withOpacity(.8),
            width: selected ? 3 : 1.2,
          ),
          boxShadow: [
            BoxShadow(color: colors.first.withOpacity(.38), blurRadius: 12, offset: const Offset(0, 5)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(top: -18, right: -15, child: Icon(icon, size: 104, color: Colors.white.withOpacity(.12))),
            Positioned(top: 22, left: 0, right: 0, child: Icon(icon, size: 58, color: Colors.white.withOpacity(.92))),
            Positioned(
              top: 9,
              right: 9,
              child: selected
                  ? const CircleAvatar(radius: 13, backgroundColor: Color(0xFF8B18E8), child: Icon(Icons.check, color: Colors.white, size: 17))
                  : premium
                      ? const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD54F), size: 24)
                      : const SizedBox.shrink(),
            ),
            if (premium)
              const Positioned(left: 0, right: 0, bottom: 43, child: Icon(Icons.lock_rounded, color: Colors.white, size: 23)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.62),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                ),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleThemes = freeThemes.where((theme) {
      if (category == 'همه طرح‌ها') return true;
      if (category == 'دخترانه' || category == 'پسرانه') return theme['group'] == category;
      return true;
    }).toList();

    return Directionality(
      textDirection: iranaTextDirection,
      child: Scaffold(
        backgroundColor: const Color(0xFF241052),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF25005B), Color(0xFF6320A5), Color(0xFF190A49)],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF17003D), Color(0xFF5410A0), Color(0xFF230052)]),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFFFB7FF), width: 1.2),
                    boxShadow: const [BoxShadow(color: Color(0x887E22CE), blurRadius: 18)],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      ),
                      const Icon(Icons.palette_rounded, color: Color(0xFFFFD6FF), size: 27),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('تنظیمات ظاهر برنامه', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFFFD36A)), borderRadius: BorderRadius.circular(15)),
                        child: const Row(children: [
                          Text('نسخه ویژه', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Icon(Icons.workspace_premium, color: Color(0xFFFFD54F), size: 17),
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    categoryChip('همه طرح‌ها', Icons.star_rounded),
                    categoryChip('دخترانه', Icons.local_florist_rounded),
                    categoryChip('پسرانه', Icons.workspace_premium_rounded),
                    categoryChip('خاص و فانتزی', Icons.auto_awesome_rounded),
                    categoryChip('عکس دلخواه', Icons.photo_library_rounded),
                  ]),
                ),
                const SizedBox(height: 17),
                const Row(children: [
                  Icon(Icons.auto_awesome, color: Color(0xFFFFE27A), size: 19),
                  SizedBox(width: 7),
                  Text('پوسته‌های رایگان', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  height: 190,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: visibleThemes.map((theme) => themeCard(theme, premium: false)).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(children: [
                  Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD54F), size: 20),
                  SizedBox(width: 7),
                  Text('پوسته‌های ویژه و پولی', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                  Spacer(),
                  Text('قفل تا زمان خرید', style: TextStyle(color: Color(0xFFFFE39A), fontSize: 10)),
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  height: 190,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: premiumThemes.map((theme) => themeCard(theme, premium: true)).toList(),
                  ),
                ),
                const SizedBox(height: 17),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF210052), Color(0xFF4A0C8A)]),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFDFA7FF), width: 1.2),
                    boxShadow: const [BoxShadow(color: Color(0x667C20D9), blurRadius: 14)],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_library_rounded, color: Color(0xFFFFD6FF), size: 43),
                      const SizedBox(width: 12),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('عکس دلخواه خود را انتخاب کنید', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                        SizedBox(height: 5),
                        Text('پس‌زمینه صفحات را با عکس گالری گوشی شخصی‌سازی کنید؛ این امکان ویژه و پولی است.', style: TextStyle(color: Color(0xFFEAD8FF), fontSize: 11, height: 1.6)),
                      ])),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: showPurchaseNotice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A16EA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE9B8FF))),
                        ),
                        child: const Icon(Icons.lock_outline_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF35100D), Color(0xFF7B3D0A), Color(0xFF32100D)]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD45B), width: 1.4),
                  ),
                  child: Row(children: [
                    const Icon(Icons.workspace_premium, color: Color(0xFFFFD54F), size: 38),
                    const SizedBox(width: 10),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('ارتقا به نسخه ویژه', style: TextStyle(color: Color(0xFFFFE36D), fontWeight: FontWeight.w900, fontSize: 15)),
                      Text('دسترسی به همه طرح‌ها و امکانات بیشتر', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ])),
                    ElevatedButton.icon(
                      onPressed: showPurchaseNotice,
                      icon: const Icon(Icons.shopping_cart_rounded, size: 17),
                      label: const Text('خرید اشتراک', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC928), foregroundColor: const Color(0xFF482000), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    ),
                  ]),
                ),
                const SizedBox(height: 15),
                Center(
                  child: TextButton.icon(
                    onPressed: () => selectFreeTheme('پیش‌فرض ایرانا'),
                    icon: const Icon(Icons.restart_alt_rounded, color: Colors.white),
                    label: const Text('بازگشت به ظاهر پیش‌فرض برنامه', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(backgroundColor: const Color(0x44FFFFFF), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: const StadiumBorder()),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'خرید پوسته‌ها و فعال‌سازی انتخاب عکس گالری پس از اتصال درگاه پرداخت و سرور انجام می‌شود.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFDCCBFA), fontSize: 10, height: 1.6),
                ),
              ],
            ),
          ),
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
  String selectedOption = 'فارسی';
  final TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedOption = switch (iranaLocale.value.languageCode) {
      'en' => 'English',
      'ar' => 'العربية',
      _ => 'فارسی',
    };
  }

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
                  onPressed: () async {
                    final languageCode = switch (selectedOption) {
                      'English' => 'en',
                      'العربية' => 'ar',
                      _ => 'fa',
                    };
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('irana_language', languageCode);
                    iranaLocale.value = Locale(languageCode);
                    if (!mounted) return;
                    final message = switch (languageCode) {
                      'en' => 'Language preference saved.',
                      'ar' => 'تم حفظ اختيار اللغة.',
                      _ => 'زبان انتخابی ذخیره شد.',
                    };
                    showMessage(message);
                    setState(() {});
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

// ---------------- LIVE STREAM ----------------

class IranaLivePage extends StatefulWidget {
  const IranaLivePage({super.key});

  @override
  State<IranaLivePage> createState() => _IranaLivePageState();
}

class _IranaLivePageState extends State<IranaLivePage> {
  final TextEditingController commentController = TextEditingController();
  final TextEditingController inviteController = TextEditingController();
  final List<String> comments = [];
  final List<String> invitedViewers = [];
  int likes = 0;
  bool participationRequested = false;

  @override
  void dispose() {
    commentController.dispose();
    inviteController.dispose();
    super.dispose();
  }

  void showServerNotice(String title) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: const Text(
          'این بخش در نسخه فعلی نمایشی است. ارسال و دریافت زنده اطلاعات، شمارش آنلاین بینندگان و ارتباط تصویری پس از اتصال سرور فعال می‌شود.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }

  void sendComment() {
    final value = commentController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      comments.insert(0, 'شما: $value');
      commentController.clear();
    });
  }

  Future<void> addViewer() async {
    inviteController.clear();
    final username = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('افزودن بیننده به لایو'),
          content: TextField(
            controller: inviteController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'نام کاربری یا آیدی بیننده',
              hintText: 'مثلاً user123',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                inviteController.text.trim().replaceFirst(RegExp(r'^@'), ''),
              ),
              child: const Text('افزودن'),
            ),
          ],
        ),
      ),
    );
    if (username == null || username.isEmpty || !mounted) return;
    setState(() {
      if (!invitedViewers.contains(username)) invitedViewers.add(username);
    });
    showServerNotice('دعوت بیننده');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF17131D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF24202B),
          foregroundColor: Colors.white,
          title: const Text('پخش زنده IRANA'),
          actions: [
            IconButton(
              tooltip: 'آمار بینندگان آنلاین',
              onPressed: () => showServerNotice('آمار بینندگان آنلاین'),
              icon: const Icon(Icons.people_alt_outlined),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF332B3D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.live_tv_rounded, color: Colors.white70, size: 74),
                          SizedBox(height: 12),
                          Text('محیط تصویر پخش زنده', style: TextStyle(color: Colors.white, fontSize: 17)),
                          SizedBox(height: 6),
                          Text('تصویر زنده پس از اتصال سرویس پخش فعال می‌شود', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                        child: const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          children: [
                            Icon(Icons.visibility, color: Colors.white, size: 16),
                            SizedBox(width: 5),
                            Text('۰ آنلاین', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'لایک',
                  onPressed: () => setState(() => likes++),
                  icon: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 30),
                ),
                Text('$likes', style: const TextStyle(color: Colors.white)),
                IconButton(
                  tooltip: 'درخواست مشارکت در لایو',
                  onPressed: () {
                    setState(() => participationRequested = true);
                    showServerNotice('درخواست مشارکت در لایو');
                  },
                  icon: Icon(
                    participationRequested ? Icons.hourglass_top : Icons.video_call,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
                const Text('درخواست مشارکت', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF24202B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('گفت‌وگوی بینندگان', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Expanded(
                      child: comments.isEmpty
                          ? const Center(child: Text('هنوز کامنتی ثبت نشده است', style: TextStyle(color: Colors.white54)))
                          : ListView(
                              children: comments.map((comment) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(comment, style: const TextStyle(color: Colors.white70)),
                              )).toList(),
                            ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'کامنت بنویسید...',
                              hintStyle: TextStyle(color: Colors.white54),
                              isDense: true,
                            ),
                            onSubmitted: (_) => sendComment(),
                          ),
                        ),
                        IconButton(
                          onPressed: sendComment,
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: ExpansionTile(
                collapsedTextColor: Colors.white,
                textColor: Colors.white,
                iconColor: Colors.white,
                collapsedIconColor: Colors.white,
                title: const Text('ابزار منتشرکننده: مدیریت مشارکت‌کنندگان'),
                children: [
                  ListTile(
                    textColor: Colors.white,
                    leading: const Icon(Icons.person_add_alt_1, color: Colors.white),
                    title: const Text('افزودن اختیاری هر بیننده به لایو'),
                    onTap: addViewer,
                  ),
                  if (invitedViewers.isNotEmpty)
                    ...invitedViewers.map((name) => ListTile(
                      dense: true,
                      textColor: Colors.white70,
                      leading: const Icon(Icons.person, color: Colors.white70),
                      title: Text('@$name'),
                      trailing: IconButton(
                        tooltip: 'حذف از فهرست',
                        onPressed: () => setState(() => invitedViewers.remove(name)),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    )),
                  ListTile(
                    textColor: Colors.white,
                    leading: const Icon(Icons.check_circle_outline, color: Colors.white),
                    title: const Text('بررسی و پذیرش درخواست‌های مشارکت'),
                    onTap: () => showServerNotice('درخواست‌های مشارکت'),
                  ),
                ],
              ),
            ),
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          actionItem(
                            icon: Icons.live_tv_rounded,
                            title: 'پخش زنده',
                            color: Colors.redAccent,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const IranaLivePage(),
                              ),
                            ),
                          ),
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