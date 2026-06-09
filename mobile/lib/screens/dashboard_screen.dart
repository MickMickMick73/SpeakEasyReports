import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/session.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'inspection_flow.dart';
import 'session_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.state});

  final AppState state;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
        final count = widget.state.sessions.length;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SpeakEasy Reports', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Voice notes, photos, video — sync to your PC.', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$count saved inspections', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'New job',
                        icon: Icons.add_circle_outline,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => InspectionFlow(state: widget.state)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (widget.state.sessions.isNotEmpty) ...[
                  const Text('Recent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.state.sessions.take(5).length,
                      itemBuilder: (context, i) {
                        final s = widget.state.sessions[i];
                        final pushing = _pushingId == s.id;
                        return ListTile(
                          onTap: () => _openSession(s),
                          title: Text(s.clientName.isEmpty ? 'Untitled' : s.clientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(s.siteAddress),
                          trailing: pushing
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(
                                  tooltip: 'Push to PC',
                                  onPressed: () => _pushSession(s),
                                  icon: Icon(
                                    s.syncStatus == SyncStatus.complete ? Icons.cloud_done : Icons.cloud_upload_outlined,
                                    color: s.syncStatus == SyncStatus.complete ? AppColors.success : AppColors.textMuted,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}