import AVKit
import AVFoundation
import Flutter
import UIKit
import MediaPlayer


let OS_NAME = "iOS"
let ENABLE_NOTIFICATIONS_HANDLER = true
let CHANNEL_NAME = "xyz.luan/audioplayers"
let AudioplayersPluginStop = NSNotification.Name("AudioplayersPluginStop")

public class SwiftAudioplayersPlugin: NSObject, FlutterPlugin {
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    
    var players = [String : WrappedMediaPlayer]()
    
    var isDealloc = false
    
    init(registrar: FlutterPluginRegistrar, channel: FlutterMethodChannel) {
        self.registrar = registrar
        self.channel = channel
        
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.needStop), name: AudioplayersPluginStop, object: nil)
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let binaryMessenger = registrar.messenger()
        let channel = FlutterMethodChannel(name: CHANNEL_NAME, binaryMessenger: binaryMessenger)
        let instance = SwiftAudioplayersPlugin(registrar: registrar, channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    @objc func needStop() {
        isDealloc = true
        destroy()
    }
    
    func destroy() {
        self.players = [:]
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let method = call.method
        
        guard let args = call.arguments as? [String: Any] else {
            result(0)
            return
        }

        guard let playerId = args["playerId"] as? String else {
            result(0)
            return
        }
        
        let player = self.getOrCreatePlayer(playerId: playerId)
        
        if method == "play" {
            guard let url = args["url"] as! String? else {
                result(0)
                return
            }
            
            player.play(url: url)
        } else if method == "pause" {
            player.pause()
        } else if method == "resume" {
            player.resume()
        } else if method == "stop" {
            player.stop()
        } else if method == "release" {
            player.release()
        } else if method == "setUrl" {
            let url: String? = args["url"] as? String
            
            if url == nil {
                result(0)
                return
            }
            
            player.setUrl(url: url!) {
                player in
                result(1)
            }
        }  else {
            result(FlutterMethodNotImplemented)
            return
        }
        
        // shortcut to avoid requiring explicit call of result(1) everywhere
        if method != "setUrl" {
            result(1)
        }
    }
    
    func getOrCreatePlayer(playerId: String) -> WrappedMediaPlayer {
        if let player = players[playerId] {
            return player
        }
        let newPlayer = WrappedMediaPlayer(
            reference: self,
            playerId: playerId
        )
        players[playerId] = newPlayer
        return newPlayer
    }
    
    func updateCategory() {
        let category = AVAudioSession.Category.playback        
        configureAudioSession(category: category, options: [])
    }
    
    func maybeDeactivateAudioSession() {
        let hasPlaying = players.values.contains { player in player.isPlaying }
        if !hasPlaying {
            #if os(iOS)
            configureAudioSession(active: false)
            #endif
        }
    }
    
    #if os(iOS)
    private func configureAudioSession(
        category: AVAudioSession.Category? = nil,
        options: AVAudioSession.CategoryOptions = [],
        active: Bool? = nil
    ) {
        do {
            let session = AVAudioSession.sharedInstance()
            if let category = category {
                try session.setCategory(category, options: options)
            }
            if let active = active {
                try session.setActive(active)
            }
        } catch {
            print("\(error)")
        }
    }
    #endif
}
