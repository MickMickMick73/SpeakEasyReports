import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';

const _itchUrl = 'https://mickeykool401.itch.io/SpeakEasyServer';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _inspector;
  late final TextEditingController _company;

  @override
  void initState() {
    super.initState();
    _inspector = TextEditingController(text: widget.state.settings.inspectorName);
    _company = TextEditingController(text: widget.state.settings.companyName);
  }

  @override
  void dispose() {
    _inspector.dispose();
    _company.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    widget.state.settings.inspectorName = _inspector.text.trim();
    widget.state.settings.companyName = _company.text.trim();
    await widget.state.saveSettings();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved.')));
    }
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
    final p = AppPalette.of(context);
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
            style: TextButton.styleFrom(foregroundColor: p.danger),
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
    final p = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('SpeakEasy Reports v3.14emc', style: TextStyle(fontWeight: FontWeight.w700, color: p.text)),
          Text('App Store edition', style: TextStyle(color: p.textMuted)),
          const SizedBox(height: 6),
          Text('© 2026 SpeakEasy Reports', style: TextStyle(color: p.textMuted, fontSize: 12)),
          const SizedBox(height: 20),
          Text('SpeakEasy Server (PC)', style: TextStyle(fontWeight: FontWeight.w700, color: p.text)),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Download from itch.io', style: TextStyle(color: p.text)),
            subtitle: Text(_itchUrl, style: TextStyle(color: p.primary, fontSize: 13)),
            trailing: Icon(Icons.open_in_new, color: p.primary),
            onTap: _openItch,
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.border),
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
          Text(
            'Scan on your PC to download the server. PC connection setup is on the Connect tab.',
            style: TextStyle(color: p.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Text('Inspector name', style: TextStyle(fontWeight: FontWeight.w700, color: p.text)),
          const SizedBox(height: 8),
          TextField(controller: _inspector),
          const SizedBox(height: 16),
          Text('Company name', style: TextStyle(fontWeight: FontWeight.w700, color: p.text)),
          const SizedBox(height: 8),
          TextField(controller: _company),
          const SizedBox(height: 24),
          SwitchListTile(
            title: Text('Dark theme', style: TextStyle(color: p.text)),
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
          Text('Danger zone', style: TextStyle(fontWeight: FontWeight.w700, color: p.danger)),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _deleteAll,
            style: OutlinedButton.styleFrom(foregroundColor: p.danger, side: BorderSide(color: p.danger)),
            child: const Text('Delete all inspection history'),
          ),
        ],
      ),
    );
  }
}