import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

const _itchUrl = 'https://mickeykool401.itch.io/SpeakEasyServer';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _sync = SyncService();
  late final TextEditingController _apiUrl;
  late final TextEditingController _inspector;
  late final TextEditingController _company;
  String _testMsg = '';
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _apiUrl = TextEditingController(text: widget.state.settings.apiBaseUrl);
    _inspector = TextEditingController(text: widget.state.settings.inspectorName);
    _company = TextEditingController(text: widget.state.settings.companyName);
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _apiUrl.dispose();
    _inspector.dispose();
    _company.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    final qrUrl = widget.state.lastQrConnectedUrl;
    if (qrUrl == null) return;
    _apiUrl.text = qrUrl;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PC connected from QR: $qrUrl')),
    );
    widget.state.clearQrConnectedBanner();
    setState(() => _testMsg = 'QR code filled the PC address. Tap Test PC connection.');
  }

  Future<void> _save() async {
    widget.state.settings.apiBaseUrl = _apiUrl.text.trim();
    widget.state.settings.inspectorName = _inspector.text.trim();
    widget.state.settings.companyName = _company.text.trim();
    await widget.state.saveSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved.')));
    }
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testMsg = 'Testing…';
    });
    final ok = await _sync.testConnection(_apiUrl.text.trim());
    setState(() {
      _testing = false;
      _testMsg = ok ? 'Connected to PC server.' : 'Could not connect. Run SpeakEasy on PC, same Wi‑Fi.';
    });
  }

  Future<void> _openItch() async {
    final uri = Uri.parse(_itchUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link.')));
      }
    }
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all inspection history?'),
        content: const Text(
          'This permanently removes all saved reports and media from this phone. Synced copies on your PC are not affected. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await widget.state.deleteAllSessions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All inspections deleted from this phone.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = _testMsg.contains('Connected');
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('SpeakEasy Reports v1.2', style: TextStyle(fontWeight: FontWeight.w700)),
          const Text('App Store edition', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          const Text('© 2026 SpeakEasy Reports', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 20),
          const Text('Connect to PC (QR)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'On your PC, open SpeakEasy → Connect iPhone → scan the QR with the iPhone Camera app → tap Open in SpeakEasy Reports. The server address fills in automatically below.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          const Text('SpeakEasy Server (PC)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Download from itch.io'),
            subtitle: Text(_itchUrl, style: TextStyle(color: AppColors.primary, fontSize: 13)),
            trailing: const Icon(Icons.open_in_new),
            onTap: _openItch,
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: QrImageView(
                data: _itchUrl,
                version: QrVersions.auto,
                size: 160,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Scan this QR on your PC to open the server download page.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          const Text('Office PC URL', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(controller: _apiUrl, decoration: const InputDecoration(hintText: 'http://192.168.1.110:3001')),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(onPressed: _testing ? null : _test, child: Text(_testing ? 'Testing…' : 'Test PC connection')),
              const SizedBox(width: 12),
              if (_testMsg.isNotEmpty)
                Icon(connected ? Icons.check_circle : Icons.error_outline, color: connected ? AppColors.success : AppColors.warning),
            ],
          ),
          if (_testMsg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_testMsg, style: TextStyle(color: connected ? AppColors.success : AppColors.warning)),
            ),
          const SizedBox(height: 20),
          const Text('Inspector name', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(controller: _inspector),
          const SizedBox(height: 16),
          const Text('Company name', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(controller: _company),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Dark theme'),
            value: widget.state.settings.appearanceDark,
            onChanged: (v) async {
              widget.state.settings.appearanceDark = v;
              await widget.state.saveSettings();
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Save settings')),
          const SizedBox(height: 32),
          const Text('Danger zone', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _deleteAll,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
            child: const Text('Delete all inspection history'),
          ),
        ],
      ),
    );
  }
}