import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/session.dart';
import '../theme/app_theme.dart';
import '../widgets/delivery_actions.dart';
import '../widgets/session_media_review.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key, required this.state, required this.sessionId});

  final AppState state;
  final String sessionId;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  String _message = '';
  var _isError = false;

  InspectionSession get _session =>
      widget.state.sessions.firstWhere((s) => s.id == widget.sessionId);

  Future<void> _delete() async {
    final p = AppPalette.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this report?'),
        content: const Text(
          'This permanently removes this inspection and its media from this phone. Synced copies on your PC are not affected.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: p.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await widget.state.deleteSession(_session.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    final p = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.clientName.isEmpty ? 'Inspection' : s.clientName),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: _delete,
            icon: Icon(Icons.delete_outline, color: p.danger),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(s.siteAddress, style: TextStyle(color: p.textMuted)),
          const SizedBox(height: 8),
          Text(inspectionTypeLabel(s.inspectionType), style: TextStyle(fontWeight: FontWeight.w600, color: p.text)),
          const SizedBox(height: 16),
          SessionMediaReview(session: s, settings: widget.state.settings, reportHeight: 420),
          const SizedBox(height: 20),
          DeliveryActions(
            state: widget.state,
            session: s,
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