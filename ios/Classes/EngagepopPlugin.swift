import Flutter
import UIKit
import EngagePop

/// Flutter bridge over the native EngagePop iOS SDK.
public class EngagepopPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var deepLinkSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = EngagepopPlugin()
        let channel = FlutterMethodChannel(name: "engagepop", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
        let events = FlutterEventChannel(name: "engagepop/deeplinks", binaryMessenger: registrar.messenger())
        events.setStreamHandler(instance)
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
        EngagePop.configure(EngagePopConfig(siteKey: site, appKey: app, apiBaseURL: base, debugLogging: debug))
        EngagePop.shared.deepLinkHandler = { [weak self] url in
            self?.deepLinkSink?(url.absoluteString)
        }
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
