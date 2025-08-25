
import Foundation

protocol SoundManaging {
    func playSound(sound: SoundManager.SoundOption, volume: Float)
}

extension SoundManager: SoundManaging {}

class MockSoundManager: SoundManaging {
    func playSound(sound: SoundManager.SoundOption, volume: Float) {
        print("Playing sound: \(sound) at volume \(volume)")
    }
}
