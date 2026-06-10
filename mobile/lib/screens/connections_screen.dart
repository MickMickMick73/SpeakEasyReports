import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app_state.dart';
import '../models/settings.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hotspot_wizard.dart';

class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final _sync = SyncService();
  String _status = 'Not tested yet';
  bool _testing = false;
  bool _scanning = false;

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _status = 'Testing…';
    });
    final url = widget.state.settings.apiBaseUrl.trim();
    final ok = await _sync.testConnection(url);
    if (mounted) {
      setState(() {
        _testing = false;
        _status = ok ? 'Connected to PC at $url' : 'PC not reachable at $url';
      });
    }
  }

  Future<void> _scanQr() async {
    setState(() => _scanning = true);
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrScanScreen()),
    );
    setState(() => _scanning = false);
    if (result == null || result.isEmpty) return;

    var url = result.trim();
    if (url.endsWith('/connect') || url.endsWith('/link')) {
      url = url.replaceAll(RegExp(r'/(connect|link)/?$'), '');
    }
    widget.state.settings.apiBaseUrl = url;
    widget.state.settings.preferredConnectionMode = ConnectionMode.lan;
    await widget.state.saveSettings();
    widget.state.markPcConnectedFromQr(url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved PC URL: $url')));
      await _test();
    }
  }

  void _selectMode(ConnectionMode mode) async {
    widget.state.settings.preferredConnectionMode = mode;
    await widget.state.saveSettings();
    if (mode == ConnectionMode.hotspot) {
      await HotspotWizard.show(context, widget.state);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final api = widget.state.settings.apiBaseUrl.trim();
    final connected = _status.startsWith('Connected');
    final mode = widget.state.settings.preferredConnectionMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Connections')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Connect your phone to the PC tool without typing URLs when possible.',
            style: TextStyle(color: p.textMuted, height: 1.4),
          ),
          const SizedBox(height: 20),
          _ModeCard(
            title: 'LAN (same Wi‑Fi)',
            icon: Icons.wifi,
            selected: mode == ConnectionMode.lan,
            onSelect: () => _selectMode(ConnectionMode.lan),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('PC URL: $api', style: TextStyle(color: p.text, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: const Icon(Icons.link),
                  label: Text(_testing ? 'Testing…' : 'Test connection'),
                ),
                const SizedBox(height: 8),
                Text(_status, style: TextStyle(color: connected ? p.success : p.warning)),
                if (api.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: QrImageView(
                      data: '$api/connect',
                      version: QrVersions.auto,
                      size: 140,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Show this QR on your phone; open /connect on PC to confirm the same URL.',
                    style: TextStyle(color: p.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _scanning ? null : _scanQr,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(_scanning ? 'Opening scanner…' : 'Scan PC QR — save URL'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ModeCard(
            title: 'Personal Hotspot',
            icon: Icons.wifi_tethering,
            selected: mode == ConnectionMode.hotspot,
            onSelect: () => _selectMode(ConnectionMode.hotspot),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'When site Wi‑Fi is unavailable: turn on iPhone hotspot, connect your laptop, run PC tool, then push reports.',
                  style: TextStyle(color: p.textMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => HotspotWizard.show(context, widget.state),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Hotspot Transfer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onSelect,
    required this.child,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? p.primary : p.border, width: selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: selected ? p.primary : p.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: p.text)),
                  ),
                  if (selected) Icon(Icons.check_circle, color: p.primary),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _QrScanScreen extends StatefulWidget {
  const _QrScanScreen();

  @override
  State<_QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<_QrScanScreen> {
  final _controller = MobileScannerController();
  var _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan PC QR')),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_done) return;
          for (final bar in capture.barcodes) {
            final raw = bar.rawValue;
            if (raw == null || !raw.contains('http')) continue;
            _done = true;
            Navigator.pop(context, raw);
            return;
          }
        },
      ),
    );
  }
}