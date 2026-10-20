import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/feedback_helper.dart';

class WebcamScannerDialog extends StatefulWidget {
  final void Function(String barcode) onBarcodeScanned;
  final VoidCallback onOpenCompanionMode;
  final bool isTaglish;

  const WebcamScannerDialog({
    super.key,
    required this.onBarcodeScanned,
    required this.onOpenCompanionMode,
    this.isTaglish = true,
  });

  @override
  State<WebcamScannerDialog> createState() => _WebcamScannerDialogState();
}

class _WebcamScannerDialogState extends State<WebcamScannerDialog> {
  late final MobileScannerController _controller;
  bool _hasDetected = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasDetected) return;

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.trim().isNotEmpty) {
        setState(() => _hasDetected = true);
        FeedbackHelper.triggerSuccessFeedback();
        widget.onBarcodeScanned(code.trim());
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.isTaglish;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 540),
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        tr ? 'Webcam / Laptop Scanner' : 'Webcam Barcode Scanner',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Camera Area / Fallback
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.black,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_cameraError == null)
                        MobileScanner(
                          controller: _controller,
                          onDetect: _onDetect,
                          errorBuilder: (context, error) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && _cameraError == null) {
                                setState(() {
                                  _cameraError = error.errorCode.name;
                                });
                              }
                            });
                            return const SizedBox.shrink();
                          },
                        ),

                      if (_cameraError != null)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.no_photography_rounded, size: 48, color: Colors.amber),
                              const SizedBox(height: 12),
                              Text(
                                tr ? 'Hindi ma-access ang webcam ng laptop.' : 'Cannot access laptop webcam.',
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tr
                                    ? 'Kadalasan, malabo ang webcam ng laptop para sa barcode. Gamitin ang smartphone bilang wireless scanner gun!'
                                    : 'Laptop webcams often struggle with barcode focus. Use your smartphone as a wireless scanner gun instead!',
                                style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                                icon: const Icon(Icons.phonelink_ring_rounded, size: 18),
                                label: Text(tr ? 'Buksan ang Phone Companion' : 'Open Smartphone Companion'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  widget.onOpenCompanionMode();
                                },
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // Viewfinder Box
                        Container(
                          width: 220,
                          height: 160,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary, width: 2.5),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.phonelink_rounded, size: 16, color: AppColors.primary),
                    label: Text(
                      tr ? 'I-pair ang Phone' : 'Pair Phone Instead',
                      style: const TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onOpenCompanionMode();
                    },
                  ),
                  Text(
                    tr ? 'Itapat ang barcode sa kahon' : 'Aim barcode at target frame',
                    style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
