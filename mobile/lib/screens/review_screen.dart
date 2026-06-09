import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/session.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'deliver_screen.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final s = state.activeSession!;
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${s.clientName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('Site: ${s.siteAddress}'),
            const SizedBox(height: 12),
            Text('${s.media.where((m) => m.type == 'photo').length} photos · ${s.media.where((m) => m.type == 'video').length} videos'),
            const SizedBox(height: 12),
            const Text('Next: review the full client report, then email, share, or push to PC.', style: TextStyle(color: AppColors.textMuted)),
            const Spacer(),
            PrimaryButton(
              label: 'Continue to deliver',
              icon: Icons.arrow_forward,
              onPressed: () async {
                s.endedAt = DateTime.now();
                s.syncStatus = SyncStatus.pending;
                await state.saveSession(s);
                if (!context.mounted) return;
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => DeliverScreen(state: state)));
              },
            ),
          ],
        ),
      ),
    );
  }
}