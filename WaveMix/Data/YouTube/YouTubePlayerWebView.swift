import SwiftUI
import WebKit

/// State reported by YouTube IFrame Player API
public enum YouTubePlayerState: Int, Sendable {
    case unstarted = -1
    case ended = 0
    case playing = 1
    case paused = 2
    case buffering = 3
    case cued = 5
    case unknown = 999

    public init(rawValue: Int) {
        switch rawValue {
        case -1: self = .unstarted
        case 0: self = .ended
        case 1: self = .playing
        case 2: self = .paused
        case 3: self = .buffering
        case 5: self = .cued
        default: self = .unknown
        }
    }
}

/// Controller bridging Swift actions to the WKWebView embedded YouTube player
@MainActor
public final class YouTubePlayerController: ObservableObject {
    @Published public var state: YouTubePlayerState = .unstarted
    @Published public var currentTime: TimeInterval = 0
    @Published public var duration: TimeInterval = 0
    @Published public var isReady: Bool = false
    @Published public var playbackError: String? = nil

    fileprivate weak var webView: WKWebView?

    public init() {}

    public func loadVideo(videoID: String) {
        guard let webView = webView else { return }
        let js = "if (window.player && window.player.loadVideoById) { window.player.loadVideoById('\(videoID)'); }"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    public func play() {
        guard let webView = webView else { return }
        let js = "if (window.player && window.player.playVideo) { window.player.playVideo(); }"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    public func pause() {
        guard let webView = webView else { return }
        let js = "if (window.player && window.player.pauseVideo) { window.player.pauseVideo(); }"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    public func seek(to seconds: TimeInterval) {
        guard let webView = webView else { return }
        let js = "if (window.player && window.player.seekTo) { window.player.seekTo(\(seconds), true); }"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    public func stop() {
        guard let webView = webView else { return }
        let js = "if (window.player && window.player.stopVideo) { window.player.stopVideo(); }"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}

/// SwiftUI wrapper for official YouTube IFrame Player inside WKWebView.
/// Strict Compliance:
/// - Minimum 200x200 CSS pixels enforced.
/// - Controls enabled, playsinline enabled.
/// - Full attribution and controls intact.
/// - Immediately paused on app background transition.
public struct YouTubePlayerWebView: UIViewRepresentable {
    public let videoID: String
    @ObservedObject public var controller: YouTubePlayerController

    public init(videoID: String, controller: YouTubePlayerController) {
        self.videoID = videoID
        self.controller = controller
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller, videoID: videoID)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Register script message handler
        let contentController = configuration.userContentController
        contentController.add(context.coordinator, name: "wavemixBridge")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        context.coordinator.setupWebView(webView)

        loadPlayerHTML(in: webView)
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
        if context.coordinator.currentVideoID != videoID {
            context.coordinator.currentVideoID = videoID
            controller.loadVideo(videoID: videoID)
        }
    }

    private func loadPlayerHTML(in webView: WKWebView) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { width: 100%; height: 100%; background-color: #000; overflow: hidden; }
                #player { width: 100%; height: 100%; min-width: 200px; min-height: 200px; }
            </style>
        </head>
        <body>
            <div id="player"></div>
            <script>
                var tag = document.createElement('script');
                tag.src = "https://www.youtube.com/iframe_api";
                var firstScriptTag = document.getElementsByTagName('script')[0];
                firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

                var player;
                var timePoller;

                function onYouTubeIframeAPIReady() {
                    player = new YT.Player('player', {
                        height: '100%',
                        width: '100%',
                        videoId: '\(videoID)',
                        playerVars: {
                            'playsinline': 1,
                            'controls': 1,
                            'rel': 0,
                            'fs': 1,
                            'origin': 'https://wavemix.app',
                            'enablejsapi': 1,
                            'modestbranding': 1
                        },
                        events: {
                            'onReady': onPlayerReady,
                            'onStateChange': onPlayerStateChange,
                            'onError': onPlayerError
                        }
                    });
                }

                function onPlayerReady(event) {
                    window.webkit.messageHandlers.wavemixBridge.postMessage({
                        type: 'ready',
                        duration: player.getDuration()
                    });
                    startTimePoller();
                }

                function onPlayerStateChange(event) {
                    window.webkit.messageHandlers.wavemixBridge.postMessage({
                        type: 'stateChange',
                        state: event.data,
                        currentTime: player.getCurrentTime(),
                        duration: player.getDuration()
                    });
                }

                function onPlayerError(event) {
                    window.webkit.messageHandlers.wavemixBridge.postMessage({
                        type: 'error',
                        code: event.data
                    });
                }

                function startTimePoller() {
                    if (timePoller) clearInterval(timePoller);
                    timePoller = setInterval(function() {
                        if (player && player.getCurrentTime) {
                            window.webkit.messageHandlers.wavemixBridge.postMessage({
                                type: 'timeUpdate',
                                currentTime: player.getCurrentTime()
                            });
                        }
                    }, 500);
                }
            </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://wavemix.app"))
    }

    public class Coordinator: NSObject, WKScriptMessageHandler {
        private let controller: YouTubePlayerController
        fileprivate var currentVideoID: String
        private weak var webView: WKWebView?
        private var notificationObservers: [NSObjectProtocol] = []

        init(controller: YouTubePlayerController, videoID: String) {
            self.controller = controller
            self.currentVideoID = videoID
            super.init()
            setupBackgroundObserver()
        }

        deinit {
            for obs in notificationObservers {
                NotificationCenter.default.removeObserver(obs)
            }
        }

        func setupWebView(_ webView: WKWebView) {
            self.webView = webView
            controller.webView = webView
        }

        /// Strict enforcement: Pause immediately on app entering background or screen lock.
        private func setupBackgroundObserver() {
            let resignObs = NotificationCenter.default.addObserver(
                forName: UIApplication.willResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.enforceBackgroundPause()
            }

            let backgroundObs = NotificationCenter.default.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.enforceBackgroundPause()
            }

            notificationObservers.append(contentsOf: [resignObs, backgroundObs])
        }

        private func enforceBackgroundPause() {
            // Strictly pause YouTube player when screen locks or app backgrounds
            controller.pause()
        }

        public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let dict = message.body as? [String: Any],
                  let type = dict["type"] as? String else { return }

            Task { @MainActor in
                switch type {
                case "ready":
                    controller.isReady = true
                    if let dur = dict["duration"] as? Double {
                        controller.duration = dur
                    }
                case "stateChange":
                    if let stateVal = dict["state"] as? Int {
                        controller.state = YouTubePlayerState(rawValue: stateVal)
                    }
                    if let cur = dict["currentTime"] as? Double {
                        controller.currentTime = cur
                    }
                    if let dur = dict["duration"] as? Double {
                        controller.duration = dur
                    }
                case "timeUpdate":
                    if let cur = dict["currentTime"] as? Double {
                        controller.currentTime = cur
                    }
                case "error":
                    let code = dict["code"] as? Int ?? -1
                    controller.playbackError = "YouTube Error Code: \(code)"
                default:
                    break
                }
            }
        }
    }
}
