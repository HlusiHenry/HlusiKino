import Foundation

// MARK: - Local Storage Service

actor StorageService {
    static let shared = StorageService()

    private let defaults = UserDefaults.standard
    private let profilesKey = "hk_db"
    private let activeUserKey = "hk_user"
    private let activeWatchlistKey = "hk_activelist"

    // MARK: - Profile Database

    func loadDatabase() -> ProfileDatabase {
        guard let data = defaults.data(forKey: profilesKey),
              let db = try? JSONDecoder().decode(ProfileDatabase.self, from: data) else {
            return ProfileDatabase()
        }
        // Migrate old format
        var migrated = db
        for (_, profile) in migrated.profiles {
            migrateProfile(profile)
        }
        return migrated
    }

    func saveDatabase(_ db: ProfileDatabase) {
        // Clean old watchlist key and _deleted entries
        var cleaned = db
        let cutoff = Date().timeIntervalSince1970 - 30 * 86400
        for (name, var profile) in cleaned.profiles {
            profile._deleted = profile._deleted.filter { $0.deletedAt > cutoff }
            cleaned.profiles[name] = profile
        }
        if let data = try? JSONEncoder().encode(cleaned) {
            defaults.set(data, forKey: profilesKey)
        }
    }

    private func migrateProfile(_ profile: UserProfile) {
        // Profiles are already migrated on load (watchlists always present)
        _ = profile
    }

    // MARK: - Profile CRUD

    func createProfile(name: String, icon: String = "🎬", bg: String = "#3b82f6") -> UserProfile? {
        let db = loadDatabase()
        guard db.profiles[name] == nil else { return nil }
        let profile = UserProfile(name: name, icon: icon, bg: bg)
        var updated = db
        updated.profiles[name] = profile
        saveDatabase(updated)
        return profile
    }

    func loadProfile(name: String) -> UserProfile? {
        let db = loadDatabase()
        return db.profiles[name]
    }

    func saveProfile(_ profile: UserProfile) {
        var db = loadDatabase()
        db.profiles[profile.name] = profile
        saveDatabase(db)
    }

    func deleteProfile(name: String) {
        var db = loadDatabase()
        db.profiles.removeValue(forKey: name)
        saveDatabase(db)
    }

    func allProfileNames() -> [String] {
        loadDatabase().profiles.map(\.key).sorted()
    }

    // MARK: - Active User

    func activeUser() -> String? {
        defaults.string(forKey: activeUserKey)
    }

    func setActiveUser(_ name: String?) {
        if let name = name {
            defaults.set(name, forKey: activeUserKey)
        } else {
            defaults.removeObject(forKey: activeUserKey)
        }
    }

    // MARK: - Active Watchlist

    func activeWatchlist() -> String {
        defaults.string(forKey: activeWatchlistKey) ?? "Main"
    }

    func setActiveWatchlist(_ name: String) {
        defaults.set(name, forKey: activeWatchlistKey)
    }

    // MARK: - Watchlist Helpers

    func toggleWatchlist(profile: UserProfile, itemID: Int, title: String, poster: String, type: WatchlistEntry.MediaType, listName: String) -> UserProfile {
        var p = profile
        if p.watchlists[listName] == nil {
            p.watchlists[listName] = []
        }

        if let idx = p.watchlists[listName]!.firstIndex(where: { $0.id == itemID }) {
            // Remove
            p.watchlists[listName]!.remove(at: idx)
            p._deleted.append(DeletedEntry(id: itemID, deletedAt: Date().timeIntervalSince1970, list: listName))
        } else {
            // Add
            let entry = WatchlistEntry(id: itemID, title: title, poster: poster, type: type, added: Date().timeIntervalSince1970)
            p.watchlists[listName]!.insert(entry, at: 0)
        }
        saveProfile(p)
        return p
    }

    func isInWatchlist(profile: UserProfile, itemID: Int, listName: String) -> Bool {
        profile.watchlists[listName]?.contains(where: { $0.id == itemID }) ?? false
    }
}
