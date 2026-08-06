import Foundation

// MARK: - EPG Service (ESPN + TheSportsDB + OpenLigaDB)

actor EPGService {
    static let shared = EPGService()

    // MARK: - League Definitions

    struct League: Identifiable {
        let id: String
        let slug: String?
        let name: String
        let cat: String
        let icon: String
        let channels: [String]
        let tsdbID: String?
        let oldbShortcut: String?
    }

    private let espnLeagues: [League] = [
        League(id: "soccer/ger.1",          slug: "soccer/ger.1",           name: "Bundesliga",              cat: "Soccer",   icon: "⚽", channels: ["stream-sky-sport-bundesliga","stream-dazn-1"], tsdbID: "4331", oldbShortcut: "bl1"),
        League(id: "soccer/ger.2",          slug: "soccer/ger.2",           name: "2. Bundesliga",           cat: "Soccer",   icon: "⚽", channels: ["stream-sky-sport-bundesliga","stream-dazn-1"], tsdbID: "4573", oldbShortcut: nil),
        League(id: "soccer/uefa.champions", slug: "soccer/UEFA.CHAMPIONS",  name: "Champions League",        cat: "Soccer",   icon: "⚽", channels: ["stream-dazn-1","stream-dazn-2","stream-zdf"], tsdbID: "4480", oldbShortcut: nil),
        League(id: "soccer/uefa.europa",    slug: "soccer/UEFA.EUROPA",     name: "Europa League",           cat: "Soccer",   icon: "⚽", channels: ["stream-dazn-1","stream-rtl"], tsdbID: "4481", oldbShortcut: nil),
        League(id: "soccer/eng.1",          slug: "soccer/eng.1",           name: "Premier League",          cat: "Soccer",   icon: "⚽", channels: ["stream-sky-sport-premier-league","stream-sky-sport-1"], tsdbID: "4328", oldbShortcut: nil),
        League(id: "soccer/esp.1",          slug: "soccer/esp.1",           name: "La Liga",                 cat: "Soccer",   icon: "⚽", channels: ["stream-dazn-1","stream-dazn-2"], tsdbID: "4335", oldbShortcut: nil),
        League(id: "soccer/ita.1",          slug: "soccer/ita.1",           name: "Serie A",                 cat: "Soccer",   icon: "⚽", channels: ["stream-dazn-2","stream-dazn-1"], tsdbID: "4332", oldbShortcut: nil),
        League(id: "soccer/fra.1",          slug: "soccer/fra.1",           name: "Ligue 1",                 cat: "Soccer",   icon: "⚽", channels: ["stream-dazn-2"], tsdbID: "4334", oldbShortcut: nil),
        League(id: "soccer/ger.dfb_pokal",  slug: "soccer/ger.dfb_pokal",   name: "DFB-Pokal",               cat: "Soccer",   icon: "⚽", channels: ["stream-sky-sport-1","stream-das-erste"], tsdbID: "4371", oldbShortcut: nil),
        League(id: "soccer/uefa.nations",   slug: "soccer/UEFA.NATIONS",    name: "Nations League",          cat: "Soccer",   icon: "⚽", channels: ["stream-das-erste","stream-rtl","stream-zdf"], tsdbID: nil, oldbShortcut: nil),
        League(id: "soccer/ned.1",          slug: "soccer/ned.1",           name: "Eredivisie",              cat: "Soccer",   icon: "⚽", channels: ["stream-dazn-2"], tsdbID: nil, oldbShortcut: nil),
        League(id: "soccer/por.1",          slug: "soccer/por.1",           name: "Primeira Liga",           cat: "Soccer",   icon: "⚽", channels: ["stream-dazn-2"], tsdbID: nil, oldbShortcut: nil),
        League(id: "soccer/fifa.world",     slug: "soccer/FIFA.WORLD",      name: "WM 2026",                 cat: "Soccer",   icon: "🏆", channels: ["stream-das-erste","stream-zdf","stream-rtl"], tsdbID: nil, oldbShortcut: nil),
        League(id: "soccer/ger.friendlies", slug: nil,                       name: "Deutschland Länderspiel", cat: "Soccer",   icon: "🇩🇪", channels: ["stream-das-erste","stream-rtl","stream-zdf"], tsdbID: nil, oldbShortcut: nil),
        League(id: "racing/f1",             slug: "racing/f1",              name: "Formula 1",               cat: "Motorsport", icon: "🏎", channels: ["stream-sky-sport-f1-de","stream-sky-sports-f1","stream-dazn-f1"], tsdbID: nil, oldbShortcut: nil),
        League(id: "racing/formula-e",      slug: "racing/formula-e",       name: "Formula E",               cat: "Motorsport", icon: "⚡", channels: ["stream-eurosport-1"], tsdbID: nil, oldbShortcut: nil),
        League(id: "basketball/nba",        slug: "basketball/nba",         name: "NBA",                     cat: "Basketball", icon: "🏀", channels: ["stream-dazn-2","stream-sport-1"], tsdbID: nil, oldbShortcut: nil),
        League(id: "football/nfl",          slug: "football/nfl",           name: "NFL",                     cat: "AmericanFootball", icon: "🏈", channels: ["stream-dazn-1","stream-nbc","stream-espn"], tsdbID: nil, oldbShortcut: nil),
        League(id: "hockey/nhl",            slug: "hockey/nhl",             name: "NHL",                     cat: "IceHockey", icon: "🏒", channels: ["stream-dazn-2"], tsdbID: nil, oldbShortcut: nil),
    ]

    // OpenLigaDB leagues (for German leagues, fallback)
    private let oldbLeagues: [(shortcut: String, name: String, cat: String, icon: String, channels: [String])] = [
        ("hbl", "HBL Handball", "Handball", "🤾", ["stream-sky-sport-1","stream-dazn-1"]),
        ("del", "DEL Eishockey", "IceHockey", "🏒", ["stream-dazn-2","stream-sport-1"]),
        ("bbl", "BBL Basketball", "Basketball", "🏀", ["stream-dazn-2","stream-sport-1"]),
        ("bl1", "Bundesliga (OLDB)", "Soccer", "⚽", ["group-sky-bundesliga","stream-dazn-1"]),
    ]

    // MARK: - Date Helpers

    private let berlinTZ = TimeZone(identifier: "Europe/Berlin")!

    private func todayStr() -> String {
        let f = DateFormatter()
        f.timeZone = berlinTZ
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func espnDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = berlinTZ
        f.dateFormat = "yyyyMMdd"
        return f.string(from: date)
    }

    private func isInWindow(_ date: Date?) -> Bool {
        guard let date = date else { return true }
        let now = Date()
        return date.timeIntervalSince1970 >= now.timeIntervalSince1970 - 4 * 3600
            && date.timeIntervalSince1970 <= now.timeIntervalSince1970 + 8 * 86400
    }

    private func dayKey(_ date: Date?) -> String {
        guard let date = date else { return todayStr() }
        let f = DateFormatter()
        f.timeZone = berlinTZ
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    func dayLabel(_ key: String) -> String {
        let today = todayStr()
        let f = DateFormatter()
        f.timeZone = berlinTZ
        f.dateFormat = "yyyy-MM-dd"

        if key == today { return "Heute" }
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()),
           key == f.string(from: tomorrow) { return "Morgen" }

        guard let date = f.date(from: key + "T12:00:00") else { return key }
        let df = DateFormatter()
        df.timeZone = berlinTZ
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "EEEE, d. MMMM"
        return df.string(from: date)
    }

    // MARK: - Fetch All

    func fetchAllEvents() async -> [EPGEvent] {
        let results = await withTaskGroup(of: [EPGEvent].self) { group in
            for league in espnLeagues {
                group.addTask { await self.fetchESPN(league: league) }
            }
            group.addTask { await self.fetchTSDB() }
            group.addTask { await self.fetchOLDB() }

            var all: [EPGEvent] = []
            for await events in group {
                all.append(contentsOf: events)
            }
            return all
        }

        // Deduplicate
        var seen = Set<String>()
        return results.filter { seen.insert($0.id).inserted }
    }

    // MARK: - ESPN Fetch

    private func fetchESPN(league: League) async -> [EPGEvent] {
        guard let slug = league.slug else { return [] }
        var urls: [String] = []

        let cal = Calendar.current
        for i in 0..<7 {
            if let d = cal.date(byAdding: .day, value: i, to: Date()) {
                urls.append("https://site.api.espn.com/apis/site/v2/sports/\(slug)/scoreboard?dates=\(espnDate(d))&limit=50")
            }
        }
        urls.append("https://site.api.espn.com/apis/site/v2/sports/\(slug)/scoreboard?limit=50")

        var events: [EPGEvent] = []
        var seen = Set<String>()

        for url in urls {
            guard let u = URL(string: url),
                  let (data, response) = try? await URLSession.shared.data(from: u),
                  let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let decoded = try? JSONDecoder().decode(ESPNResponse.self, from: data),
                  let espnEvents = decoded.events else { continue }

            for ev in espnEvents {
                guard !seen.contains(ev.id) else { continue }
                seen.insert(ev.id)
                if let parsed = parseESPN(ev, league: league), isInWindow(parsed.date) {
                    events.append(parsed)
                }
            }
        }
        return events
    }

    private func parseESPN(_ ev: ESPNEvent, league: League) -> EPGEvent? {
        let comp = ev.competitions?.first
        let statusName = (comp?.status?.type?.name ?? ev.status?.type?.name ?? "STATUS_SCHEDULED").uppercased()

        let isLive = statusName.contains("PROGRESS") || statusName.contains("HALFTIME") || statusName.contains("INTERMISSION")
        let isDone = statusName.contains("FINAL") || statusName.contains("FULL_TIME") || statusName.contains("POSTGAME") || statusName.contains("END_OF_")
        let status: EPGEvent.EventStatus = isLive ? .live : isDone ? .done : .soon

        let home = comp?.competitors?.first(where: { $0.homeAway == "home" })
        let away = comp?.competitors?.first(where: { $0.homeAway == "away" })
        let homeTeam = home?.team?.displayName ?? home?.team?.name ?? ""
        let awayTeam = away?.team?.displayName ?? away?.team?.name ?? ""
        let teams = homeTeam.isEmpty && awayTeam.isEmpty ? (ev.name ?? ev.shortName ?? "Unbekannt")
            : "\(homeTeam) – \(awayTeam)"

        let hScore = home?.score.flatMap(Int.init)
        let aScore = away?.score.flatMap(Int.init)
        let hasScore = hScore != nil && aScore != nil && (isLive || isDone)
        let clock = isLive ? (comp?.status?.type?.detail ?? comp?.status?.displayClock ?? "") : ""

        let eventDate: Date? = {
            guard let ds = ev.date else { return nil }
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f.date(from: ds) ?? ISO8601DateFormatter().date(from: ds)
        }()

        return EPGEvent(
            id: "espn-\(ev.id)",
            teams: teams,
            league: league.name,
            status: status,
            homeScore: hasScore ? hScore : nil,
            awayScore: hasScore ? aScore : nil,
            clockDetail: clock,
            date: eventDate,
            channels: league.channels,
            icon: league.icon,
            cat: league.cat,
            source: "espn"
        )
    }

    // MARK: - TheSportsDB Fetch

    private func fetchTSDB() async -> [EPGEvent] {
        var events: [EPGEvent] = []
        var seen = Set<String>()

        for league in espnLeagues where league.tsdbID != nil {
            guard let tsdbID = league.tsdbID else { continue }
            let urls = [
                "https://www.thesportsdb.com/api/v1/json/3/eventsnextleague.php?id=\(tsdbID)",
                "https://www.thesportsdb.com/api/v1/json/3/eventspastleague.php?id=\(tsdbID)",
            ]

            for urlStr in urls {
                guard let u = URL(string: urlStr),
                      let (data, response) = try? await URLSession.shared.data(from: u),
                      let http = response as? HTTPURLResponse, http.statusCode == 200,
                      let decoded = try? JSONDecoder().decode(TSDBResponse.self, from: data),
                      let tsdbEvents = decoded.events else { continue }

                for ev in tsdbEvents {
                    guard let id = ev.idEvent, !seen.contains("tsdb-\(id)") else { continue }
                    seen.insert("tsdb-\(id)")
                    if let parsed = parseTSDB(ev, league: league), isInWindow(parsed.date) {
                        events.append(parsed)
                    }
                }
            }
        }
        return events
    }

    private func parseTSDB(_ ev: TSDBEvent, league: League) -> EPGEvent? {
        let teams = ev.strEvent ?? "\(ev.strHomeTeam ?? "") – \(ev.strAwayTeam ?? "")"
        let statusStr = (ev.strStatus ?? "").uppercased()

        let isLive = statusStr.contains("LIVE") || statusStr.contains("PROGRESS")
        let isDone = statusStr.contains("FINAL") || statusStr.contains("FULL") || statusStr.contains("FINISHED")
        let status: EPGEvent.EventStatus = isLive ? .live : isDone ? .done : .soon

        let hScore = ev.intHomeScore.flatMap(Int.init)
        let aScore = ev.intAwayScore.flatMap(Int.init)

        let eventDate: Date? = {
            guard let ds = ev.dateEvent, !ds.isEmpty else { return nil }
            let ts = (ev.strTime ?? "").replacingOccurrences(of: "+00:00", with: "").replacingOccurrences(of: "Z", with: "")
            let dateStr = ts.isEmpty ? "\(ds)T12:00:00" : "\(ds)T\(ts)"
            let f = ISO8601DateFormatter()
            return f.date(from: dateStr + "Z")
        }()

        return EPGEvent(
            id: "tsdb-\(ev.idEvent ?? UUID().uuidString)",
            teams: teams,
            league: league.name,
            status: status,
            homeScore: (isLive || isDone) ? hScore : nil,
            awayScore: (isLive || isDone) ? aScore : nil,
            clockDetail: isLive ? ev.strStatus ?? "" : "",
            date: eventDate,
            channels: league.channels,
            icon: league.icon,
            cat: league.cat,
            source: "tsdb"
        )
    }

    // MARK: - OpenLigaDB Fetch

    private func fetchOLDB() async -> [EPGEvent] {
        var events: [EPGEvent] = []

        for def in oldbLeagues {
            guard let u = URL(string: "https://api.openligadb.de/getmatchdata/\(def.shortcut)") else { continue }
            guard let (data, response) = try? await URLSession.shared.data(from: u),
                  let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let matches = try? JSONDecoder().decode([OLDBMatch].self, from: data) else { continue }

            for m in matches {
                let eventDate: Date? = {
                    guard let ds = m.matchDateTime else { return nil }
                    let f = ISO8601DateFormatter()
                    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    return f.date(from: ds + "Z") ?? ISO8601DateFormatter().date(from: ds + "Z")
                }()
                guard isInWindow(eventDate) else { continue }

                let isLive = m.matchIsFinished == false && (m.matchResults?.isEmpty == false)
                let isDone = m.matchIsFinished == true
                let status: EPGEvent.EventStatus = isLive ? .live : isDone ? .done : .soon
                let lastResult = m.matchResults?.last

                events.append(EPGEvent(
                    id: "oldb-\(m.matchID ?? Int.random(in: 100000...999999))",
                    teams: "\(m.team1?.teamName ?? "") – \(m.team2?.teamName ?? "")",
                    league: def.name,
                    status: status,
                    homeScore: (isLive || isDone) ? lastResult?.pointsTeam1 : nil,
                    awayScore: (isLive || isDone) ? lastResult?.pointsTeam2 : nil,
                    clockDetail: isLive ? "LIVE" : "",
                    date: eventDate,
                    channels: def.channels,
                    icon: def.icon,
                    cat: def.cat,
                    source: "oldb"
                ))
            }
        }
        return events
    }
}
