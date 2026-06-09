import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/session.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('History')),
          body: state.sessions.isEmpty
              ? const Center(child: Text('No saved inspections yet.', style: TextStyle(color: AppColors.textMuted)))
              : ListView.builder(
                  itemCount: state.sessions.length,
                  itemBuilder: (context, i) {
                    final s = state.sessions[i];
                    return ListTile(
                      title: Text(s.clientName.isEmpty ? 'Untitled' : s.clientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${s.siteAddress}\n${inspectionTypeLabel(s.inspectionType)}'),
                      isThreeLine: true,
                      trailing: _syncIcon(s.syncStatus),
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
        return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
      default:
        return const Icon(Icons.cloud_upload_outlined, color: AppColors.textMuted);
    }
  }
}