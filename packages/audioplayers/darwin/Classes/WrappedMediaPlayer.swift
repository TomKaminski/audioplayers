import AVKit

private let defaultPlaybackRate: Double = 1.0
private let defaultVolume: Double = 1.0
private let defaultPlayingRoute = "speakers"

class WrappedMediaPlayer {
    var reference: SwiftAudioplayersPlugin
    
    var playerId: String
    var player: AVAudioPlayer?
    
    var isPlaying: Bool
    var playbackRate: Double
    var volume: Double
    var playingRoute: String
    var looping: Bool
    var url: String?
    var onReady: ((AVAudioPlayer) -> Void)?
    
    init(
        reference: SwiftAudioplayersPlugin,
        playerId: String,
        player: AVAudioPlayer? = nil,        
        isPlaying: Bool = false,
        playbackRate: Double = defaultPlaybackRate,
        volume: Double = defaultVolume,
        playingRoute: String = defaultPlayingRoute,
        looping: Bool = false,
        url: String? = nil,
        onReady: ((AVPlayer) -> Void)? = nil
    ) {
        self.reference = reference
        self.playerId = playerId
        self.player = player        
        self.isPlaying = isPlaying
        self.playbackRate = playbackRate
        self.volume = volume
        self.playingRoute = playingRoute
        self.looping = looping
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
        // update last player that was used
        reference.lastPlayerId = playerId
    }
    
    func setVolume(volume: Double) {
        self.volume = volume
        player?.volume = Float(volume)
    }
    
    func setPlaybackRate(playbackRate: Double) {
        self.playbackRate = playbackRate
        player?.rate = Float(playbackRate)
    }
    
    func seek(time: CMTime) {}
    
    func skipForward(interval: TimeInterval) {}
    
    func skipBackward(interval: TimeInterval) {}
    
    func stop() {
        player?.stop()
    }
    
    func release() {
        player?.stop()
    }
    
    func onSoundComplete() {}
    
    func onTimeInterval(time: CMTime) {
        if reference.isDealloc {
            return
        }
        let millis = fromCMTime(time: time)
        reference.onCurrentPosition(playerId: playerId, millis: millis)
    }
    
    func updateDuration() {}
    
    func setUrl(
        url: String,
        isLocal: Bool,
        isNotification: Bool,
        recordingActive: Bool,
        duckAudio: Bool,
        onReady: @escaping (AVAudioPlayer) -> Void
    ) {
        reference.updateCategory(
            recordingActive: recordingActive,
            isNotification: isNotification,
            playingRoute: playingRoute,
            duckAudio: duckAudio
        )
        
        if self.url != url {
            let parsedUrl = isLocal ? URL.init(fileURLWithPath: url.deletingPrefix("file://")) : URL.init(string: url)!
            let player: AVAudioPlayer
            if let existingPlayer = self.player, existingPlayer.url == parsedUrl {
                self.url = url
                player = existingPlayer
            } else {
                player = try! AVAudioPlayer(contentsOf: parsedUrl)
                
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
    }
    
    func play(
        url: String,
        isLocal: Bool,
        volume: Double,
        time: CMTime?,
        isNotification: Bool,
        recordingActive: Bool,
        duckAudio: Bool
    ) {
        reference.updateCategory(
            recordingActive: recordingActive,
            isNotification: isNotification,
            playingRoute: playingRoute,
            duckAudio: duckAudio
        )
        
        setUrl(
            url: url,
            isLocal: isLocal,
            isNotification: isNotification,
            recordingActive: recordingActive,
            duckAudio: duckAudio
        ) {
            player in
            player.volume = Float(volume)
            self.resume()
        }
        
        reference.lastPlayerId = playerId
    }
}
