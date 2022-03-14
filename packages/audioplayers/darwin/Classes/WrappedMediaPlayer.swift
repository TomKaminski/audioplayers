import AVKit

class WrappedMediaPlayer {
    var reference: SwiftAudioplayersPlugin
    
    var playerId: String
    var player: AVAudioPlayer?
    
    var isPlaying: Bool
    var url: String?
    var onReady: ((AVAudioPlayer) -> Void)?
    
    init(
        reference: SwiftAudioplayersPlugin,
        playerId: String,
        player: AVAudioPlayer? = nil,        
        isPlaying: Bool = false,
        url: String? = nil,
        onReady: ((AVAudioPlayer) -> Void)? = nil
    ) {
        self.reference = reference
        self.playerId = playerId
        self.player = player        
        self.isPlaying = isPlaying
        self.url = url
        self.onReady = onReady
    }
        
    func getDurationCMTime() -> CMTime? {
        return nil
    }
    
    func getDuration() -> Int? {
        return nil
    }
    
    private func getCurrentCMTime() -> CMTime? {
        return nil
    }
    
    func getCurrentPosition() -> Int? {
        return nil
    }
    
    func pause() {
        isPlaying = false
        player?.pause()
    }
    
    func resume() {
        isPlaying = true
        player?.play()
    }
    
    func stop() {
        player?.stop()
    }
    
    func release() {
        player?.stop()
    }
    
    func onTimeInterval(time: CMTime) {}
    
    func setUrl(
        url: String,
        onReady: @escaping (AVAudioPlayer) -> Void
    ) {
        reference.updateCategory()
        do {
            if self.url != url {
            let parsedUrl = URL.init(fileURLWithPath: url.deletingPrefix("file://"))
            let player: AVAudioPlayer
            if let existingPlayer = self.player, existingPlayer.url == parsedUrl {
                self.url = url
                player = existingPlayer
            } else {
                player = try AVAudioPlayer(contentsOf: parsedUrl)
                
                self.player = player
                self.url = url
            }
            
            self.onReady = onReady
            if let onReady = self.onReady {
                self.onReady = nil
                onReady(self.player!)
            }
        } else {
            onReady(player!)
        }
        } catch {
            print(error)
        }
        
    }
    
    func play(url: String) {
        reference.updateCategory()
        
        setUrl(url: url) {
            player in
            player.volume = Float(1)
            self.resume()
        }
    }
}
