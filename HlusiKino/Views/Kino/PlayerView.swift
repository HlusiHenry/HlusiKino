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
    @State private var playerKey = UUID()

    private let sources = [
        ("nontongo.win", "https://nontongo.win/embed"),
        ("vidsrc.to", "https://vidsrc.to/embed"),
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
                            ProgressView().tint(.white)
                            Text("Loading stream...")
                                .font(.caption)
                                .foregroundStyle(Color(hex: "#a1a1aa"))
                        }
                    }
                }

                // Source switcher (movies/shows only)
                if channelURL == nil {
                    HStack {
                        Button {
                            sourceIndex = (sourceIndex + 1) % sources.count
                            playerKey = UUID()
                            isLoading = true
                        } label: {
                            Label("\(sources[sourceIndex].0) (\(sourceIndex + 1)/\(sources.count))", systemImage: "arrow.triangle.swap")
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
            .navigationTitle(channelURL != nil ? "Live Stream" : item.displayTitle)
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

    private var currentURL: String {
        let type = item.inferredType
        if type == .tv, let s = season, let e = episode {
            return "\(sources[sourceIndex].1)/tv/\(item.id)/\(s)/\(e)"
        }
        return "\(sources[sourceIndex].1)/movie/\(item.id)"
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

        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
        }

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        // User script: add playsinline+autoplay to all video elements
        let autoplayScript = WKUserScript(
            source: """
            (function() {
                function fixVideos() {
                    var vids = document.querySelectorAll('video');
                    vids.forEach(function(v) {
                        v.setAttribute('playsinline', '');
                        v.setAttribute('autoplay', '');
                        v.muted = true;
                        v.play().catch(function(){});
                    });
                }
                fixVideos();
                new MutationObserver(fixVideos).observe(document.body || document.documentElement, {childList: true, subtree: true});
                setInterval(fixVideos, 2000);
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(autoplayScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.setValue("https://nontongo.win/", forHTTPHeaderField: "Referer")
        webView.load(request)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        @Binding var isLoading: Bool

        init(isLoading: Binding<Bool>) {
            self._isLoading = isLoading
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { [weak self] in self?.isLoading = false }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { [weak self] in self?.isLoading = false }
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
    }
}
