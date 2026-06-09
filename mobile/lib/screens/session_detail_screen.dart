import 'dart:io';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/session.dart';
import '../services/report_share_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/report_preview_widget.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key, required this.state, required this.sessionId});

  final AppState state;
  final String sessionId;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final _sync = SyncService();
  final _share = ReportShareService();
  var _pushing = false;
  String _message = '';

  InspectionSession get _session =>
      widget.state.sessions.firstWhere((s) => s.id == widget.sessionId);

  Future<void> _push() async {
    setState(() {
      _pushing = true;
      _message = 'Pushing to PC…';
    });
    try {
      final result = await _sync.pushSession(_session, widget.state.settings);
      final s = _session;
      s.syncStatus = SyncStatus.complete;
      s.syncError = null;
      await widget.state.saveSession(s);
      setState(() => _message = 'Synced! ${result['reportFolder'] ?? 'OK'}');
    } catch (e) {
      final s = _session;
      s.syncStatus = SyncStatus.failed;
      s.syncError = e.toString();
      await widget.state.saveSession(s);
      setState(() => _message = 'Push failed: $e');
    } finally {
      setState(() => _pushing = false);
    }
  }

  Future<void> _delete() async {
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
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(s.projectName.isNotEmpty ? s.projectName : (s.clientName.isEmpty ? 'Inspection' : s.clientName)),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.siteAddress, style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Text(inspectionTypeLabel(s.inspectionType), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const Text('Report preview', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ReportPreviewWidget(session: s, settings: widget.state.settings),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.media.isNotEmpty) ...[
                    const Text('Media on this device', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ...s.media.map((m) {
                      final exists = File(m.localPath).existsSync();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(m.type == 'video' ? Icons.videocam : Icons.photo, color: AppColors.primary),
                        title: Text('${m.type == 'video' ? 'Video' : 'Photo'} · ${m.id.substring(0, 8)}'),
                        subtitle: Text(exists ? 'Stored on phone' : 'File missing', style: TextStyle(color: exists ? AppColors.success : AppColors.danger)),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                  PrimaryButton(
                    label: _pushing ? 'Pushing…' : 'Push to PC',
                    icon: Icons.cloud_upload,
                    onPressed: _pushing ? null : _push,
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Email report',
                    icon: Icons.email_outlined,
                    onPressed: () => _share.promptEmailRecipient(context, s, widget.state.settings),
                    color: AppColors.surfaceAlt,
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Share',
                    icon: Icons.share,
                    onPressed: () => _share.shareReport(s, widget.state.settings, context: context),
                    color: AppColors.surfaceAlt,
                  ),
                  if (_message.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(_message, style: TextStyle(color: _message.contains('failed') ? AppColors.danger : AppColors.success)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}