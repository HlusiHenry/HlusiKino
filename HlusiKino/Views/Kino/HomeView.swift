import SwiftUI

// MARK: - Home View (Hero + Category Rows)

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var trendingMovies: [MediaItem] = []
    @State private var trendingTV: [MediaItem] = []
    @State private var popular: [MediaItem] = []
    @State private var topRated: [MediaItem] = []
    @State private var heroItem: MediaItem?
    @State private var heroTimer: Timer?
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero
                if let hero = heroItem {
                    HeroBanner(item: hero) {
                        openDetail(hero)
                    } playAction: {
                        openPlayer(hero)
                    }
                    .frame(height: 420)
                }

                // Category rows
                VStack(spacing: 24) {
                    if !trendingMovies.isEmpty {
                        CategoryRow(title: "Trending Movies", items: trendingMovies, type: .movie) { openDetail($0) }
                    }
                    if !trendingTV.isEmpty {
                        CategoryRow(title: "Trending Shows", items: trendingTV, type: .tv) { openDetail($0) }
                    }
                    if !popular.isEmpty {
                        CategoryRow(title: "Popular", items: popular, type: .movie) { openDetail($0) }
                    }
                    if !topRated.isEmpty {
                        CategoryRow(title: "Top Rated", items: topRated, type: .movie) { openDetail($0) }
                    }

                    // Watchlist sections
                    WatchlistGrid()

                    // Recommendations
                    RecommendationsRow()
                }
                .padding(.top, 20)
            }
        }
        .background(Color(hex: "#09090b"))
        .scrollIndicators(.hidden)
        .task { await loadAll() }
        .onDisappear { heroTimer?.invalidate() }
    }

    private func loadAll() async {
        async let movies = TMDbService.shared.trendingMovies()
        async let tv = TMDbService.shared.trendingTV()
        async let pop = TMDbService.shared.popular()
        async let top = TMDbService.shared.topRated()

        let (m, t, p, r) = await (try? movies, try? tv, try? pop, try? top)

        await MainActor.run {
            trendingMovies = m ?? []
            trendingTV = t ?? []
            popular = p ?? []
            topRated = r ?? []
            isLoading = false

            if heroItem == nil, let first = m?.randomElement() {
                heroItem = first
                startHeroTimer()
            }
        }
    }

    private func startHeroTimer() {
        heroTimer?.invalidate()
        heroTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { _ in
            Task { await rotateHero() }
        }
    }

    private func rotateHero() async {
        guard let movies = try? await TMDbService.shared.trendingMovies(), let next = movies.randomElement() else { return }
        await MainActor.run { heroItem = next }
    }

    private func openDetail(_ item: MediaItem) {
        appState.selectedDetail = item
        appState.showDetail = true
    }

    private func openPlayer(_ item: MediaItem) {
        appState.selectedPlayer = item
        appState.showPlayer = true
    }
}

// MARK: - Hero Banner

