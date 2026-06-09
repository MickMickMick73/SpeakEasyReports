import 'package:flutter/material.dart';

import '../app_state.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'inspect_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.state});

  final AppState state;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _speech = SpeechService();
  String _preview = '';
  bool _listening = false;
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
    _speech.initialize();
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

  void _append(String text) {
    switch (_focus) {
      case 'clientName':
        _name.text = _name.text.trim().isEmpty ? text : '${_name.text.trim()} $text';
      case 'siteAddress':
        _address.text = _address.text.trim().isEmpty ? text : '${_address.text.trim()} $text';
      case 'clientEmail':
        _email.text = _email.text.trim().isEmpty ? text : '${_email.text.trim()} $text';
      default:
        _note.text = _note.text.trim().isEmpty ? text : '${_note.text.trim()} $text';
    }
    setState(() {});
  }

  Future<void> _toggleSpeak() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() {
      _listening = true;
      _preview = '';
    });
    await _speech.startListening(onResult: (text, isFinal) {
      setState(() => _preview = text);
      if (isFinal && text.trim().isNotEmpty) {
        _append(text.trim());
      }
    });
  }

  Future<void> _continue() async {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client name and site address are required.')),
      );
      return;
    }
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
          const Text('Tap a field, type, or use Speak.', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          _field('Client name *', _name, 'clientName'),
          _field('Site address *', _address, 'siteAddress'),
          _field('Email', _email, 'clientEmail', keyboard: TextInputType.emailAddress),
          _field('Job note', _note, 'jobDescription', lines: 3),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _toggleSpeak,
            icon: Icon(_listening ? Icons.stop : Icons.mic),
            label: Text(_listening ? 'Listening… tap to stop' : 'Tap to speak into this field'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _listening ? AppColors.danger : AppColors.primary,
              minimumSize: const Size.fromHeight(56),
            ),
          ),
          if (_preview.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(_preview),
            ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Start inspection', icon: Icons.arrow_forward, onPressed: _continue),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, String key, {TextInputType? keyboard, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: c,
            keyboardType: keyboard,
            maxLines: lines,
            onTap: () => setState(() => _focus = key),
            onChanged: (_) => setState(() => _focus = key),
          ),
        ],
      ),
    );
  }
}