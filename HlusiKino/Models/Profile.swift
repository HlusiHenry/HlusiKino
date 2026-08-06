import Foundation

// MARK: - Profile

struct UserProfile: Codable, Identifiable, Equatable {
    var id: String { name }
    let name: String
    var icon: String
    var bg: String
    var watchlists: [String: [WatchlistEntry]]
    var history: [WatchlistEntry]
    var _deleted: [DeletedEntry]
    var _lastSync: TimeInterval

    init(name: String, icon: String = "🎬", bg: String = "#3b82f6") {
        self.name = name
        self.icon = icon
        self.bg = bg
        self.watchlists = ["Main": []]
        self.history = []
        self._deleted = []
        self._lastSync = 0
    }
}

// MARK: - Watchlist Entry

struct WatchlistEntry: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let poster: String
    let type: MediaType
    let added: TimeInterval

    enum MediaType: String, Codable, CaseIterable {
        case movie, tv
    }
}

// MARK: - Deleted Entry (for sync tracking)

struct DeletedEntry: Codable, Equatable {
    let id: Int
    let deletedAt: TimeInterval
    var list: String?
}

// MARK: - Profile Database

struct ProfileDatabase: Codable {
    var profiles: [String: UserProfile]

    init() {
        self.profiles = [:]
    }
}
