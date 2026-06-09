import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _ready = false;
  int _listenGeneration = 0;

  Future<bool> initialize() async {
    _ready = await _speech.initialize(
      onStatus: (_) {},
      onError: (_) {},
    );
    return _ready;
  }

  bool get isListening => _speech.isListening;

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'en_AU',
  }) async {
    if (!_ready) {
      _ready = await initialize();
    }
    if (!_ready) return;

    if (_speech.isListening) {
      await _speech.stop();
    }

    final generation = ++_listenGeneration;
    await _speech.listen(
      onResult: (result) {
        if (generation != _listenGeneration) return;
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
      ),
    );
  }

  Future<void> stop() async {
    _listenGeneration++;
    if (_speech.isListening) {
      await _speech.stop();
    }
  }
}