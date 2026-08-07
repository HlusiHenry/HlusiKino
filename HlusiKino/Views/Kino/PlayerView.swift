import SwiftUI
import WebKit

// MARK: - Player View

struct PlayerView: View {
    let item: MediaItem
    var season: Int? = nil
    var episode: Int? = nil
    var channelURL: String? = nil

    @Environment(\.dismiss) var dismiss
    @State private var sourceIndex = 0
    @State private var isLoading = true
    @State private var playerKey = UUID() // force WKWebView recreate on source change

    private let sources = [
        "https://nontongo.win/embed",
        "https://vidsrc.net/embed",
        "https://vidlink.pro/movie",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    Color.black

                    if let chURL = channelURL {
                        EmbedWebView(urlString: chURL, isLoading: $isLoading)
                            .id(playerKey)
                    } else {
                        EmbedWebView(urlString: currentURL, isLoading: $isLoading)
                            .id(playerKey)
                    }

                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                            Text("Loading...")
                                .font(.caption)
                                .foregroundStyle(Color(hex: "#a1a1aa"))
                        }
                    }
                }

                // Controls
                if channelURL == nil {
                    HStack {
                        Button {
                            sourceIndex = (sourceIndex + 1) % sources.count
                            playerKey = UUID()
                            isLoading = true
                        } label: {
                            Label("Source \(sourceIndex + 1)/\(sources.count)", systemImage: "arrow.triangle.swap")
                                .font(.caption)
                                .foregroundStyle(Color(hex: "#3b82f6"))
                        }

                        Spacer()

                        Button {
                            playerKey = UUID()
                            isLoading = true
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .foregroundStyle(Color(hex: "#a1a1aa"))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#09090b"))
                }
            }
            .background(Color.black)
            .navigationTitle(channelURL != nil ? channelName : item.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(hex: "#52525b"))
                            .font(.title3)
                    }
                }
            }
        }
    }

    private var channelName: String {
        // Extract something readable from the URL
        "Live Stream"
    }

    private var currentURL: String {
        let type = item.inferredType
        if type == .tv, let s = season, let e = episode {
            return "\(sources[sourceIndex])/tv/\(item.id)/\(s)/\(e)"
        }
        return "\(sources[sourceIndex])/movie/\(item.id)"
    }
}

// MARK: - Embed WebView

struct EmbedWebView: UIViewRepresentable {
    let urlString: String
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator { Coordinator(isLoading: $isLoading) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true

        // Critical for autoplay
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
        }

        // Allow all content
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        // User script to attempt autoplay
        let autoplayScript = WKUserScript(
            source: """
            document.addEventListener('DOMContentLoaded', function() {
                var vids = document.getElementsByTagName('video');
                for (var i = 0; i < vids.length; i++) {
                    vids[i].play().catch(function() {});
                }
                var iframes = document.getElementsByTagName('iframe');
                for (var j = 0; j < iframes.length; j++) {
                    try {
                        var iframeDoc = iframes[j].contentDocument || iframes[j].contentWindow.document;
                        if (iframeDoc) {
                            var iframeVids = iframeDoc.getElementsByTagName('video');
                            for (var k = 0; k < iframeVids.length; k++) {
                                iframeVids[k].play().catch(function() {});
                            }
                        }
                    } catch(e) {}
                }
            });
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(autoplayScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        webView.load(request)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        @Binding var isLoading: Bool

        init(isLoading: Binding<Bool>) {
            self._isLoading = isLoading
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Handle popups by loading in same webView
            if let url = navigationAction.request.url {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}
