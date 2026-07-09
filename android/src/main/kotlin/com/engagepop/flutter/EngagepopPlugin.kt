package com.engagepop.flutter

import android.content.Context
import com.engagepop.EngagePop
import com.engagepop.EngagePopConfig
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Flutter bridge over the native EngagePop Android SDK. */
class EngagepopPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private lateinit var events: EventChannel
    private var sink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "engagepop")
        channel.setMethodCallHandler(this)
        events = EventChannel(binding.binaryMessenger, "engagepop/deeplinks")
        events.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        events.setStreamHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "configure" -> { configure(call); result.success(null) }
            "requestPushPermission" -> result.success(true) // needs an Activity — see README
            "identify" -> { EngagePop.identify(stringMap(call.argument("attributes"))); result.success(null) }
            "track" -> {
                EngagePop.track(call.argument<String>("event") ?: "", stringMap(call.argument("properties")))
                result.success(null)
            }
            "convert" -> {
                val value = call.argument<Double>("value") ?: 0.0
                val id = call.argument<Int>("campaignId")?.toLong()?.takeIf { it > 0 }
                EngagePop.convert(value, call.argument("order"), id)
                result.success(null)
            }
            "reset" -> { EngagePop.reset(); result.success(null) }
            "refreshInAppMessages" -> { EngagePop.refreshInAppMessages(); result.success(null) }
            else -> result.notImplemented()
        }
    }

    private fun configure(call: MethodCall) {
        val site = call.argument<String>("siteKey") ?: ""
        val app = call.argument<String>("appKey") ?: ""
        val base = call.argument<String>("apiBaseUrl") ?: "https://edge.engagepop.com"
        val debug = call.argument<Boolean>("debugLogging") ?: false
        EngagePop.configure(context, EngagePopConfig(site, app, base, debug))
        EngagePop.deepLinkHandler = { url -> sink?.success(url) }
    }

    @Suppress("UNCHECKED_CAST")
    private fun stringMap(map: Map<String, Any?>?): Map<String, String> {
        if (map == null) return emptyMap()
        val out = HashMap<String, String>()
        for ((k, v) in map) if (v is String) out[k] = v
        return out
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }
}
