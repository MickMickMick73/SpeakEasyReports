import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/session.dart';
import '../models/settings.dart';
import 'report_builder.dart';

class ReportShareService {
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

  Future<void> emailReport(
    InspectionSession session,
    AppSettings settings, {
    String? recipient,
    BuildContext? context,
  }) async {
    final to = (recipient ?? session.clientEmail).trim();
    final subject = ReportBuilder.buildEmailSubject(session, settings);
    final body = ReportBuilder.buildEmailBody(session, settings);
    final html = ReportBuilder.buildHtmlReport(session, settings);

    try {
      final dir = await getTemporaryDirectory();
      final htmlPath = '${dir.path}/report-${session.id.substring(0, 8)}.html';
      await File(htmlPath).writeAsString(html);

      final email = Email(
        subject: subject,
        body: body,
        recipients: to.isEmpty ? [] : [to],
        attachmentPaths: [htmlPath],
        isHTML: false,
      );
      await FlutterEmailSender.send(email);
      return;
    } catch (_) {
      final query = <String>[];
      if (subject.isNotEmpty) query.add('subject=${Uri.encodeComponent(subject)}');
      if (body.isNotEmpty) query.add('body=${Uri.encodeComponent(body)}');
      final uri = Uri(
        scheme: 'mailto',
        path: to,
        query: query.isEmpty ? null : query.join('&'),
      );
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Mail. Check that an email account is set up on this device.')),
          );
        }
      }
    }
  }

  Future<void> promptEmailRecipient(BuildContext context, InspectionSession session, AppSettings settings) async {
    final controller = TextEditingController(text: session.clientEmail);
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
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await emailReport(session, settings, recipient: controller.text.trim(), context: context);
    controller.dispose();
  }

  Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}