import SwiftUI

// MARK: - EPG View ("Was läuft gerade?")

struct EPGView: View {
    @State private var events: [EPGEvent] = []
    @State private var selectedCat: String? = nil
    @State private var isLoading = true
    @State private var lastUpdate: Date?

    @EnvironmentObject var appState: AppState

    private let categories = [
        ("all", "Alle", "🏆"),
        ("Soccer", "Fußball", "⚽"),
        ("Motorsport", "Motorsport", "🏎"),
        ("Basketball", "Basketball", "🏀"),
        ("AmericanFootball", "NFL", "🏈"),
        ("IceHockey", "Eishockey", "🏒"),
        ("Handball", "Handball", "🤾"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(categories, id: \.0) { cat in
                            Button {
                                selectedCat = cat.0 == "all" ? nil : cat.0
                            } label: {
                                HStack(spacing: 4) {
                                    Text(cat.2)
                                    Text(cat.1)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    selectedCat == cat.0 || (cat.0 == "all" && selectedCat == nil)
                                        ? Color(hex: "#F58F7C").opacity(0.15)
                                        : Color(hex: "#3d3c40")
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            selectedCat == cat.0 || (cat.0 == "all" && selectedCat == nil)
                                                ? Color(hex: "#F58F7C")
                                                : Color(hex: "#4F4F51"),
                                            lineWidth: 1
                                        )
                                )
                                .cornerRadius(16)
                                .foregroundStyle(
                                    selectedCat == cat.0 || (cat.0 == "all" && selectedCat == nil)
                                        ? Color(hex: "#F58F7C")
                                        : Color(hex: "#aaa")
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }

                Divider().background(Color(hex: "#4F4F51"))

                // Content
                ScrollView {
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView().tint(Color(hex: "#F58F7C"))
                            Text("Loading sport schedule...")
                                .font(.caption)
                                .foregroundStyle(Color(hex: "#555"))
                        }
                        .padding(.top, 80)
                    } else if filteredEvents.isEmpty {
                        ContentUnavailableView("No Events", systemImage: "sportscourt", description: Text("No live or upcoming events found"))
                            .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(daySections, id: \.key) { section in
                                EPGDaySection(key: section.key, events: section.value)
                            }
                        }
                        .padding(.bottom, 60)
                    }
                }
                .refreshable { await loadEvents() }
            }
            .background(Color(hex: "#2C2B30"))
            .navigationTitle("EPG")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await loadEvents() } } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color(hex: "#888"))
                            .font(.caption)
                    }
                }
            }
            .task { await loadEvents() }
        }
    }

    private var filteredEvents: [EPGEvent] {
        guard let cat = selectedCat else { return events }
        return events.filter { $0.cat == cat }
    }

    private var daySections: [(key: String, value: [EPGEvent])] {
        // Group by day manually
        var dict: [String: [EPGEvent]] = [:]
        for event in filteredEvents {
            let key = localDayKey(event.date)
            let label = localDayLabel(key)
            dict[label, default: []].append(event)
        }
        return dict.sorted { a, b in
            // Sort: Today first, then chronological
            if a.key == "Heute" { return true }
            if b.key == "Heute" { return false }
            if a.key == "Morgen" { return true }
            if b.key == "Morgen" { return false }
            return a.key < b.key
        }
    }

    private func localDayKey(_ date: Date?) -> String {
        guard let date = date else { return "Heute" }
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: "Europe/Berlin")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func localDayLabel(_ key: String) -> String {
        let today = localDayKey(Date())
        let tomorrow: String = {
            guard let d = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return "" }
            return localDayKey(d)
        }()

        if key == today { return "Heute" }
        if key == tomorrow { return "Morgen" }

        guard let date = { () -> Date? in
            let f = DateFormatter()
            f.timeZone = TimeZone(identifier: "Europe/Berlin")
            f.dateFormat = "yyyy-MM-dd"
            return f.date(from: key + "T12:00:00")
        }() else { return key }

        let df = DateFormatter()
        df.timeZone = TimeZone(identifier: "Europe/Berlin")
        df.locale = Locale(identifier: "de_DE")
        df.dateFormat = "EEEE, d. MMMM"
        return df.string(from: date)
    }

    private func loadEvents() async {
        isLoading = true
        let results = await EPGService.shared.fetchAllEvents()
        await MainActor.run {
            events = results.sorted { a, b in
                (a.date ?? Date()) < (b.date ?? Date())
            }
            lastUpdate = Date()
            isLoading = false
        }
    }
}

// MARK: - EPG Day Section

struct EPGDaySection: View {
    let key: String
    let events: [EPGEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Day header (sticky)
            HStack(spacing: 8) {
                Circle()
                    .fill(key == "Heute" ? Color(hex: "#ef4444") : Color(hex: "#F58F7C"))
                    .frame(width: 8, height: 8)
                Text(key)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Spacer()
                Text("\(events.count) events")
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#555"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(colors: [Color(hex: "#2e2d32"), Color(hex: "#2e2d32").opacity(0.85)], startPoint: .top, endPoint: .bottom)
            )

            // Events
            ForEach(events) { event in
                EPGEventRow(event: event)
                Divider().background(Color(hex: "#3a3a3d")).padding(.leading, 16)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - EPG Event Row

struct EPGEventRow: View {
    let event: EPGEvent
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button {
            // Navigate to channel if available
            if let channelID = event.channels.first {
                // Try to find and open the channel
                appState.showChannelByID = channelID
            }
        } label: {
            HStack(spacing: 12) {
                // Icon
                Text(event.icon)
                    .font(.title3)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.teams)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(event.league)
                            .font(.caption2)
                            .foregroundStyle(Color(hex: "#555"))
                        if !event.clockDetail.isEmpty {
                            Text(event.clockDetail)
                                .font(.caption2)
                                .foregroundStyle(Color(hex: "#F58F7C"))
                        }
                    }
                }

                Spacer()

                // Score / Status
                VStack(alignment: .trailing, spacing: 2) {
                    if let home = event.homeScore, let away = event.awayScore {
                        Text("\(home) - \(away)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                    statusBadge(event.status)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func statusBadge(_ status: EPGEvent.EventStatus) -> some View {
        switch status {
        case .live:
            HStack(spacing: 4) {
                Circle().fill(Color.red).frame(width: 6, height: 6)
                Text("LIVE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "#f87171"))
            }
        case .done:
            Text("FT")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(hex: "#a1a1aa"))
        case .soon:
            if let date = event.date {
                Text(formatTime(date))
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "#F58F7C"))
            }
        case .future:
            Text("Upcoming")
                .font(.caption2)
                .foregroundStyle(Color(hex: "#93c5fd"))
        case .relive:
            Text("Replay")
                .font(.caption2)
                .foregroundStyle(Color(hex: "#a5b4fc"))
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: "Europe/Berlin")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
