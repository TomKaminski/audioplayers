package xyz.luan.audioplayers

import android.content.Context
import android.os.Handler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import java.lang.ref.WeakReference

class AudioplayersPlugin : MethodCallHandler, FlutterPlugin {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    private val mediaPlayers = mutableMapOf<String, WrappedSoundPool>()
    private val handler = Handler()
    private var positionUpdates: Runnable? = null

    private var seekFinish = false

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "xyz.luan/audioplayers")
        context = binding.applicationContext
        seekFinish = false
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {}
    override fun onMethodCall(call: MethodCall, response: MethodChannel.Result) {
        try {
            handleMethodCall(call, response)
        } catch (e: Exception) {
            response.error("Unexpected error!", e.message, e)
        }
    }

    private fun handleMethodCall(call: MethodCall, response: MethodChannel.Result) {
        val playerId = call.argument<String>("playerId") ?: return
        val player = getPlayer(playerId)
        when (call.method) {
            "play" -> {
                val url = call.argument<String>("url")!!
                player.setUrl(url)
                player.play()
            }
            "resume" -> player.play()
            "pause" -> player.pause()
            "stop" -> player.stop()
            "release" -> player.release()
            "setUrl" -> {
                val url = call.argument<String>("url") !!
                player.setUrl(url)
            }
            else -> {
                response.notImplemented()
                return
            }
        }
        response.success(1)
    }

    private fun getPlayer(playerId: String): WrappedSoundPool {
        return WrappedSoundPool(playerId)
    }

    fun getApplicationContext(): Context {
        return context.applicationContext
    }

    companion object {
        private fun buildArguments(playerId: String, value: Any): Map<String, Any> {
            return mapOf(
                    "playerId" to playerId,
                    "value" to value
            )
        }

        private fun error(message: String): Exception {
            return IllegalArgumentException(message)
        }
    }
}

private inline fun <reified T: Enum<T>> MethodCall.enumArgument(name: String): T? {
    val enumName = argument<String>(name) ?: return null
    return enumValueOf<T>(enumName.split('.').last())
}
