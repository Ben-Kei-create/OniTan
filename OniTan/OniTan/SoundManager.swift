import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    var audioPlayer: AVAudioPlayer?

    enum SoundOption: String {
        case correct = "correct_sound" // placeholder filename
        case incorrect = "incorrect_sound" // placeholder filename
    }

    func playSound(sound: SoundOption) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            // In a real app, you might want to log this error
            print("Could not find sound file \(sound.rawValue).mp3")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
}
