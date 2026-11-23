import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _purple = Color(0xFF7139A8);
const Color _pink = Color(0xFFE84B91);

class IranaNotificationsPage extends StatefulWidget {
  const IranaNotificationsPage({super.key});

  @override
  State<IranaNotificationsPage> createState() => _IranaNotificationsPageState();
}

class _IranaNotificationsPageState extends State<IranaNotificationsPage> {
  final List<String> filters = const [
    'همه',
    'افرادی که دنبال می‌کنید',
    'نظرها',
    'دنبال‌کردن‌ها',
    'نام‌بردن‌ها',
    'تأییدشده‌ها',
  ];
  int selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('اعلان‌ها', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              tooltip: 'تنظیمات اعلان‌ها',
              icon: const Icon(Icons.notifications_active_outlined, color: _purple),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const IranaNotificationSettingsPage(),
              )),
            ),
          ],
        ),
        body: ListView(
          children: [
            SizedBox(
              height: 54,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ChoiceChip(
                  label: Text(filters[index]),
                  selected: selectedFilter == index,
                  selectedColor: _purple.withOpacity(.13),
                  labelStyle: TextStyle(
                    color: selectedFilter == index ? _purple : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => selectedFilter = index),
                ),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF2E9FA),
                child: Icon(Icons.people_alt_outlined, color: _purple),
              ),
              title: const Text('درخواست‌های دنبال‌کردن', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('درخواست‌های جدید را اینجا ببین'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const IranaFollowRequestsPage(),
              )),
            ),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text('ویژه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ),
            const _NoticeRow(
              icon: Icons.auto_awesome,
              color: _pink,
              title: 'به ایرانا خوش آمدی',
              detail: 'از اینجا می‌توانی اعلان‌ها و فعالیت‌های حساب خود را دنبال کنی.',
              time: 'همین حالا',
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text('امروز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ),
            const _NoticeRow(
              icon: Icons.favorite,
              color: _pink,
              title: 'پسندها و واکنش‌ها',
              detail: 'وقتی کسی پستت را بپسندد، اعلان آن در این بخش نمایش داده می‌شود.',
              time: 'اعلان نمونه',
            ),
            const _NoticeRow(
              icon: Icons.chat_bubble,
              color: _purple,
              title: 'نظرها و پاسخ‌ها',
              detail: 'نظرها و پاسخ‌های مربوط به پست‌هایت اینجا نمایش داده می‌شوند.',
              time: 'اعلان نمونه',
            ),
            const _NoticeRow(
              icon: Icons.person_add_alt_1,
              color: Colors.blue,
              title: 'دنبال‌کننده‌های جدید',
              detail: 'فعالیت دنبال‌کردن کاربران در این قسمت قرار می‌گیرد.',
              time: 'اعلان نمونه',
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'این صفحه فعلاً رابط کاربری اعلان‌هاست. برای دریافت اعلان واقعی از کاربران دیگر و اعلان روی گوشی، اتصال سرور و سرویس اعلان لازم است.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.7, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String time;

  const _NoticeRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: CircleAvatar(
        radius: 23,
        backgroundColor: color.withOpacity(.12),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(detail, style: const TextStyle(height: 1.5)),
      ),
      trailing: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
    );
  }
}

class IranaFollowRequestsPage extends StatelessWidget {
  const IranaFollowRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('درخواست‌های دنبال‌کردن')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 58, color: _purple),
                SizedBox(height: 14),
                Text('درخواستی وجود ندارد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                SizedBox(height: 8),
                Text('وقتی کاربری درخواست دنبال‌کردن بفرستد، اینجا نمایش داده می‌شود.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IranaNotificationSettingsPage extends StatefulWidget {
  const IranaNotificationSettingsPage({super.key});

  @override
  State<IranaNotificationSettingsPage> createState() => _IranaNotificationSettingsPageState();
}

class _IranaNotificationSettingsPageState extends State<IranaNotificationSettingsPage> {
  bool pauseAll = false;
  bool sleepMode = false;
  bool likes = true;
  bool comments = true;
  bool followers = true;
  bool messages = true;
  bool mentions = true;
  bool calls = true;
  bool live = true;
  bool email = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      pauseAll = p.getBool('irana_notice_pause') ?? false;
      sleepMode = p.getBool('irana_notice_sleep') ?? false;
      likes = p.getBool('irana_notice_likes') ?? true;
      comments = p.getBool('irana_notice_comments') ?? true;
      followers = p.getBool('irana_notice_followers') ?? true;
      messages = p.getBool('irana_notice_messages') ?? true;
      mentions = p.getBool('irana_notice_mentions') ?? true;
      calls = p.getBool('irana_notice_calls') ?? true;
      live = p.getBool('irana_notice_live') ?? true;
      email = p.getBool('irana_notice_email') ?? false;
    });
  }

  Future<void> _save(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  Widget _switch(String title, String subtitle, bool value, String key, ValueChanged<bool> update) {
    return SwitchListTile(
      activeColor: _purple,
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      value: value,
      onChanged: (v) {
        setState(() => update(v));
        _save(key, v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9FC),
        appBar: AppBar(title: const Text('تنظیمات اعلان‌ها'), backgroundColor: Colors.white),
        body: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('تنظیمات کلی', style: TextStyle(color: _purple, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            _switch('توقف موقت همه اعلان‌ها', 'همه اعلان‌ها را موقتاً بی‌صدا کن', pauseAll, 'irana_notice_pause', (v) => pauseAll = v),
            _switch('حالت خواب', 'اعلان‌ها در زمان استراحت متوقف شوند', sleepMode, 'irana_notice_sleep', (v) => sleepMode = v),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('تعاملات', style: TextStyle(color: _purple, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            _switch('پسندها', 'پسندیدن پست‌ها و واکنش‌ها', likes, 'irana_notice_likes', (v) => likes = v),
            _switch('نظرها و پاسخ‌ها', '', comments, 'irana_notice_comments', (v) => comments = v),
            _switch('دنبال‌کننده‌های جدید', '', followers, 'irana_notice_followers', (v) => followers = v),
            _switch('پیام‌ها', '', messages, 'irana_notice_messages', (v) => messages = v),
            _switch('نام‌بردن‌ها و برچسب‌ها', '', mentions, 'irana_notice_mentions', (v) => mentions = v),
            _switch('تماس‌ها', '', calls, 'irana_notice_calls', (v) => calls = v),
            _switch('پخش زنده و ویدئو', '', live, 'irana_notice_live', (v) => live = v),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('سایر اعلان‌ها', style: TextStyle(color: _purple, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            _switch('ایمیل‌های ایرانا', 'دریافت خبرها و پیشنهادها از طریق ایمیل', email, 'irana_notice_email', (v) => email = v),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'این تنظیمات فعلاً روی همین دستگاه ذخیره می‌شوند و ظاهر و ترجیح انتخابی را نگه می‌دارند. فعال‌سازی اعلان سیستمی و ارسال از سرور در مرحله اتصال زیرساخت انجام می‌شود.',
                style: TextStyle(color: Colors.grey, height: 1.7, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
