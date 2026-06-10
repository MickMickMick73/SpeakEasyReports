import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../models/settings.dart';
import '../theme/app_theme.dart';

class HotspotWizard {
  static Future<void> show(BuildContext context, AppState state) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _HotspotSheet(state: state),
    );
  }
}

class _HotspotSheet extends StatefulWidget {
  const _HotspotSheet({required this.state});
  final AppState state;

  @override
  State<_HotspotSheet> createState() => _HotspotSheetState();
}

class _HotspotSheetState extends State<_HotspotSheet> {
  var _step = 0;

  Future<void> _openSettings() async {
    final uri = Uri.parse('App-Prefs:root=INTERNET_TETHERING');
    if (!await launchUrl(uri)) {
      await launchUrl(Uri.parse('app-settings:'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final steps = [
      'On iPhone: Settings → Personal Hotspot → turn **Allow Others to Join** ON.',
      'On your laptop: join the iPhone hotspot Wi‑Fi network.',
      'On PC: run SERTOOLWINPC.exe from the SER V2.0 PC-Tool folder.',
      'Return here and tap **Test connection** on the Connections tab.',
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Hotspot transfer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: 8),
          Text(
            'Use this when site Wi‑Fi is unavailable. Your phone shares internet; your PC connects to the phone.',
            style: TextStyle(color: p.textMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
            child: Text(steps[_step], style: TextStyle(color: p.text, fontSize: 16, height: 1.45)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_step > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _step--),
                    child: const Text('Back'),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _step < steps.length - 1
                      ? () => setState(() => _step++)
                      : () {
                          widget.state.settings.preferredConnectionMode = ConnectionMode.hotspot;
                          widget.state.saveSettings();
                          Navigator.pop(context);
                        },
                  child: Text(_step < steps.length - 1 ? 'Next' : 'Done'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
            label: const Text('Open Hotspot Settings'),
          ),
        ],
      ),
    );
  }
}