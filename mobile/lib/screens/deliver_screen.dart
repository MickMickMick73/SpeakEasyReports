import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/session.dart';
import '../services/report_share_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/report_preview_widget.dart';

class DeliverScreen extends StatefulWidget {
  const DeliverScreen({super.key, required this.state});

  final AppState state;

  @override
  State<DeliverScreen> createState() => _DeliverScreenState();
}

class _DeliverScreenState extends State<DeliverScreen> {
  final _sync = SyncService();
  final _share = ReportShareService();
  String _message = '';
  bool _pushing = false;

  Future<void> _push() async {
    final s = widget.state.activeSession;
    if (s == null) return;
    setState(() {
      _pushing = true;
      _message = 'Pushing to PC…';
    });
    try {
      final result = await _sync.pushSession(s, widget.state.settings);
      s.syncStatus = SyncStatus.complete;
      s.syncError = null;
      await widget.state.saveSession(s);
      setState(() => _message = 'Synced! Report folder: ${result['reportFolder'] ?? 'OK'}');
    } catch (e) {
      s.syncStatus = SyncStatus.failed;
      s.syncError = e.toString();
      await widget.state.saveSession(s);
      setState(() => _message = 'Push failed: $e');
    } finally {
      setState(() => _pushing = false);
    }
  }

  Future<void> _newJob() async {
    await widget.state.setActiveSession(null);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state.activeSession!;
    return Scaffold(
      appBar: AppBar(title: const Text('Review & deliver')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('${s.clientName} — ready to send', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Review what your client will receive before you email, share, or push to PC.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          const Text('Report preview', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 8),
          ReportPreviewWidget(session: s, settings: widget.state.settings, height: 400),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Email report',
                  icon: Icons.email_outlined,
                  onPressed: () => _share.promptEmailRecipient(context, s, widget.state.settings),
                  color: AppColors.surfaceAlt,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'Share',
                  icon: Icons.share,
                  onPressed: () => _share.shareReport(s, widget.state.settings, context: context),
                  color: AppColors.surfaceAlt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: _pushing ? 'Pushing…' : 'Push to PC',
            icon: Icons.cloud_upload,
            onPressed: _pushing ? null : _push,
          ),
          const SizedBox(height: 8),
          Text('Run SpeakEasy server on your PC first, same Wi‑Fi.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 12),
          PrimaryButton(label: 'New inspection', icon: Icons.add, onPressed: _newJob, color: AppColors.success),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(_message, style: TextStyle(color: _message.contains('failed') ? AppColors.danger : AppColors.success)),
          ],
        ],
      ),
    );
  }
}