import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    var audioPlayer: AVAudioPlayer?

    enum SoundOption: String {
        case correct = "Quiz-Ding_Dong"
        case incorrect = "Quiz-Buzzer"
    }

    func playSound(sound: SoundOption, volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = volume
            audioPlayer?.play()
        } catch {
            // In a real app, you might want to log this error
        }
    }
}
