import SwiftUI
import WebKit

// MARK: - Detail View (Cast, Trailer, Seasons, Episodes)

struct DetailView: View {
    let item: MediaItem
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var detail: MediaItem?
    @State private var cast: [CastMember] = []
    @State private var trailerKey: String?
    @State private var trailerExpanded = false
    @State private var seasons: [Season] = []
    @State private var episodes: [Episode] = []
    @State private var selectedSeason: Int = 1
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if let d = detail {
                    VStack(spacing: 0) {
                        // Backdrop
                        ZStack(alignment: .bottomLeading) {
                            AsyncImage(url: TMDbService.shared.imageURL(d.backdropPath ?? item.posterPath, size: "original")) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fill)
                                default:
                                    Color(hex: "#18181b")
                                }
                            }
                            .frame(height: 250)
                            .clipped()
                            .overlay(
                                LinearGradient(stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: Color(hex: "#09090b"), location: 1)
                                ], startPoint: .top, endPoint: .bottom)
                            )

                            // Trailer button
                            if let key = trailerKey {
                                Button {
                                    trailerExpanded.toggle()
                                } label: {
                                    Label("Trailer", systemImage: "play.fill")
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(8)
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                                .padding(.leading, 20)
                                .padding(.bottom, 12)
                            }
                        }

                        // Info
                        VStack(alignment: .leading, spacing: 16) {
                            Text(d.displayTitle)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "#fafafa"))

                            // Meta row
                            HStack(spacing: 12) {
                                Label(d.displayRating, systemImage: "star.fill")
                                    .foregroundStyle(Color(hex: "#f59e0b"))
                                Text(d.displayYear)
                                Text((d.originalLanguage ?? "").uppercased())
                                Text(d.inferredType == .tv ? "Series" : "Movie")
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "#3b82f6").opacity(0.2))
                                    .cornerRadius(4)
                                if let rt = d.runtime {
                                    Text("\(rt / 60)h \(rt % 60)m")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(Color(hex: "#a1a1aa"))

                            // Genres
                            if let genres = d.genres, !genres.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(genres) { g in
                                            Text(g.name)
                                                .font(.caption2)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color(hex: "#27272a"))
                                                .cornerRadius(6)
                                                .foregroundStyle(Color(hex: "#a1a1aa"))
                                        }
                                    }
                                }
                            }

                            // Overview
                            if let overview = d.overview, !overview.isEmpty {
                                Text(overview)
                                    .font(.subheadline)
                                    .foregroundStyle(Color(hex: "#d4d4d8"))
                                    .lineSpacing(4)
                            }

                            // Action buttons
                            HStack(spacing: 12) {
                                Button {
                                    appState.selectedPlayer = item
                                    appState.showPlayer = true
                                } label: {
                                    Label("Play", systemImage: "play.fill")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(hex: "#3b82f6"))
                                        .cornerRadius(10)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.white)
                                }

                                Button {
                                    guard let profile = appState.currentProfile,
                                          let listName = appState.activeWatchlistName else { return }
                                    let inWL = appState.isInWatchlist(itemID: item.id)
                                    let img = item.posterPath ?? ""
                                    appState.toggleWatchlist(itemID: item.id, title: item.displayTitle, poster: img, type: item.inferredType == .tv ? .tv : .movie)
                                } label: {
                                    let inWL = appState.isInWatchlist(itemID: item.id)
                                    Label(inWL ? "In Watchlist" : "Watchlist", systemImage: inWL ? "checkmark" : "plus")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(hex: "#27272a"))
                                        .cornerRadius(10)
                                        .font(.subheadline)
                                        .foregroundStyle(Color(hex: "#fafafa"))
                                }
                            }

                            // Trailer expanded
                            if trailerExpanded, let key = trailerKey {
                                YouTubePlayer(videoKey: key)
                                    .frame(height: 220)
                                    .cornerRadius(12)
                            }

                            // Cast
                            if !cast.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Cast")
                                        .font(.headline)
                                        .foregroundStyle(Color(hex: "#fafafa"))
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(cast) { member in
                                                VStack(spacing: 6) {
                                                    AsyncImage(url: TMDbService.shared.imageURL(member.profilePath, size: "w185")) { phase in
                                                        switch phase {
                                                        case .success(let image):
                                                            image.resizable().aspectRatio(contentMode: .fill)
                                                        default:
                                                            Circle().fill(Color(hex: "#27272a"))
                                                        }
                                                    }
                                                    .frame(width: 64, height: 64)
                                                    .clipShape(Circle())

                                                    Text(member.name.components(separatedBy: " ").prefix(2).joined(separator: " "))
                                                        .font(.caption2)
                                                        .foregroundStyle(Color(hex: "#fafafa"))
                                                        .lineLimit(1)
                                                    Text(member.displayCharacter)
                                                        .font(.caption2)
                                                        .foregroundStyle(Color(hex: "#a1a1aa"))
                                                        .lineLimit(1)
                                                }
                                                .frame(width: 72)
                                            }
                                        }
                                    }
                                }
                            }

                            // Seasons & Episodes (TV only)
                            if !seasons.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Episodes")
                                        .font(.headline)
                                        .foregroundStyle(Color(hex: "#fafafa"))

                                    Picker("Season", selection: $selectedSeason) {
                                        ForEach(seasons) { s in
                                            Text("Season \(s.seasonNumber)").tag(s.seasonNumber)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .onChange(of: selectedSeason) { _, newSeason in
                                        Task { await loadEpisodes(tvID: item.id, season: newSeason) }
                                    }

                                    if episodes.isEmpty {
                                        ProgressView()
                                    } else {
                                        ForEach(episodes) { ep in
                                            EpisodeRow(episode: ep) {
                                                appState.selectedPlayer = item
                                                appState.selectedPlayerSeason = selectedSeason
                                                appState.selectedPlayerEpisode = ep.episodeNumber
                                                appState.showPlayer = true
                                            }
                                        }
                                    }
                                }
                            }

                            // Production companies + Links
                            if let homepage = d.homepage, !homepage.isEmpty {
                                Link(destination: URL(string: homepage)!) {
                                    Label("Website", systemImage: "globe")
                                        .font(.caption)
                                        .foregroundStyle(Color(hex: "#3b82f6"))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
            }
            .background(Color(hex: "#09090b"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(hex: "#52525b"))
                    }
                }
            }
            .task {
                await loadDetail()
            }
        }
    }

    private func loadDetail() async {
        let type = item.inferredType
        guard let d = try? await TMDbService.shared.detail(id: item.id, type: type) else {
            isLoading = false
            return
        }

        let credits = d.credits
        let videos = d.videos?.results
        let trailer = videos?.first(where: { $0.isYouTubeTrailer }) ?? videos?.first(where: { $0.isYouTube })

        await MainActor.run {
            detail = d
            cast = credits?.cast?.filter { $0.profilePath != nil }.map { $0 } ?? []
            trailerKey = trailer?.key
            if type == .tv {
                seasons = d.seasons?.filter { $0.seasonNumber > 0 && (($0.episodeCount ?? 0) > 0) } ?? []
                if let firstSeason = seasons.first?.seasonNumber {
                    selectedSeason = firstSeason
                    Task { await loadEpisodes(tvID: item.id, season: firstSeason) }
                }
            }
            isLoading = false
        }
    }

    private func loadEpisodes(tvID: Int, season: Int) async {
        guard let sd = try? await TMDbService.shared.seasonEpisodes(tvID: tvID, season: season) else { return }
        await MainActor.run { episodes = sd.episodes ?? [] }
    }
}

struct EpisodeRow: View {
    let episode: Episode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text("\(episode.episodeNumber)")
                    .font(.caption.bold())
                    .foregroundStyle(Color(hex: "#a1a1aa"))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(episode.name ?? "Episode \(episode.episodeNumber)")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "#fafafa"))
                    Text("\(episode.runtime ?? 0) min · \(episode.airDate ?? "TBA")")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#52525b"))
                }

                Spacer()

                Image(systemName: "play.circle")
                    .foregroundStyle(Color(hex: "#3b82f6"))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - YouTube Player (Wrapped)

struct YouTubePlayer: UIViewRepresentable {
    let videoKey: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .black
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <html><head><style>body{margin:0;background:#000}</style></head>
        <body><iframe width="100%" height="100%" src="https://www.youtube.com/embed/\(videoKey)?autoplay=1"
        frameborder="0" allow="autoplay;encrypted-media" allowfullscreen></iframe></body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
