import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app_state.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/voice_input_field.dart';
import 'inspect_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _speech = SpeechService();
  String _focus = 'clientName';

  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _email;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final s = widget.state.activeSession!;
    _name = TextEditingController(text: s.clientName);
    _address = TextEditingController(text: s.siteAddress);
    _email = TextEditingController(text: s.clientEmail);
    _note = TextEditingController(text: s.jobDescription);
    _speech.initialize().then((_) {
      if (!mounted) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _focus = 'clientName');
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _email.dispose();
    _note.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _setFocus(String key) async {
    if (_focus == key) return;
    await _speech.stop();
    setState(() => _focus = key);
  }

  Future<void> _continue() async {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client name and site address are required.')),
      );
      return;
    }
    await _speech.stop();
    final s = widget.state.activeSession!;
    s.clientName = _name.text.trim();
    s.siteAddress = _address.text.trim();
    s.clientEmail = _email.text.trim();
    s.jobDescription = _note.text.trim();
    s.jobReference = s.clientName;
    await widget.state.saveSession(s);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => InspectScreen(state: widget.state)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Tap a field to start speaking, or use the keyboard for typing.', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          VoiceInputField(
            label: 'Client name *',
            controller: _name,
            speech: _speech,
            active: _focus == 'clientName',
            onFocus: () => _setFocus('clientName'),
          ),
          VoiceInputField(
            label: 'Site address *',
            controller: _address,
            speech: _speech,
            active: _focus == 'siteAddress',
            onFocus: () => _setFocus('siteAddress'),
          ),
          VoiceInputField(
            label: 'Email',
            controller: _email,
            speech: _speech,
            keyboardType: TextInputType.emailAddress,
            stripSpaces: true,
            active: _focus == 'clientEmail',
            onFocus: () => _setFocus('clientEmail'),
          ),
          VoiceInputField(
            label: 'Job note',
            controller: _note,
            speech: _speech,
            maxLines: 3,
            active: _focus == 'jobDescription',
            onFocus: () => _setFocus('jobDescription'),
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Start inspection', icon: Icons.arrow_forward, onPressed: _continue),
        ],
      ),
    );
  }
}