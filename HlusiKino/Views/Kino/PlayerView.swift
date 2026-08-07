import SwiftUI
import WebKit

// MARK: - Player View (WKWebView for streaming embeds)

struct PlayerView: View {
    let item: MediaItem
    var season: Int? = nil
    var episode: Int? = nil
    var channelURL: String? = nil  // For sport channels

    @Environment(\.dismiss) var dismiss
    @State private var sourceIndex = 0
    @State private var isLoading = true

    private let sources = [
        "https://nontongo.win/embed",
        "https://vidsrc.net/embed",
        "https://vidlink.pro/movie",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Player
                ZStack {
                    Color.black

                    if channelURL != nil {
                        EmbedWebView(urlString: channelURL!)
                    } else {
                        EmbedWebView(urlString: currentURL)
                    }

                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }

                // Controls
                if channelURL == nil {
                    HStack {
                        Text("Source \(sourceIndex + 1)/\(sources.count)")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "#a1a1aa"))

                        Spacer()

                        Button("Next Source") {
                            sourceIndex = (sourceIndex + 1) % sources.count
                            isLoading = true
                        }
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: "#3b82f6"))

                        Button {
                            isLoading = true
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(Color(hex: "#a1a1aa"))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#09090b"))
                }

                // Season/Episode picker (TV only)
                if item.inferredType == .tv, channelURL == nil {
                    HStack(spacing: 12) {
                        Text("S\(season ?? 1) E\(episode ?? 1)")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "#a1a1aa"))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
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
                    }
                }
            }
        }
    }

    private var currentURL: String {
        let type = item.inferredType == .tv ? "tv" : "movie"
        if type == "tv", let s = season, let e = episode {
            return "\(sources[sourceIndex])/tv/\(item.id)/\(s)/\(e)"
        }
        return "\(sources[sourceIndex])/movie/\(item.id)"
    }
}

// MARK: - Embed WebView

struct EmbedWebView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Loading state handled by parent
        }
    }
}
