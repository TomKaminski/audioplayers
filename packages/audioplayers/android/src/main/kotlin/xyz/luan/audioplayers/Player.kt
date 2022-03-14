package xyz.luan.audioplayers

import android.media.MediaDataSource

abstract class Player {
    abstract val playerId: String

    abstract fun play()
    abstract fun stop()
    abstract fun release()
    abstract fun pause()

    abstract fun setUrl(url: String)
    abstract fun setVolume(volume: Double)

    companion object {
        @JvmStatic
        protected fun objectEquals(o1: Any?, o2: Any?): Boolean {
            return o1 == null && o2 == null || o1 != null && o1 == o2
        }
    }
}