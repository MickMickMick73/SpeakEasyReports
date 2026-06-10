import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/session.dart';
import '../theme/app_theme.dart';
import '../widgets/delivery_actions.dart';
import '../widgets/session_media_review.dart';

class DeliverScreen extends StatefulWidget {
  const DeliverScreen({super.key, required this.state});

  final AppState state;

  @override
  State<DeliverScreen> createState() => _DeliverScreenState();
}

class _DeliverScreenState extends State<DeliverScreen> {
  String _message = '';
  var _isError = false;

  Future<void> _newJob() async {
    await widget.state.setActiveSession(null);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state.activeSession!;
    final p = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Review & deliver')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('${s.clientName} — ready to send', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Review the report, photos, and videos before you send.',
            style: TextStyle(color: p.textMuted),
          ),
          const SizedBox(height: 16),
          SessionMediaReview(session: s, settings: widget.state.settings, reportHeight: 400),
          const SizedBox(height: 20),
          DeliveryActions(
            state: widget.state,
            session: s,
            showNewInspection: true,
            onNewInspection: _newJob,
            onStatus: (msg, {bool isError = false}) => setState(() {
              _message = msg;
              _isError = isError;
            }),
          ),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(_message, style: TextStyle(color: _isError ? p.danger : p.success)),
          ],
        ],
      ),
    );
  }
}