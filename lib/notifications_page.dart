import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:irana/l10n/app_localizations.dart';

const Color _purple = Color(0xFF7139A8);
const Color _pink = Color(0xFFE84B91);

class IranaNotificationsPage extends StatefulWidget {
  const IranaNotificationsPage({super.key});

  @override
  State<IranaNotificationsPage> createState() => _IranaNotificationsPageState();
}

class _IranaNotificationsPageState extends State<IranaNotificationsPage> {
  int selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filters = [l10n.all, l10n.followingPeople, l10n.commentsFilter, l10n.followsFilter, l10n.mentionsFilter, l10n.verifiedFilter];
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(l10n.notifications, style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              tooltip: l10n.notificationSettings,
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
              title: Text(l10n.followRequests, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(l10n.viewNewRequests),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const IranaFollowRequestsPage(),
              )),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(l10n.featured, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ),
            _NoticeRow(
              icon: Icons.auto_awesome,
              color: _pink,
              title: l10n.welcomeToIrana,
              detail: l10n.notificationIntro,
              time: l10n.justNow,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(l10n.today, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ),
            _NoticeRow(
              icon: Icons.favorite,
              color: _pink,
              title: l10n.likesReactions,
              detail: l10n.likeNotice,
              time: l10n.sampleNotice,
            ),
            _NoticeRow(
              icon: Icons.chat_bubble,
              color: _purple,
              title: l10n.commentsReplies,
              detail: l10n.commentsNotice,
              time: l10n.sampleNotice,
            ),
            _NoticeRow(
              icon: Icons.person_add_alt_1,
              color: Colors.blue,
              title: l10n.newFollowers,
              detail: l10n.followersNotice,
              time: l10n.sampleNotice,
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                l10n.notificationsDemoInfo,
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

  _NoticeRow({
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
      textDirection: Directionality.of(context),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.followRequests)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 58, color: _purple),
                SizedBox(height: 14),
                Text(l10n.noFollowRequests, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                SizedBox(height: 8),
                Text(l10n.followRequestsInfo, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.7)),
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
      textDirection: Directionality.of(context),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9FC),
        appBar: AppBar(title: Text(l10n.notificationSettings), backgroundColor: Colors.white),
        body: ListView(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(l10n.generalSettings, style: TextStyle(color: _purple, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            _switch(l10n.pauseAll, l10n.pauseAllInfo, pauseAll, 'irana_notice_pause', (v) => pauseAll = v),
            _switch(l10n.sleepMode, l10n.sleepModeInfo, sleepMode, 'irana_notice_sleep', (v) => sleepMode = v),
            const Divider(),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(l10n.interactions, style: TextStyle(color: _purple, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            _switch(l10n.likes, l10n.likesInfo, likes, 'irana_notice_likes', (v) => likes = v),
            _switch(l10n.commentsReplies, '', comments, 'irana_notice_comments', (v) => comments = v),
            _switch(l10n.newFollowers, '', followers, 'irana_notice_followers', (v) => followers = v),
            _switch(l10n.messages, '', messages, 'irana_notice_messages', (v) => messages = v),
            _switch(l10n.mentionsTags, '', mentions, 'irana_notice_mentions', (v) => mentions = v),
            _switch(l10n.calls, '', calls, 'irana_notice_calls', (v) => calls = v),
            _switch(l10n.liveVideo, '', live, 'irana_notice_live', (v) => live = v),
            const Divider(),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(l10n.otherNotifications, style: TextStyle(color: _purple, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            _switch(l10n.iranaEmails, l10n.emailInfo, email, 'irana_notice_email', (v) => email = v),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                l10n.notificationSettingsInfo,
                style: TextStyle(color: Colors.grey, height: 1.7, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
