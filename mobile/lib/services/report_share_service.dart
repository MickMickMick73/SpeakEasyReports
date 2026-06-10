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

    final box = context != null ? _shareOrigin(context) : null;
    await Share.shareXFiles(
      [XFile(htmlFile.path), XFile(textFile.path)],
      text: text,
      subject: ReportBuilder.buildEmailSubject(session, settings),
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

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Preparing email attachments…\nOriginal photos and videos stay unchanged.')),
          ],
        ),
      ),
    );

    try {
      final html = ReportBuilder.buildHtmlReport(session, settings);
      final packed = await _compress.prepareAttachments(session: session, htmlReport: html);

      final subject = ReportBuilder.buildEmailSubject(session, settings);
      var body = ReportBuilder.buildEmailBody(session, settings);
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
    } on EmailCompressException catch (e) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Video too large'),
            content: Text(e.message),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
      throw EmailShareException(e.message);
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