struct HeroBanner: View {
    let item: MediaItem
    let detailAction: () -> Void
    let playAction: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            // Backdrop
            AsyncImage(url: TMDbService.shared.imageURL(item.backdropPath ?? item.posterPath, size: "original")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Color(hex: "#18181b")
                }
            }
            .frame(height: 420)
            .clipped()
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Color(hex: "#09090b").opacity(0.6), location: 0.5),
                        .init(color: Color(hex: "#09090b"), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(item.displayTitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#fafafa"))

                HStack(spacing: 12) {
                    Label(item.displayRating, systemImage: "star.fill")
                        .foregroundStyle(Color(hex: "#f59e0b"))
                    Text(item.displayYear)
                    Text((item.originalLanguage ?? "").uppercased())
                }
                .font(.caption)
                .foregroundStyle(Color(hex: "#a1a1aa"))

                if let overview = item.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#a1a1aa))
                        .lineLimit(3)
                }

                HStack(spacing: 12) {
                    Button(action: playAction) {
                        Label("Play", systemImage: "play.fill")
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#3b82f6"))
                            .cornerRadius(8)
                            .font(.subheadline.bold())
                    }

                    Button(action: detailAction) {
                        Label("Info", systemImage: "info.circle")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#27272a"))
                            .cornerRadius(8)
                            .font(.subheadline)
                    }
                }
                .foregroundStyle(Color(hex: "#fafafa"))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let title: String
    let items: [MediaItem]
    let type: MediaItem.MediaType
    let action: (MediaItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(Color(hex: "#fafafa"))
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items) { item in
                        MediaCard(item: item, type: type, action: { action(item) })
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Media Card

struct MediaCard: View {
    let item: MediaItem
    let type: MediaItem.MediaType
    let action: () -> Void
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: TMDbService.shared.imageURL(item.posterPath, size: "w342")) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            Color(hex: "#27272a")
                        }
                    }
                    .frame(width: 140, height: 210)
                    .cornerRadius(8)
                    .clipped()

                    // Type badge
                    Text(type == .tv ? "SERIES" : "MOVIE")
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#3b82f6"))
                        .cornerRadius(4)
                        .foregroundStyle(.white)
                        .padding(4)
                }

                Text(item.displayTitle)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#fafafa"))
                    .lineLimit(1)
                    .frame(width: 140, alignment: .leading)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color(hex: "#f59e0b))
                    Text(item.displayRating)
                    Text(item.displayYear)
                }
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#a1a1aa))
            }
        }
    }
}

// MARK: - Watchlist Grid (shows all watchlist items on home)

struct WatchlistGrid: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if let profile = appState.currentProfile {
            ForEach(profile.watchlists.sorted(by: { $0.key < $1.key }), id: \.key) { name, items in
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            appState.selectedTab = 1  // Watchlist tab
                        } label: {
                            HStack {
                                Text(name)
                                    .font(.title3.bold())
                                Text("\(items.count) items")
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: "#a1a1aa))
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: "#a1a1aa))
                            }
                            .foregroundStyle(Color(hex: "#fafafa"))
                            .padding(.horizontal, 16)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(items.prefix(10)) { entry in
                                    WatchlistCard(entry: entry)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
    }
}

struct WatchlistCard: View {
    let entry: WatchlistEntry
    @EnvironmentObject var appState: AppState

    var body: some View {
        AsyncImage(url: TMDbService.shared.imageURL(entry.poster, size: "w342")) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            default:
                Color(hex: "#27272a")
            }
        }
        .frame(width: 100, height: 150)
        .cornerRadius(8)
        .clipped()
        .onTapGesture {
            let item = MediaItem(id: entry.id, title: entry.title, name: nil, posterPath: entry.poster, backdropPath: nil, voteAverage: nil, releaseDate: nil, firstAirDate: nil, overview: nil, originalLanguage: nil, mediaType: entry.type.rawValue, genreIDs: nil)
            appState.selectedDetail = item
            appState.showDetail = true
        }
    }
}

// MARK: - Recommendations Row

struct RecommendationsRow: View {
    @EnvironmentObject var appState: AppState
    @State private var recs: [MediaItem] = []

    var body: some View {
        if !recs.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recommended for You")
                    .font(.title3.bold())
                    .foregroundStyle(Color(hex: "#fafafa))
                    .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(recs) { item in
                            MediaCard(item: item, type: item.inferredType) {
                                appState.selectedDetail = item
                                appState.showDetail = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .task { await loadRecs() }
        }
    }

    private func loadRecs() async {
        guard let profile = appState.currentProfile,
              let listName = appState.activeWatchlistName,
              let wl = profile.watchlists[listName], !wl.isEmpty else { return }

        var all: [MediaItem] = []
        var seen = Set<Int>()
        for entry in wl.prefix(5) {
            guard let recs = try? await TMDbService.shared.recommendations(id: entry.id, type: entry.type == .tv ? .tv : .movie) else { continue }
            for r in recs {
                if seen.insert(r.id).inserted {
                    all.append(r)
                }
            }
        }
        await MainActor.run { recs = Array(all.prefix(15)) }
    }
}
