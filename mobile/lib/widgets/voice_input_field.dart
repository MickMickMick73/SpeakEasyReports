import 'package:flutter/material.dart';

import '../services/speech_service.dart';
import '../theme/app_theme.dart';

class VoiceInputField extends StatefulWidget {
  const VoiceInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.speech,
    this.keyboardType,
    this.maxLines = 1,
    this.stripSpaces = false,
    this.active = false,
    required this.onFocus,
  });

  final String label;
  final TextEditingController controller;
  final SpeechService speech;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool stripSpaces;
  final bool active;
  final VoidCallback onFocus;

  @override
  State<VoiceInputField> createState() => _VoiceInputFieldState();
}

class _VoiceInputFieldState extends State<VoiceInputField> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final FocusNode _focusNode;
  String _preview = '';
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant VoiceInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _startListening();
    } else if (!widget.active && oldWidget.active) {
      _stopListening();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (_listening) return;
    setState(() {
      _listening = true;
      _preview = '';
    });
    await widget.speech.startListening(onResult: (text, isFinal) {
      if (!mounted) return;
      var value = text;
      if (widget.stripSpaces) value = value.replaceAll(' ', '');
      setState(() => _preview = value);
      if (isFinal && value.trim().isNotEmpty) {
        _commit(value.trim());
      }
    });
  }

  Future<void> _stopListening() async {
    if (!_listening) return;
    await widget.speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  void _commit(String text) {
    final current = widget.controller.text.trim();
    widget.controller.text = current.isEmpty ? text : '$current $text';
    setState(() => _preview = '');
  }

  void _acceptPreview() {
    if (_preview.trim().isEmpty) return;
    _commit(_preview.trim());
  }

  void _clearField() {
    widget.controller.clear();
    setState(() => _preview = '');
  }

  Future<void> _openKeyboard() async {
    await _stopListening();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.active && _listening;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (glow) ...[
                const SizedBox(width: 8),
                FadeTransition(
                  opacity: Tween(begin: 0.45, end: 1.0).animate(_pulse),
                  child: const Icon(Icons.mic, color: AppColors.primary, size: 18),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            onTap: widget.onFocus,
            decoration: InputDecoration(
              suffixIcon: glow ? const Icon(Icons.mic_none, color: AppColors.primary) : null,
            ),
          ),
          if (glow && _preview.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Text(_preview, style: const TextStyle(color: AppColors.textMuted)),
            ),
          if (widget.active) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _toolButton(Icons.check, 'Accept', _acceptPreview),
                const SizedBox(width: 8),
                _toolButton(Icons.clear, 'Clear', _clearField),
                const SizedBox(width: 8),
                _toolButton(Icons.keyboard, 'Keyboard', _openKeyboard),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback onPressed) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}