import SwiftUI

// MARK: - Channel List View (Sport Streams)

struct ChannelListView: View {
    @State private var groups: [SportChannelGroup] = []
    @State private var searchText = ""
    @State private var selectedTag: String? = nil
    @State private var collapsedGroups: Set<String> = []
    @State private var isLoading = true

    @EnvironmentObject var appState: AppState

    private let tags: [SportTag] = [
        SportTag(id: "all", name: "All", icon: "🏆"),
        SportTag(id: "bundesliga", name: "Bundesliga", icon: "⚽"),
        SportTag(id: "champions-league", name: "CL", icon: "⭐"),
        SportTag(id: "premier-league", name: "PL", icon: "🏴"),
        SportTag(id: "laliga", name: "LaLiga", icon: "🇪🇸"),
        SportTag(id: "seriea", name: "Serie A", icon: "🇮🇹"),
        SportTag(id: "ligue1", name: "Ligue 1", icon: "🇫🇷"),
        SportTag(id: "motorsport", name: "Motorsport", icon: "🏎"),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tag filter bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tags) { tag in
                            TagButton(
                                tag: tag,
                                isSelected: selectedTag == tag.id || (tag.id == "all" && selectedTag == nil)
                            ) {
                                selectedTag = tag.id == "all" ? nil : tag.id
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }

                Divider().background(Color(hex: "#27272a"))

                // Channel list
                ScrollView {
                    if isLoading {
                        ProgressView().padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredGroups) { group in
                                ChannelGroupView(
                                    group: group,
                                    isCollapsed: collapsedGroups.contains(group.id),
                                    toggleCollapse: { collapsedGroups.toggle(group.id) },
                                    searchText: searchText.lowercased()
                                )
                            }

                            if filteredGroups.isEmpty {
                                ContentUnavailableView("No channels found", systemImage: "tv.slash")
                                    .padding(.top, 60)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 80)
                    }
                }
                .searchable(text: $searchText, prompt: "Search channels...")
            }
            .background(Color(hex: "#0a0a0e"))
            .navigationTitle("Streams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if collapsedGroups.count == groups.count {
                            collapsedGroups = []
                        } else {
                            collapsedGroups = Set(groups.map(\.id))
                        }
                    } label: {
                        Image(systemName: collapsedGroups.count == groups.count ? "rectangle.expand.vertical" : "rectangle.compress.vertical")
                            .foregroundStyle(Color(hex: "#a1a1aa"))
                            .font(.caption)
                    }
                }
            }
            .task { await loadChannels() }
        }
    }

    private var filteredGroups: [SportChannelGroup] {
        groups.filter { group in
            let matchesSearch = searchText.isEmpty || group.channels.contains { channel in
                channel.name.lowercased().contains(searchText.lowercased()) ||
                group.label.lowercased().contains(searchText.lowercased())
            }

            let matchesTag: Bool
            if let tag = selectedTag {
                matchesTag = group.channels.contains { $0.tags.contains(tag) }
            } else {
                matchesTag = true
            }

            return matchesSearch && matchesTag
        }
    }

    private func loadChannels() async {
        guard let url = Bundle.main.url(forResource: "channels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([SportChannelGroup].self, from: data) else {
            isLoading = false
            return
        }
        groups = decoded
        isLoading = false
    }
}

// MARK: - Tag Button

struct TagButton: View {
    let tag: SportTag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(tag.icon)
                Text(tag.name)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color(hex: "#e11d48").opacity(0.2) : Color(hex: "#27272a"))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: "#e11d48") : Color(hex: "#3f3f46"), lineWidth: 1)
            )
            .cornerRadius(16)
            .foregroundStyle(isSelected ? Color(hex: "#e11d48") : Color(hex: "#a1a1aa"))
        }
    }
}

// MARK: - Channel Group View

struct ChannelGroupView: View {
    let group: SportChannelGroup
    let isCollapsed: Bool
    let toggleCollapse: () -> Void
    let searchText: String

    var body: some View {
        VStack(spacing: 0) {
            // Group header
            Button(action: toggleCollapse) {
                HStack(spacing: 8) {
                    Image(systemName: "tv")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#a1a1aa"))

                    Text(group.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: "#fafafa"))

                    Text("\(group.channelCount) channels")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: "#52525b"))

                    Spacer()

                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#52525b"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: "#18181b"))
            }

            if !isCollapsed {
                VStack(spacing: 0) {
                    ForEach(group.channels) { channel in
                        if searchText.isEmpty ||
                            channel.name.lowercased().contains(searchText) ||
                            group.label.lowercased().contains(searchText) {
                            ChannelRow(channel: channel)
                        }
                    }
                }
            }

            Divider().background(Color(hex: "#27272a"))
        }
    }
}

// MARK: - Channel Row

struct ChannelRow: View {
    let channel: SportChannel
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button {
            appState.selectedChannel = channel
            appState.showChannelPlayer = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.rectangle")
                    .foregroundStyle(Color(hex: "#e11d48"))

                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.name)
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "#fafafa"))
                    Text(channel.country)
                        .font(.caption2)
                        .foregroundStyle(Color(hex: "#52525b"))
                }

                Spacer()

                // Tags
                HStack(spacing: 4) {
                    ForEach(channel.tags.prefix(2), id: \.self) { tag in
                        Text(TagDisplayName[tag] ?? tag)
                            .font(.system(size: 8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#27272a"))
                            .cornerRadius(3)
                            .foregroundStyle(Color(hex: "#a1a1aa"))
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color(hex: "#52525b"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        Divider().background(Color(hex: "#27272a")).padding(.leading, 16)
    }
}

private let TagDisplayName: [String: String] = [
    "bundesliga": "BL",
    "champions-league": "CL",
    "premier-league": "PL",
    "laliga": "LaLiga",
    "seriea": "Serie A",
    "ligue1": "L1",
    "motorsport": "F1",
    "fussball-free": "Free",
]
