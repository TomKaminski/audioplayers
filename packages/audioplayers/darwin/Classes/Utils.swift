import AVKit

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}

class TimeObserver {
    let player: AVAudioPlayer
    let observer: Any
    
    init(
        player: AVAudioPlayer,
        observer: Any
    ) {
        self.player = player
        self.observer = observer
    }
}
