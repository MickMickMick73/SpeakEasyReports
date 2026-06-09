import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _ready = false;
  int _listenGeneration = 0;
  bool _continuous = false;
  String _lastPartial = '';
  void Function(String text, bool isFinal)? _onResult;

  Future<bool> initialize() async {
    _ready = await _speech.initialize(
      onStatus: _handleStatus,
      onError: (_) {},
    );
    return _ready;
  }

  bool get isListening => _speech.isListening;

  String get lastPartial => _lastPartial;

  void _handleStatus(String status) {
    if (!_continuous || !_ready) return;
    if (status == 'done' || status == 'notListening') {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (_continuous && !_speech.isListening) {
          _startSession();
        }
      });
    }
  }

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'en_AU',
    bool continuous = false,
  }) async {
    _onResult = onResult;
    _continuous = continuous;
    _lastPartial = '';
    if (!_ready) {
      _ready = await initialize();
    }
    if (!_ready) return;

    if (_speech.isListening) {
      await _speech.stop();
    }

    await _startSession(localeId: localeId);
  }

  Future<void> _startSession({String localeId = 'en_AU'}) async {
    if (!_ready || _onResult == null) return;

    final generation = ++_listenGeneration;
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (generation != _listenGeneration) return;
        final text = result.recognizedWords;
        if (!result.finalResult) {
          _lastPartial = text;
        } else {
          _lastPartial = '';
        }
        _onResult?.call(text, result.finalResult);
      },
      listenFor: const Duration(minutes: 30),
      pauseFor: const Duration(seconds: 4),
      listenOptions: stt.SpeechListenOptions(
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
      ),
    );
  }

  Future<String> stop({bool keepPartial = false}) async {
    _continuous = false;
    _listenGeneration++;
    final partial = _lastPartial.trim();
    if (_speech.isListening) {
      await _speech.stop();
    }
    _lastPartial = '';
    _onResult = null;
    return keepPartial ? partial : '';
  }
}