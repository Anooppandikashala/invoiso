import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Camera-based barcode scanner dialog
class CameraScannerDialog extends StatefulWidget {
  final Function(String barcode) onScan;
  final String title;

  const CameraScannerDialog({
    super.key,
    required this.onScan,
    this.title = 'Scan Barcode',
  });

  @override
  State<CameraScannerDialog> createState() => _CameraScannerDialogState();
}

class _CameraScannerDialogState extends State<CameraScannerDialog> {
  late MobileScannerController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: [BarcodeFormat.all],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode != null && barcode.isNotEmpty) {
      setState(() => _isProcessing = true);
      widget.onScan(barcode);
      Navigator.of(context).pop(barcode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scanner view
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _handleBarcode,
                  ),
                  // Scanning indicator
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Position the barcode within the frame',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Toggle flash
                  IconButton.filled(
                    icon: const Icon(Icons.flash_on),
                    onPressed: () => _controller.toggleTorch(),
                    tooltip: 'Toggle Flash',
                  ),
                  // Flip camera
                  IconButton.filled(
                    icon: const Icon(Icons.flip_camera_ios),
                    onPressed: () => _controller.switchCamera(),
                    tooltip: 'Switch Camera',
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

/// Show camera scanner dialog
Future<String?> showCameraScannerDialog(
  BuildContext context, {
  String title = 'Scan Barcode',
  Function(String)? onScan,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => CameraScannerDialog(
      title: title,
      onScan: onScan ?? (_) {},
    ),
  );
}
