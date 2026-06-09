import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class ProjectNameScreen extends StatefulWidget {
  const ProjectNameScreen({super.key, required this.onContinue});

  final ValueChanged<String> onContinue;

  @override
  State<ProjectNameScreen> createState() => _ProjectNameScreenState();
}

class _ProjectNameScreenState extends State<ProjectNameScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give this project a name before continuing.')),
      );
      return;
    }
    widget.onContinue(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New project')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Name this inspection project',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Photos and videos are saved to a SpeakEasyReports album on your iPhone, grouped under this project name.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          const Text('Project name *', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. 12 Oak Street plumbing check',
            ),
            onSubmitted: (_) => _continue(),
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Continue', icon: Icons.arrow_forward, onPressed: _continue),
        ],
      ),
    );
  }
}