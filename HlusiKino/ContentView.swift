import SwiftUI

// MARK: - Content View (TabView with 6 tabs)

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.currentUser == nil {
            ProfileGateView()
        } else {
            TabView(selection: $appState.selectedTab) {
                HomeView()
                    .tabItem { Label("Kino", systemImage: "play.rectangle.fill") }
                    .tag(0)

                WatchlistManagerView()
                    .tabItem { Label("Watchlist", systemImage: "bookmark.fill") }
                    .tag(1)

                SearchView()
                    .tabItem { Label("Suchen", systemImage: "magnifyingglass") }
                    .tag(2)

                ChannelListView()
                    .tabItem { Label("Streams", systemImage: "tv.fill") }
                    .tag(3)

                EPGView()
                    .tabItem { Label("EPG", systemImage: "sportscourt.fill") }
                    .tag(4)

                SettingsView()
                    .tabItem { Label("Einstellungen", systemImage: "gearshape.fill") }
                    .tag(5)
            }
            .tint(Color(hex: "#3b82f6"))
            .sheet(isPresented: $appState.showDetail) {
                if let item = appState.selectedDetail {
                    DetailView(item: item)
                }
            }
            .fullScreenCover(isPresented: $appState.showPlayer) {
                if let item = appState.selectedPlayer {
                    PlayerView(item: item, season: appState.selectedPlayerSeason, episode: appState.selectedPlayerEpisode)
                }
            }
            .fullScreenCover(isPresented: $appState.showChannelPlayer) {
                if let channel = appState.selectedChannel {
                    ChannelPlayerView(channel: channel)
                }
            }
            .sheet(isPresented: $appState.showImport) {
                ImportView()
            }
        }
    }
}
