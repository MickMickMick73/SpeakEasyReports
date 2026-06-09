import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/session.dart';
import '../models/settings.dart';
import '../services/report_builder.dart';

class ReportPreviewWidget extends StatefulWidget {
  const ReportPreviewWidget({super.key, required this.session, required this.settings, this.height});

  final InspectionSession session;
  final AppSettings settings;
  final double? height;

  @override
  State<ReportPreviewWidget> createState() => _ReportPreviewWidgetState();
}

class _ReportPreviewWidgetState extends State<ReportPreviewWidget> {
  late final WebViewController _controller;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setBackgroundColor(const Color(0xFFF8FAFC))
      ..loadHtmlString(ReportBuilder.buildHtmlReport(widget.session, widget.settings))
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) {
          if (mounted) setState(() => _ready = true);
        }),
      );
  }

  @override
  void didUpdateWidget(covariant ReportPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.id != widget.session.id ||
        oldWidget.settings.inspectorName != widget.settings.inspectorName ||
        oldWidget.settings.companyName != widget.settings.companyName) {
      _controller.loadHtmlString(ReportBuilder.buildHtmlReport(widget.session, widget.settings));
      setState(() => _ready = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final webView = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          WebViewWidget(
            controller: _controller,
            gestureRecognizers: {
              Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
              Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
            },
          ),
          if (!_ready) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );

    if (widget.height == null) return webView;
    return SizedBox(height: widget.height, child: webView);
  }
}