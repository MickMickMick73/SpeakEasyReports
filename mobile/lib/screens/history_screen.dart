import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/session.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import 'session_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.state});

  final AppState state;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _sync = SyncService();
  String? _pushingId;

  Future<void> _pushSession(InspectionSession session) async {
    setState(() => _pushingId = session.id);
    try {
      await _sync.pushSession(session, widget.state.settings);
      session.syncStatus = SyncStatus.complete;
      session.syncError = null;
    } catch (e) {
      session.syncStatus = SyncStatus.failed;
      session.syncError = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Push failed: $e')));
      }
    }
    await widget.state.saveSession(session);
    if (mounted) setState(() => _pushingId = null);
  }

  void _openSession(InspectionSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SessionDetailScreen(state: widget.state, sessionId: session.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final p = AppPalette.of(context);
        return Scaffold(
          appBar: AppBar(title: const Text('History')),
          body: widget.state.sessions.isEmpty
              ? Center(child: Text('No saved inspections yet.', style: TextStyle(color: p.textMuted)))
              : ListView.builder(
                  itemCount: widget.state.sessions.length,
                  itemBuilder: (context, i) {
                    final s = widget.state.sessions[i];
                    final pushing = _pushingId == s.id;
                    return ListTile(
                      onTap: () => _openSession(s),
                      title: Text(s.clientName.isEmpty ? 'Untitled' : s.clientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${s.siteAddress}\n${inspectionTypeLabel(s.inspectionType)}'),
                      isThreeLine: true,
                      trailing: pushing
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                              tooltip: 'Push to PC',
                              onPressed: () => _pushSession(s),
                              icon: _syncIcon(s.syncStatus),
                            ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _syncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.complete:
        return const Icon(Icons.cloud_done, color: AppColors.success);
      case SyncStatus.failed:
        return const Icon(Icons.cloud_off, color: AppColors.danger);
      case SyncStatus.uploading:
        return const Icon(Icons.cloud_upload_outlined, color: AppColors.warning);
      default:
        return const Icon(Icons.cloud_upload_outlined, color: AppColors.textMuted);
    }
  }
}