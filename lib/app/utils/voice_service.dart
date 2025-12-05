import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;
  SpeechToText get speech => _speech;

  Future<bool> init() async {
    print('is available or not here');
    try{
      _isAvailable = await _speech.initialize();
    }catch(e){
      print(e.toString());
    }
    print('==============');
    return _isAvailable;
  }

  void startListening(Function(String text) onResult) {
    print('started');
    if (!_isAvailable) {
      print('is not available');
      return;
    }

    _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      listenMode: ListenMode.dictation,
    );
  }

  void debugListening() {
    print('Voice Service Debug:');
    print('Is Available: $_isAvailable');
    print('Is Listening: ${_speech.isListening}');
  }

  Future<void> stopListening() async {
    print('voice stoped');
    await _speech.stop();
  }
}
