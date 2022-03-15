package xyz.luan.audioplayers

import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaDataSource
import android.media.SoundPool
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.net.URI
import java.net.URL
import java.util.*
import android.os.Build

class WrappedSoundPool internal constructor(val playerId: String) {
    companion object {
        private val soundPool = createSoundPool()

        /** For the onLoadComplete listener, track which sound id is associated with which player. An entry only exists until
         * it has been loaded.
         */
        private val soundIdToPlayer = Collections.synchronizedMap(mutableMapOf<Int, WrappedSoundPool>())

        /** This is to keep track of the players which share the same sound id, referenced by url. When a player release()s, it
         * is removed from the associated player list. The last player to be removed actually unloads() the sound id and then
         * the url is removed from this map.
         */
        private val urlToPlayers = Collections.synchronizedMap(mutableMapOf<String, MutableList<WrappedSoundPool>>())

        private fun createSoundPool(): SoundPool {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val attrs = AudioAttributes.Builder().setLegacyStreamType(AudioManager.USE_DEFAULT_STREAM_TYPE)
                        .setUsage(AudioAttributes.USAGE_GAME)
                        .build()
                // make a new SoundPool, allowing up to 100 streams
                SoundPool.Builder()
                        .setAudioAttributes(attrs)
                        .setMaxStreams(100)
                        .build()
            } else {
                // make a new SoundPool, allowing up to 100 streams
                @Suppress("DEPRECATION")
                SoundPool(100, AudioManager.STREAM_MUSIC, 0)
            }
        }

        init {
            soundPool.setOnLoadCompleteListener { _, sampleId, _ ->
                val loadingPlayer = soundIdToPlayer[sampleId]
                if (loadingPlayer != null) {
                    soundIdToPlayer.remove(loadingPlayer.soundId)
                    // Now mark all players using this sound as not loading and start them if necessary
                    synchronized(urlToPlayers) {
                        val urlPlayers = urlToPlayers[loadingPlayer.url] ?: listOf()
                        for (player in urlPlayers) {
                            player.loading = false
                            if (player.playing) {
                                player.start()
                            }
                        }
                    }
                }
            }
        }
    }

    private var url: String? = null
    var volume = 1.0f
    var rate = 1.0f
    var soundId: Int? = null
    var streamId: Int? = null
    var playing = false
    var paused = false
    var looping = false
    var loading = false

    fun play() {
        if (!loading) {
            start()
        }
        playing = true
        paused = false
    }

    fun stop() {
        if (playing) {
            streamId?.let { soundPool.stop(it) }
            playing = false
        }
        paused = false
    }

    fun release() {
        stop()
        val soundId = this.soundId ?: return
        val url = this.url ?: return

        synchronized(urlToPlayers) {
            val playersForSoundId = urlToPlayers[url] ?: return
            if (playersForSoundId.singleOrNull() === this) {
                urlToPlayers.remove(url)
                soundPool.unload(soundId)
                soundIdToPlayer.remove(soundId)
                this.soundId = null
            } else {
                // This is not the last player using the soundId, just remove it from the list.
                playersForSoundId.remove(this)
            }

        }
    }

    fun pause() {
        if (playing) {
            streamId?.let { soundPool.pause(it) }
        }
        playing = false
        paused = true
    }

    fun setUrl(url: String) {
        if (this.url != null && this.url == url) {
            return
        }
        if (soundId != null) {
            release()
        }
        synchronized(urlToPlayers) {
            this.url = url
            val urlPlayers = urlToPlayers.getOrPut(url) { mutableListOf() }
            val originalPlayer = urlPlayers.firstOrNull()

            if (originalPlayer != null) {
                // Sound has already been loaded - reuse the soundId.
                loading = originalPlayer.loading
                soundId = originalPlayer.soundId
            } else {
                // First one for this URL - load it.
                val start = System.currentTimeMillis()

                loading = true
                soundId = soundPool.load(getAudioPath(url), 1)
                soundIdToPlayer[soundId] = this
            }
            urlPlayers.add(this)
        }
    }

    private fun start() {
        if (paused) {
            streamId?.let { soundPool.resume(it) }
            paused = false
        } else {
            val soundId = this.soundId ?: return
            streamId = soundPool.play(
                    soundId,
                    volume,
                    volume,
                    0,
                    0,
                    1.0f
            )
        }
    }

    private fun getAudioPath(url: String?): String? {
        return url?.removePrefix("file://")
    }

    private fun downloadUrl(url: URL): ByteArray {
        val outputStream = ByteArrayOutputStream()
        url.openStream().use { stream ->
            val chunk = ByteArray(4096)
            while (true) {
                val bytesRead = stream.read(chunk).takeIf { it > 0 } ?: break
                outputStream.write(chunk, 0, bytesRead)
            }
        }
        return outputStream.toByteArray()
    }
}
