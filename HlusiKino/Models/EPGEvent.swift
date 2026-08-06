import Foundation

// MARK: - EPG Event Models

struct EPGEvent: Identifiable, Equatable {
    let id: String
    let teams: String
    let league: String
    let status: EventStatus
    let homeScore: Int?
    let awayScore: Int?
    let clockDetail: String
    let date: Date?
    let channels: [String]
    let icon: String
    let cat: String
    let source: String  // "espn", "tsdb", "oldb"

    enum EventStatus: String, Equatable {
        case live, soon, done, future, relive
    }
}

// MARK: - ESPN API Models

struct ESPNResponse: Codable {
    let events: [ESPNEvent]?
}

struct ESPNEvent: Codable {
    let id: String
    let name: String?
    let shortName: String?
    let date: String?
    let status: ESPNStatus?
    let competitions: [ESPNCompetition]?
}

struct ESPNStatus: Codable {
    let type: ESPNType?
}

struct ESPNType: Codable {
    let name: String?
    let detail: String?
    let displayClock: String?

    enum CodingKeys: String, CodingKey {
        case name, detail
        case displayClock = "displayClock"
    }
}

struct ESPNCompetition: Codable {
    let status: ESPNStatus?
    let competitors: [ESPNCompetitor]?
}

struct ESPNCompetitor: Codable {
    let homeAway: String?
    let team: ESPNTeam?
    let score: String?

    enum CodingKeys: String, CodingKey {
        case homeAway, team, score
    }
}

struct ESPNTeam: Codable {
    let displayName: String?
    let name: String?
}

// MARK: - TheSportsDB API Models

struct TSDBResponse: Codable {
    let events: [TSDBEvent]?
}

struct TSDBEvent: Codable {
    let idEvent: String?
    let strEvent: String?
    let strHomeTeam: String?
    let strAwayTeam: String?
    let dateEvent: String?
    let strTime: String?
    let strStatus: String?
    let intHomeScore: String?
    let intAwayScore: String?
}

// MARK: - OpenLigaDB API Models

struct OLDBMatch: Codable {
    let matchID: Int?
    let matchDateTime: String?
    let team1: OLDBTeam?
    let team2: OLDBTeam?
    let matchResults: [OLDBResult]?
    let matchIsFinished: Bool?

    enum CodingKeys: String, CodingKey {
        case matchID = "MatchID"
        case matchDateTime = "MatchDateTime"
        case team1 = "Team1"
        case team2 = "Team2"
        case matchResults = "MatchResults"
        case matchIsFinished = "MatchIsFinished"
    }
}

struct OLDBTeam: Codable {
    let teamName: String?

    enum CodingKeys: String, CodingKey {
        case teamName = "TeamName"
    }
}

struct OLDBResult: Codable {
    let pointsTeam1: Int?
    let pointsTeam2: Int?

    enum CodingKeys: String, CodingKey {
        case pointsTeam1 = "PointsTeam1"
        case pointsTeam2 = "PointsTeam2"
    }
}
