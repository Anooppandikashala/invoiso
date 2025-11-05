import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// Not using now
class PDFViewerScreen extends StatefulWidget {
  final Uint8List pdfBytes;
  final String invoiceId;

  const PDFViewerScreen({
    super.key,
    required this.pdfBytes,
    required this.invoiceId,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  double _zoomLevel = 1.0;


  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel + 0.25).clamp(1.0, 5.0);
      _pdfViewerController.zoomLevel = _zoomLevel;
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - 0.25).clamp(1.0, 5.0);
      _pdfViewerController.zoomLevel = _zoomLevel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${widget.invoiceId}'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: _zoomOut,
            tooltip: 'Zoom Out',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in,color: Colors.black,),
            onPressed: _zoomIn,
            tooltip: 'Zoom In',
          ),
        ],
      ),
      body: SfPdfViewer.memory(
        widget.pdfBytes,
        controller: _pdfViewerController,
      ),
    );
  }
}
