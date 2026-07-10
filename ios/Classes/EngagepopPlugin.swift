import Flutter
import UIKit
import EngagePop

/// Flutter bridge over the native EngagePop iOS SDK.
public class EngagepopPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var deepLinkSink: FlutterEventSink?
    private let inboxStream = EngagePopStreamHandler()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = EngagepopPlugin()
        let channel = FlutterMethodChannel(name: "engagepop", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
        let events = FlutterEventChannel(name: "engagepop/deeplinks", binaryMessenger: registrar.messenger())
        events.setStreamHandler(instance)
        let inbox = FlutterEventChannel(name: "engagepop/inbox", binaryMessenger: registrar.messenger())
        inbox.setStreamHandler(instance.inboxStream)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "configure":
            configure(args)
            result(nil)
        case "requestPushPermission":
            EngagePop.requestPushAuthorization { granted in result(granted) }
        case "identify":
            EngagePop.identify(args["attributes"] as? [String: String] ?? [:])
            result(nil)
        case "track":
            EngagePop.track(args["event"] as? String ?? "", properties: args["properties"] as? [String: String])
            result(nil)
        case "convert":
            let value = args["value"] as? Double ?? 0
            let id = (args["campaignId"] as? Int).flatMap { $0 > 0 ? Int64($0) : nil }
            EngagePop.convert(value: value, order: args["order"] as? String, campaignID: id)
            result(nil)
        case "reset":
            EngagePop.reset()
            result(nil)
        case "refreshInAppMessages":
            EngagePop.refreshInAppMessages()
            result(nil)
        case "getInbox":
            let messages = EngagePop.shared.inbox?.messages ?? []
            result(messages.map { [
                "id": $0.id, "title": $0.title, "body": $0.body,
                "url": $0.url as Any, "receivedAt": $0.receivedAt.timeIntervalSince1970, "read": $0.read,
            ] })
        case "unreadCount":
            result(EngagePop.shared.inbox?.unreadCount ?? 0)
        case "markRead":
            if let id = args["id"] as? String { EngagePop.shared.inbox?.markRead(id) }
            result(nil)
        case "markAllRead":
            EngagePop.shared.inbox?.markAllRead()
            result(nil)
        case "removeMessage":
            if let id = args["id"] as? String { EngagePop.shared.inbox?.remove(id) }
            result(nil)
        case "clearInbox":
            EngagePop.shared.inbox?.clear()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func configure(_ args: [String: Any]) {
        let site = args["siteKey"] as? String ?? ""
        let app = args["appKey"] as? String ?? ""
        let base = (args["apiBaseUrl"] as? String).flatMap { URL(string: $0) }
            ?? URL(string: "https://edge.engagepop.com")!
        let debug = args["debugLogging"] as? Bool ?? false
        let autoShow = args["autoShowInAppMessages"] as? Bool ?? true
        EngagePop.configure(EngagePopConfig(
            siteKey: site, appKey: app, apiBaseURL: base, debugLogging: debug, autoShowInAppMessages: autoShow
        ))
        EngagePop.shared.deepLinkHandler = { [weak self] url in
            self?.deepLinkSink?(url.absoluteString)
        }
        NotificationCenter.default.addObserver(
            forName: Inbox.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.inboxStream.sink?(nil) }
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        deepLinkSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        deepLinkSink = nil
        return nil
    }
}

/// A tiny stream handler that just holds a sink — used for the inbox-change
/// event channel (the plugin itself handles the deep-link channel).
final class EngagePopStreamHandler: NSObject, FlutterStreamHandler {
    var sink: FlutterEventSink?
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
}
