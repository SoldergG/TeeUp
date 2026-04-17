import AVFoundation

/// Lightweight sound effects for score entry
enum SoundManager {
    private static var player: AVAudioPlayer?

    static func playSystemSound(_ id: SystemSoundID) {
        AudioServicesPlaySystemSound(id)
    }

    /// Subtle tick for score changes
    static func tick() {
        AudioServicesPlaySystemSound(1104)
    }

    /// Success sound for finishing a round
    static func success() {
        AudioServicesPlaySystemSound(1025)
    }

    /// Prepare audio session so sounds don't interrupt music
    static func configure() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}
