import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _purple = Color(0xFF7139A8);
const Color _pale = Color(0xFFEDE2F7);

class IranaChatPage extends StatefulWidget {
  final String? username;
  final bool isGroup;
  final String groupName;

  const IranaChatPage({
    super.key,
    this.username,
    this.isGroup = false,
    this.groupName = 'گروه دوستان',
  });

  @override
  State<IranaChatPage> createState() => _IranaChatPageState();
}

class _IranaChatPageState extends State<IranaChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  Timer? _expiryTimer;
  bool _loading = true;
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  int _defaultExpiryHours = 0;

  String get _chatId => widget.isGroup
      ? 'irana_group_${widget.groupName}'
      : 'irana_dm_${widget.username ?? 'user'}';

  String get _title =>
      widget.isGroup ? widget.groupName : '@${widget.username ?? 'کاربر'}';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _expiryTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _removeExpiredMessages();
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chatId);
    final savedExpiry = prefs.getInt('${_chatId}_default_expiry') ?? 0;
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List;
        _messages
          ..clear()
          ..addAll(decoded.map((item) => Map<String, dynamic>.from(item as Map)));
      } catch (_) {
        _messages.clear();
      }
    }
    _defaultExpiryHours = savedExpiry;
    await _removeExpiredMessages();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chatId, jsonEncode(_messages));
  }

  Future<void> _removeExpiredMessages() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final before = _messages.length;
    _messages.removeWhere((message) {
      final expiry = message['expiresAt'];
      return expiry is int && expiry <= now;
    });
    if (_messages.length != before) {
      await _saveMessages();
      if (mounted) setState(() {});
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final now = DateTime.now();
    final expiry = _defaultExpiryHours > 0
        ? now.add(Duration(hours: _defaultExpiryHours)).millisecondsSinceEpoch
        : null;
    setState(() {
      _messages.add({
        'id': '${now.microsecondsSinceEpoch}_${_messages.length}',
        'text': text,
        'createdAt': now.millisecondsSinceEpoch,
        'expiresAt': expiry,
        'mine': true,
      });
    });
    _messageController.clear();
    await _saveMessages();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _setDefaultExpiry() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('زمان پیش‌فرض حذف پیام‌ها',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ),
            _expiryChoice(context, 'خاموش', 0),
            _expiryChoice(context, '۲۴ ساعت', 24),
            _expiryChoice(context, '۷ روز', 168),
            _expiryChoice(context, '۳۰ روز', 720),
            ListTile(
              leading: const Icon(Icons.event, color: _purple),
              title: const Text('تاریخ و ساعت دلخواه برای پیام بعدی'),
              onTap: () async {
                Navigator.pop(context, -1);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected == null) return;
    if (selected == -1) {
      await _sendNextMessageWithCustomExpiry();
      return;
    }
    setState(() => _defaultExpiryHours = selected);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_chatId}_default_expiry', selected);
  }

  Widget _expiryChoice(BuildContext context, String label, int hours) {
    return ListTile(
      leading: Icon(
        _defaultExpiryHours == hours
            ? Icons.radio_button_checked
            : Icons.radio_button_off,
        color: _purple,
      ),
      title: Text(label),
      onTap: () => Navigator.pop(context, hours),
    );
  }

  Future<void> _sendNextMessageWithCustomExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 24))),
    );
    if (time == null || !mounted) return;
    final expiry = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!expiry.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('زمان حذف باید در آینده باشد')),
      );
      return;
    }
    _pendingCustomExpiry = expiry.millisecondsSinceEpoch;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('زمان حذف برای پیام بعدی تنظیم شد')),
    );
  }

  int? _pendingCustomExpiry;

  Future<void> _setMessageExpiry(Map<String, dynamic> message) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(days: 1))),
    );
    if (time == null || !mounted) return;
    final expiry = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!expiry.isAfter(DateTime.now())) return;
    setState(() => message['expiresAt'] = expiry.millisecondsSinceEpoch);
    await _saveMessages();
  }

  Future<void> _deleteMessage(Map<String, dynamic> message, {required bool forEveryone}) async {
    final id = message['id'] as String;
    setState(() {
      _messages.removeWhere((item) => item['id'] == id);
      _selectedIds.remove(id);
      _selectionMode = _selectedIds.isNotEmpty;
    });
    await _saveMessages();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(forEveryone
            ? 'پیام از این دستگاه حذف شد؛ حذف برای همه پس از اتصال سرور فعال می‌شود.'
            : 'پیام از فهرست محلی شما حذف شد.'),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    setState(() {
      _messages.removeWhere((message) => _selectedIds.contains(message['id']));
      _selectedIds.clear();
      _selectionMode = false;
    });
    await _saveMessages();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      _selectionMode = _selectedIds.isNotEmpty;
    });
  }

  Future<void> _showMessageActions(Map<String, dynamic> message) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('مدیریت پیام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: _purple),
              title: const Text('تعیین تاریخ و ساعت حذف این پیام'),
              onTap: () => Navigator.pop(context, 'expiry'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('حذف برای من'),
              onTap: () => Navigator.pop(context, 'mine'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: const Text('حذف برای همه'),
              subtitle: const Text('پس از اتصال سرور برای همه کاربران همگام می‌شود'),
              onTap: () => Navigator.pop(context, 'everyone'),
            ),
            ListTile(
              leading: const Icon(Icons.checklist, color: _purple),
              title: const Text('انتخاب چند پیام'),
              onTap: () => Navigator.pop(context, 'select'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'expiry') await _setMessageExpiry(message);
    if (choice == 'mine') await _deleteMessage(message, forEveryone: false);
    if (choice == 'everyone') await _deleteMessage(message, forEveryone: true);
    if (choice == 'select') _toggleSelection(message['id'] as String);
  }

  String _timeLabel(Map<String, dynamic> message) {
    final expiry = message['expiresAt'];
    if (expiry is! int) return '';
    final remaining = DateTime.fromMillisecondsSinceEpoch(expiry).difference(DateTime.now());
    if (remaining.inDays > 0) return 'حذف تا ${remaining.inDays} روز دیگر';
    if (remaining.inHours > 0) return 'حذف تا ${remaining.inHours} ساعت دیگر';
    return 'حذف زمان‌دار';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F5FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _purple,
          elevation: 0,
          leading: _selectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _selectedIds.clear();
                    _selectionMode = false;
                  }),
                )
              : null,
          title: _selectionMode
              ? Text('${_selectedIds.length} پیام انتخاب شد')
              : Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _pale,
                      child: Icon(widget.isGroup ? Icons.groups : Icons.person, color: _purple),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(_title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
          actions: [
            if (_selectionMode)
              IconButton(
                tooltip: 'حذف پیام‌های انتخاب‌شده',
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              )
            else ...[
              IconButton(
                tooltip: 'تنظیم پیام‌های زمان‌دار',
                onPressed: _setDefaultExpiry,
                icon: const Icon(Icons.timer_outlined),
              ),
              if (widget.isGroup)
                IconButton(
                  tooltip: 'تنظیمات گروه',
                  onPressed: _setDefaultExpiry,
                  icon: const Icon(Icons.settings_outlined),
                ),
            ],
          ],
        ),
        body: Column(
          children: [
            if (_defaultExpiryHours > 0)
              Container(
                width: double.infinity,
                color: _pale,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  'حذف خودکار پیام‌های جدید: ${_defaultExpiryHours == 24 ? '۲۴ ساعت' : _defaultExpiryHours == 168 ? '۷ روز' : '۳۰ روز'}',
                  style: const TextStyle(color: _purple, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _purple))
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(widget.isGroup ? Icons.groups_2_outlined : Icons.forum_outlined, size: 58, color: _purple.withOpacity(.45)),
                              const SizedBox(height: 12),
                              const Text('هنوز پیامی وجود ندارد', style: TextStyle(color: Colors.black54)),
                              const SizedBox(height: 5),
                              const Text('اولین پیام را بنویسید', style: TextStyle(color: Colors.black38, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(14),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final mine = message['mine'] == true;
                            final id = message['id'] as String;
                            final selected = _selectedIds.contains(id);
                            final expiryLabel = _timeLabel(message);
                            return Align(
                              alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
                              child: GestureDetector(
                                onLongPress: () {
                                  if (_selectionMode) {
                                    _toggleSelection(id);
                                  } else {
                                    _showMessageActions(message);
                                  }
                                },
                                onTap: _selectionMode ? () => _toggleSelection(id) : null,
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 310),
                                  margin: const EdgeInsets.symmetric(vertical: 5),
                                  padding: const EdgeInsets.fromLTRB(13, 10, 13, 8),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFFD8C3ED)
                                        : mine ? const Color(0xFFEDE2F7) : Colors.white,
                                    borderRadius: BorderRadius.circular(17),
                                    border: selected ? Border.all(color: _purple, width: 1.5) : null,
                                    boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 5, offset: Offset(0, 2))],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(message['text'] as String, style: const TextStyle(fontSize: 15, height: 1.45)),
                                      const SizedBox(height: 5),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (expiryLabel.isNotEmpty) ...[
                                            const Icon(Icons.timer_outlined, size: 12, color: _purple),
                                            const SizedBox(width: 3),
                                            Text(expiryLabel, style: const TextStyle(fontSize: 10, color: _purple)),
                                            const SizedBox(width: 6),
                                          ],
                                          Text(
                                            TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(message['createdAt'] as int)).format(context),
                                            style: const TextStyle(fontSize: 10, color: Colors.black45),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'پیام بنویسید...',
                          filled: true,
                          fillColor: const Color(0xFFF5F1F8),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: _purple,
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 5),
              child: Text('نسخه آزمایشی محلی؛ همگام‌سازی و حذف برای همه پس از اتصال سرور', style: TextStyle(fontSize: 10, color: Colors.black38)),
            ),
          ],
        ),
      ),
    );
  }
}
