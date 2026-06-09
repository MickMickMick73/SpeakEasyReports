import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../models/session.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class DeliverScreen extends StatefulWidget {
  const DeliverScreen({super.key, required this.state});

  final AppState state;

  @override
  State<DeliverScreen> createState() => _DeliverScreenState();
}

class _DeliverScreenState extends State<DeliverScreen> {
  final _sync = SyncService();
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
      final result = await _sync.pushSession(s, widget.state.settings.apiBaseUrl);
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

  Future<void> _shareSummary() async {
    final s = widget.state.activeSession!;
    final text = 'Inspection: ${s.clientName}\n${s.siteAddress}\n${s.media.length} media items';
    await Share.share(text);
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
      appBar: AppBar(title: const Text('Done')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.clientName} — ready', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Run SpeakEasy-PC.bat on your computer first, same Wi‑Fi.', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _pushing ? 'Pushing…' : 'Push to PC',
              icon: Icons.cloud_upload,
              onPressed: _pushing ? null : _push,
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Share summary', icon: Icons.share, onPressed: _shareSummary, color: AppColors.surfaceAlt),
            const SizedBox(height: 12),
            PrimaryButton(label: 'New inspection', icon: Icons.add, onPressed: _newJob, color: AppColors.success),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(_message, style: TextStyle(color: _message.contains('failed') ? AppColors.danger : AppColors.success)),
            ],
          ],
        ),
      ),
    );
  }
}