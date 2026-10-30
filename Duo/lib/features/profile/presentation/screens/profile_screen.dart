import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/duo_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/duo_app_bar.dart';
import '../../../../core/widgets/bouncy_press.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../../../memories/presentation/providers/notes_provider.dart';
import '../../../together/presentation/providers/together_provider.dart';
import '../../../pairing/presentation/providers/pairing_provider.dart';
import '../../../prayer/presentation/providers/prayer_provider.dart';
import '../providers/subscription_provider.dart';
import 'premium_paywall_screen.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/duo_strings.dart';
import '../../../../core/localization/duo_formatters.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final pairingState = ref.watch(pairingProvider);
    final subState = ref.watch(subscriptionProvider);
    final prayerState = ref.watch(prayerProvider);
    final client = ref.watch(supabaseClientProvider);

    final currentUser = client.auth.currentUser;
    final myName = (currentUser?.userMetadata?['display_name'] as String?)?.trim().isNotEmpty == true
        ? currentUser!.userMetadata!['display_name'] as String
        : 'You';

    final partnerData = pairingState.partner;
    final partnerName = (partnerData?['display_name'] as String?)?.trim().isNotEmpty == true
        ? partnerData!['display_name'] as String
        : 'Partner';

    final spaceData = pairingState.space;
    final spaceCreatedAt = spaceData?['created_at'] != null
        ? DateTime.tryParse(spaceData!['created_at'].toString())
        : null;

    final formattedSince = spaceCreatedAt != null
        ? DuoFormatters.formatDate(spaceCreatedAt, locale)
        : (locale == 'bn' ? 'সম্প্রতি যুক্ত হয়েছেন' : 'Recently paired');

    final inviteCode = spaceData?['invite_code'] as String?;

    String themeSubtitle;
    switch (currentThemeMode) {
      case ThemeMode.light:
        themeSubtitle = locale == 'bn' ? 'লাইট মোড ☀️' : 'Light mode ☀️';
        break;
      case ThemeMode.dark:
        themeSubtitle = locale == 'bn' ? 'ডার্ক মোড 🌙' : 'Dark mode 🌙';
        break;
      case ThemeMode.system:
        themeSubtitle = locale == 'bn' ? 'সিস্টেম ডিফল্ট 🌓' : 'System default 🌓';
        break;
    }

    return Scaffold(
      appBar: DuoAppBar(
        title: DuoStrings.get('settings_title', locale),
        subtitle: DuoStrings.get('settings_sub', locale),
        actions: const [],
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
        children: [
          // 1. Couple Connection Card
          BouncyPress(
            semanticsLabel: '$myName & $partnerName Duo',
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAvatar(myName, '👨‍💻', isMe: true),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [DuoColors.primary, DuoColors.accent],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: DuoColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.favorite, color: Colors.white, size: 20),
                          ),
                        ),
                        _buildAvatar(partnerName, '👩‍🎨', isMe: false),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$myName & $partnerName’s Duo',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DuoStrings.get('connected_since', locale)} $formattedSince 💗',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (inviteCode != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: DuoColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DuoColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          'Space Code: ${DuoFormatters.formatNumber(inviteCode, locale)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: DuoColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Duo Premium Banner (Connected to subscriptionProvider)
          BouncyPress(
            semanticsLabel: subState.isPremium ? 'Duo Premium Active' : 'Upgrade to Duo Premium',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumPaywallScreen()),
              );
            },
            child: Card(
              color: isDark
                  ? (subState.isPremium ? const Color(0xFF1B2A20) : const Color(0xFF261D15))
                  : (subState.isPremium ? const Color(0xFFE8F5E9) : const Color(0xFFFFF7E6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: subState.isPremium
                      ? Colors.green.withValues(alpha: 0.4)
                      : DuoColors.accent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: subState.isPremium
                            ? Colors.green.withValues(alpha: 0.2)
                            : DuoColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        subState.isPremium ? '👑' : '💎',
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                subState.isPremium ? 'Duo Premium Active' : 'Upgrade to Duo Premium',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: subState.isPremium
                                      ? (isDark ? Colors.green[300] : Colors.green[800])
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: subState.isPremium ? Colors.green : DuoColors.accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  subState.isPremium ? 'SHARED' : 'PRO',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subState.isPremium
                                ? (subState.plan != null
                                    ? '${subState.plan!.toUpperCase()} plan unlocked for both partners'
                                    : 'All luxury features active for both of you')
                                : 'One subscription unlocks everything for both partners',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Preferences Section
          _buildSettingsSection(
            context,
            title: DuoStrings.get('preferences', locale),
            items: [
              _SettingsItem(
                icon: Icons.language_rounded,
                title: DuoStrings.get('language', locale),
                subtitle: locale == 'bn' ? 'বাংলা (Bengali)' : 'English (US)',
                onTap: () => _showLanguageDialog(context, ref, locale),
              ),
              _SettingsItem(
                icon: Icons.palette_outlined,
                title: DuoStrings.get('theme_appearance', locale),
                subtitle: themeSubtitle,
                onTap: () => _showThemeDialog(context, ref),
              ),
              _SettingsItem(
                icon: Icons.mosque_rounded,
                title: DuoStrings.get('prayer_tracking_title', locale),
                subtitle: DuoStrings.get('prayer_tracking_sub', locale),
                trailing: Switch.adaptive(
                  value: prayerState.isEnabled,
                  activeTrackColor: const Color(0xFF10B981),
                  onChanged: (val) {
                    ref.read(prayerProvider.notifier).toggleEnabled(val);
                  },
                ),
                onTap: () {
                  ref.read(prayerProvider.notifier).toggleEnabled(!prayerState.isEnabled);
                },
              ),
              _SettingsItem(
                icon: Icons.notifications_active_rounded,
                title: DuoStrings.get('notifications', locale),
                subtitle: locale == 'bn' ? 'দৈনিক প্রশ্ন ও চিঠি আসার সতর্কতা' : 'Daily check-in & letter delivery alerts',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(locale == 'bn' ? 'নোটিফিকেশন সক্রিয় আছে 🔔' : 'Notifications active for daily questions and partner letters 🔔'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Relationship & Privacy Section
          _buildSettingsSection(
            context,
            title: DuoStrings.get('relationship_privacy', locale),
            items: [
              _SettingsItem(
                icon: Icons.lock_outline_rounded,
                title: DuoStrings.get('private_encryption', locale),
                subtitle: locale == 'bn' ? 'সম্পূর্ণ এনক্রিপ্টেড ডাটাবেজ সুরক্ষায় সংরক্ষিত' : 'End-to-end isolated database partition',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(locale == 'bn' ? 'আপনার স্পেসের ডাটা রো-লেভেল সিকিউরিটি দ্বারা সুরক্ষিত 🔒' : 'Your space data is protected by Supabase Row-Level Security 🔒'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _SettingsItem(
                icon: Icons.download_rounded,
                title: DuoStrings.get('export_memories', locale),
                subtitle: locale == 'bn' ? 'সব চিঠি, বিশেষ দিন ও স্বপ্ন এক্সপোর্ট করুন' : 'Download all notes, dates & questions',
                onTap: () => _showExportDialog(context, ref, myName, partnerName),
              ),
              _SettingsItem(
                icon: Icons.link_off_rounded,
                title: DuoStrings.get('disconnect_duo', locale),
                subtitle: locale == 'bn' ? '$partnerName-এর সাথে সংযোগ বিচ্ছিন্ন করুন' : 'Unpair active space with $partnerName',
                isDestructive: true,
                onTap: () => _confirmDisconnect(context, ref, partnerName),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5. Account Sign Out
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.grey),
              title: Text(
                DuoStrings.get('sign_out', locale),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                currentUser?.email ?? 'Logged in',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              onTap: () => _handleSignOut(context, ref),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, String emoji, {required bool isMe}) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isMe
                  ? DuoColors.primary.withValues(alpha: 0.15)
                  : DuoColors.accent.withValues(alpha: 0.15),
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
            if (isMe)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: DuoColors.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Colors.grey,
            ),
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: items.map((item) {
              return ListTile(
                leading: Icon(
                  item.icon,
                  color: item.isDestructive ? Colors.redAccent : DuoColors.primary,
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: item.isDestructive ? Colors.redAccent : null,
                  ),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: item.trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                onTap: item.onTap,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Theme & Appearance 🌓'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('☀️', style: TextStyle(fontSize: 22)),
              title: const Text('Light Mode'),
              trailing: currentMode == ThemeMode.light ? const Icon(Icons.check, color: DuoColors.primary) : null,
              onTap: () {
                ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Text('🌙', style: TextStyle(fontSize: 22)),
              title: const Text('Dark Mode'),
              trailing: currentMode == ThemeMode.dark ? const Icon(Icons.check, color: DuoColors.primary) : null,
              onTap: () {
                ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              leading: const Text('🌓', style: TextStyle(fontSize: 22)),
              title: const Text('System Default'),
              trailing: currentMode == ThemeMode.system ? const Icon(Icons.check, color: DuoColors.primary) : null,
              onTap: () {
                ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, WidgetRef ref, String myName, String partnerName) {
    final notes = ref.read(notesProvider).notes;
    final countdowns = ref.read(togetherProvider).countdowns;
    final bucketItems = ref.read(togetherProvider).bucketItems;

    final buffer = StringBuffer();
    buffer.writeln('# 💖 Duo Couple Archive: $myName & $partnerName');
    buffer.writeln('Exported on: ${DateFormat('d MMMM yyyy, h:mm a').format(DateTime.now())}');
    buffer.writeln();
    buffer.writeln('## 💌 SecretNotes & Letters (${notes.length})');
    for (final n in notes) {
      buffer.writeln('- **${n['title'] ?? 'Note'}** (${n['created_at']})');
      buffer.writeln('  "${n['body'] ?? ''}"');
    }
    buffer.writeln();
    buffer.writeln('## ⏳ Milestones & Countdowns (${countdowns.length})');
    for (final c in countdowns) {
      buffer.writeln('- ${c['icon'] ?? '💍'} ${c['title']} (Target: ${c['target_date']})');
    }
    buffer.writeln();
    buffer.writeln('## 🌍 Shared Bucket List (${bucketItems.length})');
    for (final b in bucketItems) {
      final done = b['completed'] == true ? '[x]' : '[ ]';
      buffer.writeln('- $done ${b['title']} (${b['category'] ?? 'dream'})');
    }

    final exportText = buffer.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Couple Memories Archive 📦'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete archive of ${notes.length} notes, ${countdowns.length} milestones, and ${bucketItems.length} dreams.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    exportText,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: DuoColors.primary),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: exportText));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Romantic archive copied to clipboard! 📋✨'),
                  backgroundColor: Color(0xFF1B3B2B),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, String currentLocale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          currentLocale == 'bn' ? 'ভাষা নির্বাচন' : 'Choose Language',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
              title: const Text('English (US)'),
              trailing: currentLocale == 'en' ? const Icon(Icons.check_circle_rounded, color: DuoColors.primary) : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale('en');
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Language set to English (US) 🇺🇸'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Text('🇧🇩', style: TextStyle(fontSize: 22)),
              title: const Text('বাংলা (Bengali)'),
              subtitle: const Text('সম্পূর্ণ বাংলা অনুবাদ সহ'),
              trailing: currentLocale == 'bn' ? const Icon(Icons.check_circle_rounded, color: DuoColors.primary) : null,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale('bn');
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ভাষা বাংলায় পরিবর্তিত হয়েছে 🇧🇩'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDisconnect(BuildContext context, WidgetRef ref, String partnerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Duo Space?'),
        content: Text(
          'Are you sure you want to unpair from $partnerName? You will both be disconnected from this space and will need to generate a new invitation code to reconnect.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref.read(pairingProvider.notifier).disconnectDuo();
              if (context.mounted) {
                if (success) {
                  context.go('/pairing');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to disconnect space')),
                  );
                }
              }
            },
            child: const Text('Disconnect', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final client = ref.read(supabaseClientProvider);
    await client.auth.signOut();
    if (context.mounted) {
      context.go('/auth');
    }
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final Widget? trailing;
  final VoidCallback? onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    this.trailing,
    this.onTap,
  });
}
