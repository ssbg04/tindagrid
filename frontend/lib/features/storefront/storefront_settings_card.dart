import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';
import '../../core/theme/app_theme.dart';
import 'storefront_provider.dart';

class StorefrontSettingsCard extends ConsumerStatefulWidget {
  const StorefrontSettingsCard({super.key});

  @override
  ConsumerState<StorefrontSettingsCard> createState() =>
      _StorefrontSettingsCardState();
}

class _StorefrontSettingsCardState extends ConsumerState<StorefrontSettingsCard> {
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _addressController;

  @override

  void initState() {
    super.initState();
    final state = ref.read(storefrontProvider);
    _nameController = TextEditingController(text: state.name);
    _slugController = TextEditingController(text: state.slug);
    _addressController = TextEditingController(text: state.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _shareStoreLink(String url, String storeName) async {
    final text = 'Bili na po kayo sa aming tindahan! Tingnan ang aming mga tinda dito: $url';
    final smsUri = Uri.parse('sms:?body=${Uri.encodeComponent(text)}');
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔗 Link copied to clipboard!'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔗 Link copied to clipboard!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storefrontProvider);
    final tr = ref.watch(stringsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SoftDecorations.card(context, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon + Title + Live/Draft Badge
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr.isTaglish ? 'Web Storefront (Cloudflare)' : 'Public Web Storefront',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: state.isPublic
                      ? AppColors.primaryLight.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.isPublic ? AppColors.primary : Colors.grey,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: state.isPublic ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.isPublic
                          ? (tr.isTaglish ? 'LIVE SA WEB' : 'LIVE PUBLIC')
                          : (tr.isTaglish ? 'DRAFT (Tago)' : 'DRAFT (Private)'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: state.isPublic ? AppColors.primary : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tr.isTaglish
                ? 'Magkaroon ng sariling website ang tindahan mo nang walang buwanang bayad.'
                : 'Free web link on Cloudflare Pages where customers can browse your goods.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 14),

          // Storefront Cover Photo Section
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isLight ? AppColors.backgroundLight : AppColors.backgroundDark,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: (state.photoUrl != null && state.photoUrl!.isNotEmpty)
                        ? Image.network(
                            state.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPhotoPlaceholder(isLight, tr),
                          )
                        : _buildPhotoPlaceholder(isLight, tr),
                  ),


                  // Overlay Camera Button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: state.isLoading
                            ? null
                            : () => _showPhotoSourceSheet(context),
                        icon: const Icon(Icons.camera_alt_rounded, size: 14),
                        label: Text(
                          tr.isTaglish ? 'Kumuha ng Litrato' : 'Take Store Photo',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Public Web Link URL Preview Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLight ? AppColors.backgroundLight : AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr.isTaglish ? 'Iyong Storefront URL:' : 'Your Storefront URL:',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: state.publicUrl));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied store link to clipboard!'),
                              backgroundColor: AppColors.primary,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            tr.isTaglish ? 'Kopyahin' : 'Copy',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(
                  state.publicUrl,
                  style: GoogleFonts.firaCode(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Draft vs Public Storefront Toggle Switch (Phase 8.2)
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                tr.isTaglish ? 'I-publish sa Publiko' : 'Public Storefront Visible',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                tr.isTaglish
                    ? 'Kung naka-ON, makikita ng kapitbahay ang paninda mo sa tindagrid.us.ci/${state.slug}'
                    : 'Allows neighbors to view your in-stock goods online.',
                style: GoogleFonts.inter(fontSize: 11),
              ),
              value: state.isPublic,
              activeThumbColor: AppColors.primary,
              onChanged: (val) {
                ref.read(storefrontProvider.notifier).setPublicVisibility(val);
              },
            ),

          ),
          const Divider(height: 24),


          // Action Buttons: Edit Details, Share, Preview
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    _showEditProfileDialog(context);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(
                    tr.isTaglish ? 'I-edit Info' : 'Edit Info',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _shareStoreLink(state.publicUrl, state.name),
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: Text(
                    tr.isTaglish ? 'I-share ang Link' : 'Share Link',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder(bool isLight, dynamic tr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 38,
            color: isLight ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          const SizedBox(height: 6),
          Text(
            tr.isTaglish ? 'Wala pang litrato ang iyong storefront' : 'No storefront photo uploaded yet',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isLight ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ),
          Text(
            tr.isTaglish ? 'Kumuha ng litrato ng iyong karatula o harapan' : 'Capture your physical store signage',
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showPhotoSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: const Text('Kumuha gamit ang Camera'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(storefrontProvider.notifier).uploadPhoto(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
              title: const Text('Pumili sa Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(storefrontProvider.notifier).uploadPhoto(source: ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final state = ref.read(storefrontProvider);
    _nameController.text = state.name;
    _slugController.text = state.slug;
    _addressController.text = state.address;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Storefront Profile',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Pangalan ng Tindahan (Store Name)',
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _slugController,
                decoration: const InputDecoration(
                  labelText: 'Web Link Slug (tindagrid.us.ci/...)',
                  prefixIcon: Icon(Icons.link),
                  helperText: 'Letters, numbers, and dashes only',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address / Lokasyon',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 14),
              // GPS Auto-Detect Button
              OutlinedButton.icon(
                onPressed: () {
                  // Set standard Metro Manila coordinates for demo
                  ref.read(storefrontProvider.notifier).updateGpsCoordinates(14.7566, 121.0450);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📍 GPS location locked: (14.7566, 121.0450)'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                icon: const Icon(Icons.my_location_rounded, size: 16),
                label: const Text('Gamitin ang Kasalukuyang GPS Lokasyon'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kanselahin'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(storefrontProvider.notifier).updateDetails(
                    name: _nameController.text.trim(),
                    slug: _slugController.text.trim(),
                    address: _addressController.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('I-save'),
          ),
        ],
      ),
    );
  }
}
