import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _apiUrl = TextEditingController(text: widget.state.settings.apiBaseUrl);
    _inspector = TextEditingController(text: widget.state.settings.inspectorName);
    _company = TextEditingController(text: widget.state.settings.companyName);
  }

  @override
  void dispose() {
    _apiUrl.dispose();
    _inspector.dispose();
    _company.dispose();
    super.dispose();
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
    setState(() => _testMsg = 'Testing…');
    final ok = await _sync.testConnection(_apiUrl.text.trim());
    setState(() => _testMsg = ok ? 'Connected to PC server.' : 'Could not connect. Run SpeakEasy-PC.bat, same Wi‑Fi.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('SpeakEasy Reports v1.0.0 — free Flutter edition', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          const Text('Office PC URL', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(controller: _apiUrl, decoration: const InputDecoration(hintText: 'http://192.168.1.110:3001')),
          const Text('Run SpeakEasy-Link.bat on PC. Same URL for inspections + Link.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: _test, child: const Text('Test PC connection')),
          if (_testMsg.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_testMsg, style: TextStyle(color: _testMsg.contains('Connected') ? AppColors.success : AppColors.warning))),
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
        ],
      ),
    );
  }
}