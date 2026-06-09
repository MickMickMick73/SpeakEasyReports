import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/session.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'inspection_flow.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final count = state.sessions.length;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SpeakEasy Reports', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Voice notes, photos, video — sync to your PC.', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$count saved inspections', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'New job',
                        icon: Icons.add_circle_outline,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => InspectionFlow(state: state)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (state.sessions.isNotEmpty) ...[
                  const Text('Recent', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.sessions.take(5).length,
                      itemBuilder: (context, i) {
                        final s = state.sessions[i];
                        return ListTile(
                          title: Text(s.clientName.isEmpty ? 'Untitled' : s.clientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(s.siteAddress),
                          trailing: Icon(
                            s.syncStatus == SyncStatus.complete ? Icons.cloud_done : Icons.cloud_upload_outlined,
                            color: s.syncStatus == SyncStatus.complete ? AppColors.success : AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}