// SpeakEasy Reports — FlutterFlow Custom Action
// Add dependency in FlutterFlow: speech_to_text ^7.0.0, permission_handler ^11.0.0
//
// Action: startDictation
// Returns: String (latest phrase) — wire to App State "dictationPreview"
// Call stopDictation when mic button toggled off.

import 'package:speech_to_text/speech_to_text.dart' as stt;

Future<String> startDictation(
  bool continuous,
  String localeId,
) async {
  final speech = stt.SpeechToText();
  final available = await speech.initialize(
    onStatus: (status) {},
    onError: (error) {},
  );
  if (!available) return '';

  // On-device preferred on iOS when offline (system handles routing).
  await speech.listen(
    localeId: localeId.isEmpty ? 'en_AU' : localeId,
    listenMode: continuous ? stt.ListenMode.dictation : stt.ListenMode.confirmation,
    partialResults: true,
    onResult: (result) {
      // FlutterFlow: assign result.recognizedWords to FFAppState dictationPreview
      // Use a Custom Action callback pattern or update via return on stop.
    },
  );

  return speech.lastRecognizedWords;
}