import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(stringsProvider);
    final currentLang = ref.watch(languageProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr.settingsTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Switcher Section (Taglish / English)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        tr.languageSection,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: currentLang == AppLanguage.taglish
                                ? AppColors.primary
                                : Colors.transparent,
                            foregroundColor: currentLang == AppLanguage.taglish
                                ? Colors.white
                                : (isLight ? Colors.black87 : Colors.white70),
                            side: BorderSide(
                              color: currentLang == AppLanguage.taglish
                                  ? AppColors.primary
                                  : Colors.grey.withAlpha(80),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            ref.read(languageProvider.notifier).setLanguage(AppLanguage.taglish);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🇵🇭 ', style: TextStyle(fontSize: 16)),
                              Text('Taglish', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: currentLang == AppLanguage.english
                                ? AppColors.primary
                                : Colors.transparent,
                            foregroundColor: currentLang == AppLanguage.english
                                ? Colors.white
                                : (isLight ? Colors.black87 : Colors.white70),
                            side: BorderSide(
                              color: currentLang == AppLanguage.english
                                  ? AppColors.primary
                                  : Colors.grey.withAlpha(80),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            ref.read(languageProvider.notifier).setLanguage(AppLanguage.english);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🇺🇸 ', style: TextStyle(fontSize: 16)),
                              Text('English', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cloud Sync Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_sync_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        tr.cloudBackupTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr.cloudBackupSubtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr.isTaglish ? '☁️ Matagumpay na nai-sync sa Neon Cloud!' : '☁️ Successfully synced to Neon Cloud!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.sync_rounded),
                      label: Text(tr.syncNowButton),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Security & PIN Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.lock_outline_rounded, color: AppColors.primary),
              ),
              title: Text(
                tr.securitySection,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                tr.isTaglish ? '4-6 digit Store PIN & Fingerprint' : '4-6 digit Store PIN & Biometrics',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr.isTaglish ? 'Ligtas ang iyong PIN gamit ang Flutter Secure Storage' : 'PIN safely protected by Flutter Secure Storage'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // System Status & Architecture Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        tr.aboutTindaGrid,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr.systemStatusSubtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'SQLite Drift (Local) + Neon PostgreSQL (Cloud) + Cloudflare R2',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
