import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _ready = false;

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

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: localeId,
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
      ),
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }
}