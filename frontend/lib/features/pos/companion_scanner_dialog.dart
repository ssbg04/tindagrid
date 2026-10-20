import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/sync/companion_scanner_service.dart';
import '../../core/utils/feedback_helper.dart';

class CompanionScannerDialog extends StatefulWidget {
  final CompanionScannerService service;
  final void Function(String barcode) onBarcodeReceived;
  final bool isTaglish;

  const CompanionScannerDialog({
    super.key,
    required this.service,
    required this.onBarcodeReceived,
    this.isTaglish = true,
  });

  @override
  State<CompanionScannerDialog> createState() => _CompanionScannerDialogState();
}

class _CompanionScannerDialogState extends State<CompanionScannerDialog> {
  CompanionSessionInfo? _session;
  bool _isLoading = true;
  Timer? _pollTimer;
  String? _lastScanId;
  final List<CompanionScanEvent> _scans = [];
  final TextEditingController _testBarcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    try {
      final session = await widget.service.createSession();
      if (mounted) {
        setState(() {
          _session = session;
          _isLoading = false;
        });
        _startPolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 900), (_) async {
      if (_session == null || !mounted) return;

      final newScans = await widget.service.pollScans(
        sessionId: _session!.sessionId,
        sinceScanId: _lastScanId,
      );

      if (newScans.isNotEmpty && mounted) {
        for (final scan in newScans) {
          _lastScanId = scan.id;
          _scans.insert(0, scan);
          FeedbackHelper.triggerSuccessFeedback();
          widget.onBarcodeReceived(scan.barcode);
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _testBarcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.isTaglish;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      backgroundColor: Theme.of(context).cardColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const SizedBox(
                  height: 240,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.phonelink_ring_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr ? 'Smartphone Scanner Gun' : 'Smartphone Companion',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  tr ? 'I-pair ang telepono sa POS' : 'Pair phone camera with web POS',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // QR Code Box
                    if (_session != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: QrImageView(
                          data: _session!.pairUrl,
                          version: QrVersions.auto,
                          size: 180,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF0D9488),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.circle,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pairing Code Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.key_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Code: ${_session!.pairingCode}',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Live Pulse Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr
                                ? 'Naka-antabay sa camera ng phone...'
                                : 'Listening for phone camera scans...',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Test Barcode Push (For browser dev & simulation without 2nd phone)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _testBarcodeController,
                            decoration: InputDecoration(
                              hintText: tr ? 'I-test ang barcode...' : 'Test barcode push...',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onSubmitted: (code) {
                              if (code.trim().isNotEmpty && _session != null) {
                                widget.service.pushScan(
                                  sessionIdOrCode: _session!.sessionId,
                                  barcode: code.trim(),
                                );
                                _testBarcodeController.clear();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () {
                            final code = _testBarcodeController.text.trim();
                            if (code.isNotEmpty && _session != null) {
                              widget.service.pushScan(
                                sessionIdOrCode: _session!.sessionId,
                                barcode: code,
                              );
                              _testBarcodeController.clear();
                            }
                          },
                          child: Text(tr ? 'I-push' : 'Send'),
                        ),
                      ],
                    ),

                    if (_scans.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          tr ? 'Kamakailang Scans (${_scans.length}):' : 'Recent Scans (${_scans.length}):',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 90),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _scans.length > 3 ? 3 : _scans.length,
                          itemBuilder: (context, i) {
                            final s = _scans[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('📦 ${s.barcode}', style: GoogleFonts.sourceCodePro(fontSize: 12, fontWeight: FontWeight.w600)),
                                  Text('✅ Pumasok', style: TextStyle(color: Colors.green.shade700, fontSize: 11)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
