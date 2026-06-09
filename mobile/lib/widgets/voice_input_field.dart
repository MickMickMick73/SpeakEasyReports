import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _focusNode = FocusNode();
    if (widget.active) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _startListening());
    }
  }

  @override
  void didUpdateWidget(covariant VoiceInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      setState(() => _preview = '');
      _startListening();
    } else if (!widget.active && oldWidget.active) {
      _stopListening(clearPreview: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _normalize(String text) {
    return widget.stripSpaces ? text.replaceAll(' ', '') : text;
  }

  Future<void> _startListening() async {
    if (!widget.active || _listening || _starting) return;
    setState(() => _starting = true);
    await widget.speech.stop();
    if (!mounted || !widget.active) {
      if (mounted) setState(() => _starting = false);
      return;
    }
    setState(() {
      _listening = true;
      _starting = false;
    });
    await widget.speech.startListening(onResult: (text, isFinal) {
      if (!mounted || !widget.active) return;
      final value = _normalize(text);
      setState(() => _preview = value);
    });
  }

  Future<void> _stopListening({bool clearPreview = false}) async {
    await widget.speech.stop();
    if (!mounted) return;
    setState(() {
      _listening = false;
      _starting = false;
      if (clearPreview) _preview = '';
    });
  }

  void _commit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final current = widget.controller.text.trim();
    widget.controller.text = current.isEmpty ? trimmed : '$current $trimmed';
    setState(() => _preview = '');
  }

  Future<void> _acceptPreview() async {
    if (_preview.trim().isNotEmpty) {
      _commit(_preview);
      return;
    }
    if (_listening) {
      await _stopListening();
    }
  }

  Future<void> _clearField() async {
    widget.controller.clear();
    setState(() => _preview = '');
    if (widget.active) {
      await _startListening();
    }
  }

  Future<void> _openKeyboard() async {
    await _stopListening();
    _focusNode.requestFocus();
  }

  void _handleTap() {
    widget.onFocus();
    if (widget.active && !_listening && !_starting) {
      _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showMic = widget.active && (_listening || _starting);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (showMic) ...[
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
            onTap: _handleTap,
            decoration: InputDecoration(
              suffixIcon: showMic ? const Icon(Icons.mic_none, color: AppColors.primary) : null,
            ),
          ),
          if (widget.active && _preview.isNotEmpty)
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
                _toolButton(Icons.check, 'Accept', () => _acceptPreview()),
                const SizedBox(width: 8),
                _toolButton(Icons.clear, 'Clear', () => _clearField()),
                const SizedBox(width: 8),
                _toolButton(Icons.keyboard, 'Keyboard', () => _openKeyboard()),
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