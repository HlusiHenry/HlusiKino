import SwiftUI

// MARK: - App State (ObservableObject shared across all views)

@MainActor
class AppState: ObservableObject {
    // Profile
    @Published var currentUser: String? = nil
    @Published var currentProfile: UserProfile? = nil
    @Published var profileNames: [String] = []
    @Published var activeWatchlistName: String? = nil

    // Navigation
    @Published var selectedTab = 0

    // Detail / Player
    @Published var selectedDetail: MediaItem? = nil
    @Published var showDetail = false
    @Published var selectedPlayer: MediaItem? = nil
    @Published var selectedPlayerSeason: Int? = nil
    @Published var selectedPlayerEpisode: Int? = nil
    @Published var showPlayer = false

    // Sport
    @Published var selectedChannel: SportChannel? = nil
    @Published var showChannelPlayer = false
    @Published var showChannelByID: String? = nil

    // Import
    @Published var showImport = false

    // Settings
    @Published var settings: AppSettings = AppSettings()

    private let storage = StorageService.shared

    init() {
        loadProfiles()
        if let user = storage.activeUser() {
            selectProfile(user)
        }
    }

    // MARK: - Profile Management

    func loadProfiles() {
        profileNames = storage.allProfileNames()
    }

    func createProfile(name: String, icon: String, bg: String) -> UserProfile? {
        guard let profile = storage.createProfile(name: name, icon: icon, bg: bg) else { return nil }
        profileNames = storage.allProfileNames()
        return profile
    }

    func selectProfile(_ name: String) {
        guard let profile = storage.loadProfile(name: name) else { return }
        currentUser = name
        currentProfile = profile
        storage.setActiveUser(name)
        activeWatchlistName = storage.activeWatchlist()
        profileNames = storage.allProfileNames()
    }

    func deleteProfile(_ name: String) {
        storage.deleteProfile(name: name)
        if currentUser == name {
            currentUser = nil
            currentProfile = nil
            storage.setActiveUser(nil)
        }
        profileNames = storage.allProfileNames()
    }

    func profileIcon(_ name: String) -> String {
        storage.loadProfile(name: name)?.icon ?? "🎬"
    }

    func profileColor(_ name: String) -> String {
        storage.loadProfile(name: name)?.bg ?? "#3b82f6"
    }

    // MARK: - Watchlist Management

    func setActiveWatchlist(_ name: String) {
        activeWatchlistName = name
        storage.setActiveWatchlist(name)
        // Ensure list exists
        if var p = currentProfile, p.watchlists[name] == nil {
            p.watchlists[name] = []
            storage.saveProfile(p)
            currentProfile = p
        }
    }

    func toggleWatchlist(itemID: Int, title: String, poster: String, type: WatchlistEntry.MediaType) {
        guard var profile = currentProfile, let listName = activeWatchlistName else { return }
        profile = storage.toggleWatchlist(profile: profile, itemID: itemID, title: title, poster: poster, type: type, listName: listName)
        currentProfile = profile
    }

    func isInWatchlist(itemID: Int) -> Bool {
        guard let profile = currentProfile, let listName = activeWatchlistName else { return false }
        return storage.isInWatchlist(profile: profile, itemID: itemID, listName: listName)
    }

    func addToWatchlist(itemID: Int, title: String, poster: String, type: WatchlistEntry.MediaType, listName: String) {
        guard var profile = currentProfile else { return }
        if profile.watchlists[listName] == nil {
            profile.watchlists[listName] = []
        }
        if !profile.watchlists[listName]!.contains(where: { $0.id == itemID }) {
            profile.watchlists[listName]!.insert(WatchlistEntry(id: itemID, title: title, poster: poster, type: type, added: Date().timeIntervalSince1970), at: 0)
        }
        storage.saveProfile(profile)
        currentProfile = profile
    }

    func renameWatchlist(from oldName: String, to newName: String) {
        guard var profile = currentProfile,
              profile.watchlists[newName] == nil,
              let items = profile.watchlists[oldName] else { return }
        profile.watchlists[newName] = items
        profile.watchlists.removeValue(forKey: oldName)
        storage.saveProfile(profile)
        currentProfile = profile
        if activeWatchlistName == oldName {
            setActiveWatchlist(newName)
        }
    }

    func deleteWatchlist(_ name: String) {
        guard var profile = currentProfile,
              profile.watchlists.count > 1,
              let items = profile.watchlists[name] else { return }
        // Track deletions
        let now = Date().timeIntervalSince1970
        for item in items {
            profile._deleted.append(DeletedEntry(id: item.id, deletedAt: now, list: name))
        }
        profile.watchlists.removeValue(forKey: name)
        storage.saveProfile(profile)
        currentProfile = profile
    }

    func moveWatchlist(_ name: String, direction: Int) {
        guard var profile = currentProfile else { return }
        let keys = Array(profile.watchlists.keys)
        guard let idx = keys.firstIndex(of: name) else { return }
        let newIdx = idx + direction
        guard newIdx >= 0, newIdx < keys.count else { return }

        var entries = Array(profile.watchlists)
        entries.swapAt(idx, newIdx)
        var newDict: [String: [WatchlistEntry]] = [:]
        for (k, v) in entries { newDict[k] = v }
        profile.watchlists = newDict
        storage.saveProfile(profile)
        currentProfile = profile
    }

    func moveWatchlistItem(_ listName: String, from source: IndexSet, to destination: Int) {
        guard var profile = currentProfile,
              var items = profile.watchlists[listName] else { return }
        items.move(fromOffsets: source, toOffset: destination)
        profile.watchlists[listName] = items
        storage.saveProfile(profile)
        currentProfile = profile
    }
}

// MARK: - App Settings

struct AppSettings: Codable {
    var darkMode = true
    var playerSource = 0
}
