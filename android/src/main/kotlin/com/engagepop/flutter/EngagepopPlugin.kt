package com.engagepop.flutter

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.engagepop.EngagePop
import com.engagepop.EngagePopConfig
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Flutter bridge over the native EngagePop Android SDK. */
class EngagepopPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private lateinit var deepLinkEvents: EventChannel
    private lateinit var inboxEvents: EventChannel
    private val main = Handler(Looper.getMainLooper())

    private var deepLinkSink: EventChannel.EventSink? = null
    private var inboxSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "engagepop")
        channel.setMethodCallHandler(this)

        deepLinkEvents = EventChannel(binding.binaryMessenger, "engagepop/deeplinks")
        deepLinkEvents.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { deepLinkSink = events }
            override fun onCancel(arguments: Any?) { deepLinkSink = null }
        })

        inboxEvents = EventChannel(binding.binaryMessenger, "engagepop/inbox")
        inboxEvents.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { inboxSink = events }
            override fun onCancel(arguments: Any?) { inboxSink = null }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        deepLinkEvents.setStreamHandler(null)
        inboxEvents.setStreamHandler(null)
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

            // Inbox
            "getInbox" -> {
                val list = EngagePop.inbox?.messages()?.map { m ->
                    mapOf(
                        "id" to m.id, "title" to m.title, "body" to m.body,
                        "url" to m.url, "receivedAt" to m.receivedAt, "read" to m.read,
                    )
                } ?: emptyList<Map<String, Any?>>()
                result.success(list)
            }
            "unreadCount" -> result.success(EngagePop.inbox?.unreadCount() ?: 0)
            "markRead" -> { EngagePop.inbox?.markRead(call.argument<String>("id") ?: ""); result.success(null) }
            "markAllRead" -> { EngagePop.inbox?.markAllRead(); result.success(null) }
            "removeMessage" -> { EngagePop.inbox?.remove(call.argument<String>("id") ?: ""); result.success(null) }
            "clearInbox" -> { EngagePop.inbox?.clear(); result.success(null) }

            else -> result.notImplemented()
        }
    }

    private fun configure(call: MethodCall) {
        val site = call.argument<String>("siteKey") ?: ""
        val app = call.argument<String>("appKey") ?: ""
        val base = call.argument<String>("apiBaseUrl") ?: "https://edge.engagepop.com"
        val debug = call.argument<Boolean>("debugLogging") ?: false
        val autoShow = call.argument<Boolean>("autoShowInAppMessages") ?: true
        EngagePop.configure(context, EngagePopConfig(site, app, base, debug, autoShow))
        // Event sinks must be touched on the main thread.
        EngagePop.deepLinkHandler = { url -> main.post { deepLinkSink?.success(url) } }
        EngagePop.inbox?.onChanged = { main.post { inboxSink?.success(null) } }
    }

    @Suppress("UNCHECKED_CAST")
    private fun stringMap(map: Map<String, Any?>?): Map<String, String> {
        if (map == null) return emptyMap()
        val out = HashMap<String, String>()
        for ((k, v) in map) if (v is String) out[k] = v
        return out
    }
}
