import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/session.dart';
import '../services/report_share_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import 'hotspot_wizard.dart';
import 'primary_button.dart';

class DeliveryActions extends StatefulWidget {
  const DeliveryActions({
    super.key,
    required this.state,
    required this.session,
    this.onStatus,
    this.showNewInspection = false,
    this.onNewInspection,
  });

  final AppState state;
  final InspectionSession session;
  final void Function(String message, {bool isError})? onStatus;
  final bool showNewInspection;
  final VoidCallback? onNewInspection;

  @override
  State<DeliveryActions> createState() => _DeliveryActionsState();
}

class _DeliveryActionsState extends State<DeliveryActions> {
  final _sync = SyncService();
  final _share = ReportShareService();
  var _pushing = false;
  var _emailing = false;

  void _notify(String msg, {bool isError = false}) {
    widget.onStatus?.call(msg, isError: isError);
  }

  Future<void> _push({required bool hotspot}) async {
    setState(() => _pushing = true);
    _notify('Pushing to PC…');
    try {
      var ok = await _sync.testConnection(widget.state.settings.apiBaseUrl);
      if (!ok && hotspot && mounted) {
        await HotspotWizard.show(context, widget.state);
        ok = await _sync.testConnection(widget.state.settings.apiBaseUrl);
      }
      if (!ok) {
        _notify(
          hotspot
              ? 'PC not reachable. Enable hotspot, connect laptop, then try again.'
              : 'PC not reachable. Check Connections tab — same Wi‑Fi required.',
          isError: true,
        );
        return;
      }
      final result = await _sync.pushSession(widget.session, widget.state.settings);
      widget.session.syncStatus = SyncStatus.complete;
      widget.session.syncError = null;
      await widget.state.saveSession(widget.session);
      _notify('Synced! Report folder: ${result['reportFolder'] ?? 'OK'}');
    } catch (e) {
      widget.session.syncStatus = SyncStatus.failed;
      widget.session.syncError = e.toString();
      await widget.state.saveSession(widget.session);
      _notify('Push failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _pushing = false);
    }
  }

  Future<void> _email() async {
    setState(() => _emailing = true);
    try {
      await _share.emailReportWithCompression(
        context,
        widget.session,
        widget.state.settings,
      );
      _notify('Email composer opened — tap Send in Mail.');
    } on EmailShareException catch (e) {
      _notify(e.message, isError: true);
    } catch (e) {
      _notify('Email failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _emailing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: _emailing ? 'Preparing…' : 'Email report',
                icon: Icons.email_outlined,
                variant: PrimaryButtonVariant.secondary,
                onPressed: _emailing ? null : _email,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: 'Share',
                icon: Icons.share,
                variant: PrimaryButtonVariant.secondary,
                onPressed: () => _share.shareReport(widget.session, widget.state.settings, context: context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: _pushing ? 'Pushing…' : 'Push to PC (Wi‑Fi)',
          icon: Icons.cloud_upload,
          onPressed: _pushing ? null : () => _push(hotspot: false),
        ),
        const SizedBox(height: 10),
        PrimaryButton(
          label: _pushing ? 'Pushing…' : 'Hotspot push',
          icon: Icons.wifi_tethering,
          variant: PrimaryButtonVariant.secondary,
          onPressed: _pushing ? null : () => _push(hotspot: true),
        ),
        if (widget.showNewInspection && widget.onNewInspection != null) ...[
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'New inspection',
            icon: Icons.add,
            variant: PrimaryButtonVariant.success,
            onPressed: widget.onNewInspection,
          ),
        ],
      ],
    );
  }
}