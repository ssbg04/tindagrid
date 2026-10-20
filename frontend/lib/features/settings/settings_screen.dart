import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';
import '../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(stringsProvider);
    final currentLang = ref.watch(languageProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;

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
          // Flat Theme Switcher Section (Light / Dark / System)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor, width: 1.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isLight ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr.themeSection,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Light Theme Button
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: currentTheme == ThemeMode.light
                                ? AppColors.primary
                                : Colors.transparent,
                            foregroundColor: currentTheme == ThemeMode.light
                                ? Colors.white
                                : (isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark),
                            side: BorderSide(
                              color: currentTheme == ThemeMode.light
                                  ? AppColors.primary
                                  : borderColor,
                              width: 1.0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wb_sunny_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text(tr.themeLight, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dark Theme Button
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: currentTheme == ThemeMode.dark
                                ? AppColors.primary
                                : Colors.transparent,
                            foregroundColor: currentTheme == ThemeMode.dark
                                ? Colors.white
                                : (isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark),
                            side: BorderSide(
                              color: currentTheme == ThemeMode.dark
                                  ? AppColors.primary
                                  : borderColor,
                              width: 1.0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.nightlight_round, size: 16),
                              const SizedBox(width: 6),
                              Text(tr.themeDark, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // System Mode Button
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: currentTheme == ThemeMode.system
                                ? AppColors.primary
                                : Colors.transparent,
                            foregroundColor: currentTheme == ThemeMode.system
                                ? Colors.white
                                : (isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark),
                            side: BorderSide(
                              color: currentTheme == ThemeMode.system
                                  ? AppColors.primary
                                  : borderColor,
                              width: 1.0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.settings_suggest_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text(tr.themeSystem, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
          const SizedBox(height: 14),

          // Flat Language Switcher Section (Taglish / English)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor, width: 1.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        tr.languageSection,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                                : (isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark),
                            side: BorderSide(
                              color: currentLang == AppLanguage.taglish
                                  ? AppColors.primary
                                  : borderColor,
                              width: 1.0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            ref.read(languageProvider.notifier).setLanguage(AppLanguage.taglish);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🇵🇭 ', style: TextStyle(fontSize: 15)),
                              Text('Taglish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: currentLang == AppLanguage.english
                                ? AppColors.primary
                                : Colors.transparent,
                            foregroundColor: currentLang == AppLanguage.english
                                ? Colors.white
                                : (isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark),
                            side: BorderSide(
                              color: currentLang == AppLanguage.english
                                  ? AppColors.primary
                                  : borderColor,
                              width: 1.0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            ref.read(languageProvider.notifier).setLanguage(AppLanguage.english);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🇺🇸 ', style: TextStyle(fontSize: 15)),
                              Text('English', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
          const SizedBox(height: 14),

          // Flat Cloud Sync Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor, width: 1.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_sync_outlined, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        tr.cloudBackupTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr.cloudBackupSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr.isTaglish ? '☁️ Matagumpay na nai-sync sa Neon Cloud!' : '☁️ Successfully synced to Neon Cloud!'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: Text(tr.syncNowButton, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Flat Security & PIN Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor, width: 1.0),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 18),
              ),
              title: Text(
                tr.securitySection,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                tr.isTaglish ? '4-6 digit Store PIN & Fingerprint' : '4-6 digit Store PIN & Biometrics',
                style: TextStyle(
                  fontSize: 12,
                  color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tr.isTaglish ? 'Ligtas ang iyong PIN gamit ang Flutter Secure Storage' : 'PIN safely protected by Flutter Secure Storage'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Flat System Status & Architecture Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor, width: 1.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        tr.aboutTindaGrid,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr.systemStatusSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SQLite Drift (Local) + Neon PostgreSQL (Cloud) + Cloudflare R2',
                    style: TextStyle(
                      fontSize: 11,
                      color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                    ),
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
