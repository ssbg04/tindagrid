import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../storefront/storefront_settings_card.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(stringsProvider);
    final currentLang = ref.watch(languageProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final syncState = ref.watch(syncProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr.settingsTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Soft UI Theme Switcher Section (Light / Dark / System)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: SoftDecorations.card(context, radius: 16),
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
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.wb_sunny_rounded, size: 16),
                            const SizedBox(width: 6),
                            Text(tr.themeLight, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.nightlight_round, size: 16),
                            const SizedBox(width: 6),
                            Text(tr.themeDark, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.settings_suggest_rounded, size: 16),
                            const SizedBox(width: 6),
                            Text(tr.themeSystem, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Soft UI Language Switcher Section (Taglish / English)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: SoftDecorations.card(context, radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      tr.languageSection,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ref.read(languageProvider.notifier).setLanguage(AppLanguage.taglish);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🇵🇭 ', style: TextStyle(fontSize: 15)),
                            Text('Taglish', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          ref.read(languageProvider.notifier).setLanguage(AppLanguage.english);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🇺🇸 ', style: TextStyle(fontSize: 15)),
                            Text('English', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Soft UI Cloud Sync & Multi-Device Sync Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: SoftDecorations.card(context, radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_sync_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          tr.cloudBackupTitle,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                    // Online / Offline Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: syncState.isOnline
                            ? AppColors.primaryLight.withValues(alpha: 0.3)
                            : Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 4,
                            backgroundColor: syncState.isOnline ? AppColors.primary : Colors.amber.shade800,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            syncState.isOnline
                                ? (tr.isTaglish ? 'Online' : 'Online')
                                : (tr.isTaglish ? 'Offline (Ligtas)' : 'Offline (Safe)'),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: syncState.isOnline ? AppColors.primary : Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tr.cloudBackupSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Live Sync Status Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLight ? AppColors.backgroundLight : AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              tr.isTaglish ? 'Mga Bagong Benta (Naka-queue):' : 'Pending Local Changes:',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: syncState.pendingCount > 0
                                  ? Colors.amber.withValues(alpha: 0.2)
                                  : AppColors.primaryLight.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              syncState.pendingCount > 0
                                  ? '${syncState.pendingCount} ${tr.isTaglish ? "naghihintay" : "pending"}'
                                  : (tr.isTaglish ? '0 (Updated)' : '0 (Up to date)'),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: syncState.pendingCount > 0 ? Colors.amber.shade900 : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              tr.isTaglish ? 'Huling Na-sync:' : 'Last Cloud Sync:',
                              style: GoogleFonts.inter(fontSize: 12, color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            syncState.lastSyncedAt != null
                                ? '${syncState.lastSyncedAt!.hour.toString().padLeft(2, '0')}:${syncState.lastSyncedAt!.minute.toString().padLeft(2, '0')} (${syncState.lastSyncedAt!.month}/${syncState.lastSyncedAt!.day})'
                                : (tr.isTaglish ? 'Hindi pa' : 'Not yet'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons: Sync Now & Disaster Recovery
                Row(
                  children: [
                    // Manual "Sync Now" Button
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: syncState.isSyncing
                            ? null
                            : () async {
                                final scaffold = ScaffoldMessenger.of(context);
                                try {
                                  final success = await ref.read(syncProvider.notifier).syncNow();
                                  scaffold.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? (tr.isTaglish ? '☁️ Matagumpay na nai-sync sa Neon Cloud!' : '☁️ Successfully synced with Neon Cloud!')
                                            : (tr.isTaglish ? 'Naka-offline. Ligtas ang benta sa lokal database.' : 'Offline. Sales safely preserved locally.'),
                                      ),
                                      backgroundColor: success ? AppColors.primary : Colors.amber.shade800,
                                    ),
                                  );
                                } catch (e) {
                                  scaffold.showSnackBar(
                                    SnackBar(
                                      content: Text('Sync Error: $e'),
                                      backgroundColor: Colors.red.shade700,
                                    ),
                                  );
                                }
                              },
                        icon: syncState.isSyncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.sync_rounded, size: 18),
                        label: Text(
                          syncState.isSyncing
                              ? (tr.isTaglish ? 'Nagsi-sync...' : 'Syncing...')
                              : tr.syncNowButton,
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Disaster Recovery / Restore from Cloud Button
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: syncState.isRestoring
                            ? null
                            : () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Row(
                                      children: [
                                        const Icon(Icons.settings_backup_restore_rounded, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          tr.isTaglish ? 'Disaster Recovery' : 'Disaster Recovery',
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      tr.isTaglish
                                          ? 'I-restore ang buong tindahan mula sa Neon Cloud?\n\nBabawiin ang lahat ng produkto, utang, at mga talaan mula sa backup. Tamang-tama ito kung bago ang iyong cellphone o nag-log in ka sa laptop.'
                                          : 'Restore entire store catalog and ledgers from Neon Cloud?\n\nThis will rehydrate your products, debts, and sales from the cloud backup. Ideal when logging in on a secondary device or replacement phone.',
                                      style: GoogleFonts.inter(fontSize: 13),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: Text(tr.isTaglish ? 'Kanselahin' : 'Cancel'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                        ),
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        child: Text(
                                          tr.isTaglish ? 'I-restore Ngayon' : 'Restore Now',
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true && context.mounted) {
                                  final scaffold = ScaffoldMessenger.of(context);
                                  try {
                                    final counts = await ref.read(syncProvider.notifier).restoreFromCloud();
                                    scaffold.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          tr.isTaglish
                                              ? '✅ Naibalik mula sa cloud: ${counts["products"] ?? 0} paninda, ${counts["debts"] ?? 0} utang!'
                                              : '✅ Successfully restored: ${counts["products"] ?? 0} products, ${counts["debts"] ?? 0} debts!',
                                        ),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  } catch (e) {
                                    scaffold.showSnackBar(
                                      SnackBar(
                                        content: Text('Disaster Recovery Error: $e'),
                                        backgroundColor: Colors.red.shade700,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: syncState.isRestoring
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.settings_backup_restore_rounded, size: 16),
                        label: Text(
                          tr.isTaglish ? 'I-restore' : 'Restore',
                          style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Public Web Storefront Card (Cloudflare Pages)
          const StorefrontSettingsCard(),
          const SizedBox(height: 14),

          // Soft UI Security & PIN Card

          Container(
            decoration: SoftDecorations.card(context, radius: 16),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 18),
                ),
                title: Text(
                  tr.securitySection,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Text(
                  tr.isTaglish ? '4-6 digit Store PIN & Fingerprint' : '4-6 digit Store PIN & Biometrics',
                  style: GoogleFonts.inter(
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
          ),
          const SizedBox(height: 14),

          // Soft UI System Status & Architecture Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: SoftDecorations.card(context, radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      tr.aboutTindaGrid,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tr.systemStatusSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'SQLite Drift (Local) + Neon PostgreSQL (Cloud) + Cloudflare R2',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
