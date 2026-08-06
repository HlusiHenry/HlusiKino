import SwiftUI

// MARK: - Watchlist Manager View

struct WatchlistManagerView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedList: String = "Main"
    @State private var showRename = false
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                guard let profile = appState.currentProfile else {
                    ContentUnavailableView("No Profile", systemImage: "person.slash", description: Text("Create or select a profile first"))
                    return
                }

                let listNames = profile.watchlists.keys.sorted()

                // List selector + management
                HStack(spacing: 4) {
                    Picker("List", selection: $selectedList) {
                        ForEach(listNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedList) { _, newValue in
                        appState.setActiveWatchlist(newValue)
                    }

                    // Rename
                    Button {
                        renameText = selectedList
                        showRename = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .padding(6)
                            .background(Color(hex: "#27272a"))
                            .cornerRadius(6)
                            .foregroundStyle(Color(hex: "#a1a1aa))
                    }

                    // Delete
                    if listNames.count > 1 {
                        Button {
                            appState.deleteWatchlist(selectedList)
                            selectedList = appState.activeWatchlistName ?? "Main"
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .padding(6)
                                .background(Color(hex: "#27272a"))
                                .cornerRadius(6)
                                .foregroundStyle(Color(hex: "#a1a1aa))
                        }
                    }

                    // Move up/down
                    Button {
                        appState.moveWatchlist(selectedList, direction: -1)
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                            .padding(6)
                            .background(Color(hex: "#27272a"))
                            .cornerRadius(6)
                            .foregroundStyle(Color(hex: "#a1a1aa))
                    }
                    Button {
                        appState.moveWatchlist(selectedList, direction: 1)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .padding(6)
                            .background(Color(hex: "#27272a"))
                            .cornerRadius(6)
                            .foregroundStyle(Color(hex: "#a1a1aa))
                    }

                    Spacer()

                    // Import
                    Button {
                        appState.showImport = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.caption)
                            .padding(6)
                            .background(Color(hex: "#27272a"))
                            .cornerRadius(6)
                            .foregroundStyle(Color(hex: "#a1a1aa))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Divider().background(Color(hex: "#27272a"))

                // Items
                let items = profile.watchlists[selectedList] ?? []
                if items.isEmpty {
                    ContentUnavailableView("Empty List", systemImage: "film.stack", description: Text("Add movies & shows from Kino or Search"))
                        .padding(.top, 60)
                } else {
                    List {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, entry in
                            WatchlistRow(entry: entry) {
                                appState.selectedDetail = MediaItem(
                                    id: entry.id, title: entry.title, name: nil,
                                    posterPath: entry.poster, backdropPath: nil,
                                    voteAverage: nil, releaseDate: nil, firstAirDate: nil,
                                    overview: nil, originalLanguage: nil, mediaType: entry.type.rawValue, genreIDs: nil
                                )
                                appState.showDetail = true
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task {
                                        await appState.toggleWatchlist(itemID: entry.id, title: entry.title, poster: entry.poster, type: entry.type)
                                    }
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                        .onMove { source, destination in
                            appState.moveWatchlistItem(selectedList, from: source, to: destination)
                        }
                    }
                    .listStyle(.plain)
                    .background(Color(hex: "#09090b"))
                }
            }
            .background(Color(hex: "#09090b"))
            .navigationTitle("Watchlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                EditButton()
                    .foregroundStyle(Color(hex: "#3b82f6))
            }
            .onAppear {
                selectedList = appState.activeWatchlistName ?? "Main"
            }
            .alert("Rename List", isPresented: $showRename) {
                TextField("Name", text: $renameText)
                Button("Cancel", role: .cancel) {}
                Button("Rename") {
                    appState.renameWatchlist(from: selectedList, to: renameText)
                    selectedList = renameText
                }
            }
        }
    }
}

struct WatchlistRow: View {
    let entry: WatchlistEntry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AsyncImage(url: TMDbService.shared.imageURL(entry.poster, size: "w92")) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Color(hex: "#27272a")
                    }
                }
                .frame(width: 50, height: 75)
                .cornerRadius(6)
                .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: "#fafafa))
                        .lineLimit(2)
                    Text(entry.type == .tv ? "Series" : "Movie")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#a1a1aa))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#52525b))
            }
            .padding(.vertical, 6)
        }
        .listRowBackground(Color(hex: "#09090b"))
        .listRowSeparatorTint(Color(hex: "#27272a"))
    }
}
