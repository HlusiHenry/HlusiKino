import SwiftUI
import WebKit

// MARK: - Channel Player View

struct ChannelPlayerView: View {
    let channel: SportChannel
    @Environment(\.dismiss) var dismiss
    @State private var useFallback = false
    @State private var isLoading = true

    private var currentURL: String {
        useFallback ? (channel.fallbackURL ?? channel.url) : channel.url
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Player
                ZStack {
                    Color.black
                    EmbedWebView(urlString: currentURL)

                    if isLoading {
                        ProgressView().tint(.white)
                    }
                }

                // Controls
                HStack {
                    Text(channel.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: "#fafafa))
                    Text("· \(channel.country)")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#a1a1aa))
                    Spacer()

                    if channel.fallbackURL != nil {
                        Button(useFallback ? "Source 1" : "Source 2") {
                            useFallback.toggle()
                            isLoading = true
                        }
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: "#3b82f6))
                    }

                    Button {
                        isLoading = true
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color(hex: "#a1a1aa))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(hex: "#09090b"))
            }
            .background(Color.black)
            .navigationTitle("Live")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(hex: "#52525b))
                    }
                }
            }
        }
    }
}
