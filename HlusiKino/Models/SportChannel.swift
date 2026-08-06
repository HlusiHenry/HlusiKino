import Foundation

// MARK: - Sport Channel Models

struct SportChannelGroup: Codable, Identifiable, Equatable {
    var id: String
    var label: String
    var country: String
    var channels: [SportChannel]
    var isSuperGroup: Bool = false
    var subGroups: [SportChannelGroup]? = nil
    var navLabel: String? = nil
}

struct SportChannel: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let country: String
    let url: String
    let fallbackURL: String?
    let tags: [String]  // e.g. ["bundesliga", "champions-league"]

    enum CodingKeys: String, CodingKey {
        case id, name, country, url, tags
        case fallbackURL = "fallback_url"
    }
}

// MARK: - Tag Definitions

struct SportTag: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
}

extension SportChannelGroup {
    var displayName: String {
        "\(label) \(country)"
    }

    var channelCount: Int {
        if let subs = subGroups {
            return subs.reduce(0) { $0 + $1.channels.count }
        }
        return channels.count
    }
}
