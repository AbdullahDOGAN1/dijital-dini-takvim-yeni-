import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  
  /// Play notification sound using just_audio
  static Future<void> playSound(String soundName) async {
    try {
      // Try with just_audio first
      await _player.setAsset('assets/sounds/$soundName.mp3');
      await _player.play();
      print('Successfully played sound: $soundName using just_audio');
    } catch (e) {
      print('Error playing sound with just_audio: $e');
      // Fallback can be added here if needed
    }
  }
  
  /// Stop currently playing sound
  static Future<void> stopSound() async {
    try {
      await _player.stop();
    } catch (e) {
      print('Error stopping sound: $e');
    }
  }
  
  /// Dispose audio player
  static Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (e) {
      print('Error disposing audio player: $e');
    }
  }
}
