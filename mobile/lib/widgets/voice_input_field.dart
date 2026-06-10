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
  bool _keyboardMode = false;
  int _speechEpoch = 0;

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
      setState(() {
        _keyboardMode = false;
        _preview = '';
      });
      _focusNode.unfocus();
      _startListening();
    } else if (!widget.active && oldWidget.active) {
      _stopListening(clearPreview: true);
      setState(() => _keyboardMode = false);
      _focusNode.unfocus();
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

  int _nextEpoch() {
    _speechEpoch++;
    return _speechEpoch;
  }

  bool _epochValid(int epoch) => mounted && widget.active && epoch == _speechEpoch;

  Future<void> _startListening() async {
    if (!widget.active || _listening || _starting || _keyboardMode) return;
    final epoch = _nextEpoch();
    setState(() => _starting = true);
    await widget.speech.stop();
    if (!_epochValid(epoch)) {
      if (mounted) setState(() => _starting = false);
      return;
    }
    setState(() {
      _listening = true;
      _starting = false;
    });
    await widget.speech.startListening(
      persistent: true,
      onResult: (text, isFinal) {
        if (!_epochValid(epoch)) return;
        final value = _normalize(text);
        if (value.trim().isEmpty) return;
        setState(() => _preview = value);
      },
    );
    if (mounted && _epochValid(epoch)) {
      setState(() => _listening = widget.speech.isListening || _starting);
    }
  }

  Future<void> _stopListening({bool clearPreview = false}) async {
    _nextEpoch();
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
  }

  Future<void> _acceptPreview() async {
    final pending = _preview.trim();
    final trailing = await widget.speech.stop(keepPartial: pending.isEmpty);
    _nextEpoch();
    final combined = [pending, trailing].where((part) => part.trim().isNotEmpty).join(' ').trim();
    if (combined.isNotEmpty) {
      _commit(combined);
    }
    if (!mounted) return;
    setState(() {
      _preview = '';
      _listening = false;
      _starting = false;
    });
  }

  Future<void> _clearField() async {
    _nextEpoch();
    await widget.speech.stop();
    widget.controller.clear();
    if (!mounted) return;
    setState(() {
      _preview = '';
      _listening = false;
      _starting = false;
      _keyboardMode = false;
    });
    _focusNode.unfocus();
  }

  Future<void> _openKeyboard() async {
    await _stopListening(clearPreview: false);
    if (!mounted) return;
    setState(() => _keyboardMode = true);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _handleTap() {
    widget.onFocus();
    if (!widget.active) return;
    if (_keyboardMode) return;
    if (!_listening && !_starting) {
      _startListening();
    }
  }

  Widget _micStatusIcon() {
    final listening = _listening || _starting;
    final color = listening ? AppColors.success : AppColors.danger;
    final icon = listening ? Icons.mic : Icons.mic_off;
    final child = Icon(icon, color: color, size: 20);
    if (!listening) return child;
    return FadeTransition(opacity: Tween(begin: 0.55, end: 1.0).animate(_pulse), child: child);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (widget.active) ...[
                const SizedBox(width: 8),
                _micStatusIcon(),
                const SizedBox(width: 6),
                Text(
                  (_listening || _starting) ? 'Recording' : 'Tap field to record',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: (_listening || _starting) ? AppColors.success : AppColors.danger,
                  ),
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
            readOnly: !_keyboardMode,
            showCursor: _keyboardMode,
            enableInteractiveSelection: _keyboardMode,
            onTap: _handleTap,
            decoration: InputDecoration(
              hintText: widget.active ? 'Tap to speak, or use Keyboard' : null,
              suffixIcon: widget.active ? _micStatusIcon() : null,
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
                border: Border.all(color: AppColors.success.withValues(alpha: 0.45)),
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

  Widget _toolButton(IconData icon, String label, Future<void> Function() onPressed) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => onPressed(),
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}