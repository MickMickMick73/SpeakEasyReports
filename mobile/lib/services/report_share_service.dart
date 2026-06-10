import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/session.dart';
import '../models/settings.dart';
import 'email_compress_service.dart';
import 'report_builder.dart';

class EmailShareException implements Exception {
  EmailShareException(this.message);
  final String message;
  @override
  String toString() => message;
}

class _PrepareState {
  _PrepareState({required this.step, this.elapsedSeconds = 0, this.maxSeconds = 60, this.progress});

  String step;
  int elapsedSeconds;
  int maxSeconds;
  double? progress;
}

class ReportShareService {
  final _compress = EmailCompressService();

  Future<void> shareReport(InspectionSession session, AppSettings settings, {BuildContext? context}) async {
    final text = ReportBuilder.buildPlainTextReport(session, settings);
    final html = ReportBuilder.buildHtmlReport(session, settings);
    final dir = await getTemporaryDirectory();
    final id = session.id.substring(0, 8);
    final htmlFile = File('${dir.path}/report-$id.html');
    final textFile = File('${dir.path}/report-$id.txt');
    await htmlFile.writeAsString(html);
    await textFile.writeAsString(text);

    final subject = ReportBuilder.buildEmailSubject(session, settings);
    final box = context != null ? _shareOrigin(context) : null;
    await Share.shareXFiles(
      [XFile(htmlFile.path), XFile(textFile.path)],
      text: '$subject — inspection report attached.',
      subject: subject,
      sharePositionOrigin: box,
    );
  }

  Future<void> emailReportWithCompression(
    BuildContext context,
    InspectionSession session,
    AppSettings settings,
  ) async {
    final recipient = session.clientEmail.trim();
    if (recipient.isEmpty) {
      final entered = await _promptRecipient(context, '');
      if (entered == null || entered.isEmpty) {
        throw EmailShareException('Add a client email on the job details screen first.');
      }
      session.clientEmail = entered;
    }

    if (!context.mounted) return;

    final prepareState = ValueNotifier(_PrepareState(step: 'Starting…'));
    Timer? elapsedTimer;

    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ValueListenableBuilder<_PrepareState>(
        valueListenable: prepareState,
        builder: (_, state, __) {
          return AlertDialog(
            title: const Text('Preparing email'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.progress != null) ...[
                  LinearProgressIndicator(value: state.progress),
                  const SizedBox(height: 12),
                ] else
                  const LinearProgressIndicator(),
                const SizedBox(height: 12),
                Text(state.step),
                const SizedBox(height: 8),
                Text(
                  '${state.elapsedSeconds}s elapsed · up to ${state.maxSeconds}s',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                Text(
                  'Large videos are omitted from email — use Push to PC for full video.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    ));

    elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = prepareState.value;
      prepareState.value = _PrepareState(
        step: current.step,
        elapsedSeconds: current.elapsedSeconds + 1,
        maxSeconds: current.maxSeconds,
        progress: current.progress,
      );
    });

    try {
      final html = ReportBuilder.buildHtmlReport(session, settings);
      final packed = await _compress.prepareAttachments(
        session: session,
        htmlReport: html,
        onProgress: (step, {elapsedSeconds = 0, maxSeconds = 60, progress}) {
          prepareState.value = _PrepareState(
            step: step,
            elapsedSeconds: elapsedSeconds,
            maxSeconds: maxSeconds,
            progress: progress,
          );
        },
      );

      final subject = ReportBuilder.buildEmailSubject(session, settings);
      var body = ReportBuilder.buildEmailBody(session, settings);
      if (packed.videoOmitted) {
        body += '\n\nNote: Video was omitted from this email (over 22 MB). Use Push to PC for full video.';
      }
      if (packed.skippedVideoCount > 0) {
        body += '\n\nNote: Only 1 video attaches to email. ${packed.skippedVideoCount} extra video(s) — use Push to PC.';
      }
      if (packed.skippedPhotoCount > 0) {
        body += '\n\nNote: ${packed.photoPaths.length} photos attached (max 5). ${packed.skippedPhotoCount} older photo(s) omitted.';
      }
      body += '\n\nTap Send in Mail to deliver.';

      final attachments = <String>[packed.htmlPath];
      if (packed.videoPath != null) attachments.add(packed.videoPath!);
      attachments.addAll(packed.photoPaths);

      final email = Email(
        subject: subject,
        body: body,
        recipients: [session.clientEmail.trim()],
        attachmentPaths: attachments,
        isHTML: false,
      );
      await FlutterEmailSender.send(email);
    } catch (e) {
      if (e is EmailShareException) rethrow;
      final subject = ReportBuilder.buildEmailSubject(session, settings);
      final body = ReportBuilder.buildEmailBody(session, settings);
      final query = <String>[
        if (subject.isNotEmpty) 'subject=${Uri.encodeComponent(subject)}',
        if (body.isNotEmpty) 'body=${Uri.encodeComponent(body)}',
      ];
      final uri = Uri(
        scheme: 'mailto',
        path: session.clientEmail.trim(),
        query: query.isEmpty ? null : query.join('&'),
      );
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw EmailShareException('Could not open Mail. Check that an email account is set up.');
      }
    } finally {
      elapsedTimer?.cancel();
      prepareState.dispose();
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<String?> _promptRecipient(BuildContext context, String initial) async {
    final controller = TextEditingController(text: initial);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email report'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Recipient email', hintText: 'client@example.com'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );
    final value = controller.text.trim();
    controller.dispose();
    return confirmed == true ? value : null;
  }

  @Deprecated('Use emailReportWithCompression')
  Future<void> promptEmailRecipient(BuildContext context, InspectionSession session, AppSettings settings) async {
    await emailReportWithCompression(context, session, settings);
  }

  Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}