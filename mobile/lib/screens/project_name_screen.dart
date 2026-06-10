import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/voice_input_field.dart';

class ProjectNameScreen extends StatefulWidget {
  const ProjectNameScreen({super.key, required this.onContinue});

  final ValueChanged<String> onContinue;

  @override
  State<ProjectNameScreen> createState() => _ProjectNameScreenState();
}

class _ProjectNameScreenState extends State<ProjectNameScreen> {
  final _speech = SpeechService();
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech.initialize().then((_) {
      if (!mounted) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _speech.stop();
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
    final p = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('New project')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Name this inspection project',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Photos and videos are saved to a SpeakEasyReports album on your iPhone, grouped under this project name.',
            style: TextStyle(color: p.textMuted),
          ),
          const SizedBox(height: 20),
          VoiceInputField(
            label: 'Project name *',
            controller: _controller,
            speech: _speech,
            active: true,
            onFocus: () {},
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Continue', icon: Icons.arrow_forward, onPressed: _continue),
        ],
      ),
    );
  }
}