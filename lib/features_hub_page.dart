import 'chat_page.dart';
import 'package:flutter/material.dart';

const Color _iranaPurple = Color(0xFF7B3FB3);
const Color _iranaPink = Color(0xFFE84A9B);
const Color _iranaBg = Color(0xFFF8F5FC);

class IranaFeatureInfo {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<String> items;

  const IranaFeatureInfo({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.items,
  });
}

const List<IranaFeatureInfo> _iranaFeatures = [
  IranaFeatureInfo(
    title: 'چت گروهی',
    subtitle: 'گفت‌وگو در گروه‌ها',
    description: 'ساخت گروه، تعیین نام و تصویر، مدیریت اعضا و گفت‌وگوی گروهی.',
    icon: Icons.groups_rounded,
    items: ['ساخت گروه جدید', 'مدیریت اعضا و مدیران', 'پیام متنی و رسانه', 'تنظیمات و حریم خصوصی گروه'],
  ),
  IranaFeatureInfo(
    title: 'تماس صوتی',
    subtitle: 'ارتباط صوتی با کاربران',
    description: 'تماس صوتی خصوصی و گروهی همراه با صفحه تماس و کنترل‌های تماس.',
    icon: Icons.call_rounded,
    items: ['تماس صوتی خصوصی', 'تماس صوتی گروهی', 'بی‌صدا کردن میکروفون', 'تاریخچه تماس‌ها'],
  ),
  IranaFeatureInfo(
    title: 'تماس تصویری',
    subtitle: 'تماس تصویری خصوصی و گروهی',
    description: 'تماس تصویری با امکان مدیریت دوربین، میکروفون و شرکت‌کنندگان.',
    icon: Icons.video_call_rounded,
    items: ['تماس تصویری خصوصی', 'تماس تصویری گروهی', 'روشن و خاموش کردن دوربین', 'مدیریت شرکت‌کنندگان'],
  ),
  IranaFeatureInfo(
    title: 'کانال اطلاع‌رسانی',
    subtitle: 'انتشار خبر و اطلاعیه',
    description: 'ساخت کانال عمومی یا خصوصی و انتشار پیام برای دنبال‌کنندگان کانال.',
    icon: Icons.campaign_rounded,
    items: ['ساخت کانال', 'کانال عمومی یا خصوصی', 'مدیریت مدیران کانال', 'ارسال اطلاعیه و رسانه'],
  ),
  IranaFeatureInfo(
    title: 'ابزار کسب‌وکار',
    subtitle: 'امکانات حرفه‌ای برای فروشندگان',
    description: 'معرفی کسب‌وکار، راه‌های ارتباطی، محصولات و ابزارهای ارتباط با مشتری.',
    icon: Icons.storefront_rounded,
    items: ['پروفایل حرفه‌ای کسب‌وکار', 'معرفی محصولات و خدمات', 'راه‌های تماس و نشانی', 'مدیریت درخواست‌های مشتریان'],
  ),
  IranaFeatureInfo(
    title: 'آمار حرفه‌ای بازدید',
    subtitle: 'تحلیل عملکرد محتوا و صفحه',
    description: 'نمایش آمار بازدید، تعامل، رشد دنبال‌کنندگان و عملکرد محتوا.',
    icon: Icons.analytics_rounded,
    items: ['بازدید پست‌ها و ویدئوها', 'میزان پسندیدن و نظرها', 'رشد دنبال‌کنندگان', 'گزارش بازه‌های زمانی'],
  ),
];

class IranaFeaturesHubPage extends StatelessWidget {
  const IranaFeaturesHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _iranaBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _iranaPurple,
          elevation: 0,
          title: const Text('امکانات IRANA', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_iranaPurple, _iranaPink],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('امکانات جدید ایرانا', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 7),
                  Text('شش قابلیت در این بخش؛ پخش زنده از منوی ساخت استوری در دسترس است. اتصال سرور در مرحله پایانی انجام می‌شود.', style: TextStyle(color: Colors.white, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _iranaFeatures.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 11,
                mainAxisSpacing: 11,
                childAspectRatio: 1.02,
              ),
              itemBuilder: (context, index) {
                final feature = _iranaFeatures[index];
                return _FeatureCard(
                  feature: feature,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => feature.title == 'چت گروهی'
                          ? const IranaChatPage(isGroup: true, groupName: 'گروه دوستان')
                          : IranaFeaturePage(feature: feature),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: _iranaPurple),
                  SizedBox(width: 9),
                  Expanded(child: Text('این مرحله شامل صفحه‌ها و آماده‌سازی رابط کاربری است. امکانات آنلاین و ارتباط واقعی پس از راه‌اندازی سرور فعال می‌شوند.', style: TextStyle(height: 1.5))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IranaFeatureInfo feature;
  final VoidCallback onTap;

  const _FeatureCard({required this.feature, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E7F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(feature.icon, color: _iranaPurple, size: 29),
              ),
              const SizedBox(height: 10),
              Text(feature.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 5),
              Text(feature.subtitle, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, fontSize: 11, height: 1.35)),
            ],
          ),
        ),
      ),
    );
  }
}

class IranaFeaturePage extends StatelessWidget {
  final IranaFeatureInfo feature;

  const IranaFeaturePage({super.key, required this.feature});

  void _showServerNotice(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('در مرحله اتصال سرور'),
        content: Text('بخش «${feature.title}» آماده‌سازی شده است. اجرای واقعی و اتصال کاربران پس از تکمیل سرور فعال خواهد شد.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('متوجه شدم')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _iranaBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _iranaPurple,
          elevation: 0,
          title: Text(feature.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_iranaPurple, _iranaPink]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(feature.icon, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(feature.title, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(feature.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('امکانات این بخش', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _iranaPurple)),
            const SizedBox(height: 8),
            ...feature.items.map((item) => Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              child: ListTile(
                leading: const Icon(Icons.check_circle_outline, color: _iranaPurple),
                title: Text(item, style: const TextStyle(fontSize: 14)),
                trailing: const Icon(Icons.lock_outline, color: Colors.black38, size: 19),
              ),
            )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showServerNotice(context),
                icon: const Icon(Icons.construction_outlined),
                label: const Text('وضعیت و فعال‌سازی قابلیت'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _iranaPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('وضعیت: رابط کاربری آماده‌سازی شده؛ اتصال و داده‌های واقعی در مرحله پایانی سرور.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
