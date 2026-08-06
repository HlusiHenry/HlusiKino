import SwiftUI

// MARK: - Search View

struct SearchView: View {
    @EnvironmentObject var appState: AppState
    @State private var query = ""
    @State private var results: [MediaItem] = []
    @State private var isSearching = false

    private let debouncer = Debouncer(delay: 0.3)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color(hex: "#a1a1aa"))
                    TextField("Search movies & shows...", text: $query)
                        .foregroundStyle(Color(hex: "#fafafa"))
                        .onChange(of: query) { _, newValue in
                            debouncer.call { Task { await search(newValue) } }
                        }
                    if !query.isEmpty {
                        Button { query = ""; results = [] } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color(hex: "#52525b"))
                        }
                    }
                }
                .padding(12)
                .background(Color(hex: "#27272a"))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Results
                if isSearching {
                    ProgressView()
                        .padding(.top, 40)
                } else if query.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "popcorn.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color(hex: "#27272a"))
                        Text("Search for movies & TV shows")
                            .foregroundStyle(Color(hex: "#52525b))
                    }
                    .padding(.top, 80)
                } else if results.isEmpty {
                    Text("Nothing found for \"\(query)\"")
                        .foregroundStyle(Color(hex: "#52525b))
                        .padding(.top, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(results) { item in
                                SearchResultRow(item: item) {
                                    appState.selectedDetail = item
                                    appState.showDetail = true
                                }
                                Divider().background(Color(hex: "#27272a")).padding(.leading, 80)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .background(Color(hex: "#09090b"))
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func search(_ q: String) async {
        guard !q.isEmpty else { results = []; return }
        isSearching = true
        defer { isSearching = false }

        guard let r = try? await TMDbService.shared.search(query: q) else { return }
        await MainActor.run { results = Array(r.prefix(15)) }
    }
}

struct SearchResultRow: View {
    let item: MediaItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AsyncImage(url: TMDbService.shared.imageURL(item.posterPath, size: "w92")) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Color(hex: "#27272a")
                    }
                }
                .frame(width: 55, height: 82)
                .cornerRadius(6)
                .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayTitle)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: "#fafafa"))
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Label(item.displayRating, systemImage: "star.fill")
                            .foregroundStyle(Color(hex: "#f59e0b"))
                        Text(item.displayYear)
                        Text(item.inferredType == .tv ? "SERIES" : "MOVIE")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(item.inferredType == .tv ? Color(hex: "#a855f7").opacity(0.3) : Color(hex: "#3b82f6").opacity(0.3))
                            .cornerRadius(4)
                    }
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "#a1a1aa))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#52525b))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Debouncer Utility

class Debouncer {
    private let delay: TimeInterval
    private var task: Task<Void, Never>?

    init(delay: TimeInterval) { self.delay = delay }

    func call(action: @escaping () -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if !Task.isCancelled { action() }
        }
    }
}
