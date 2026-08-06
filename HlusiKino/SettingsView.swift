import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                // Profile section
                Section("Profile") {
                    if let user = appState.currentUser {
                        HStack {
                            Text(appState.currentProfile?.icon ?? "🎬")
                                .font(.title)
                            VStack(alignment: .leading) {
                                Text(user)
                                    .font(.headline)
                                Text("\(appState.currentProfile?.watchlists.count ?? 0) watchlists")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button(role: .destructive) {
                            appState.deleteProfile(user)
                        } label: {
                            Label("Delete Profile", systemImage: "trash")
                        }
                    }

                    Button {
                        appState.currentUser = nil
                        appState.currentProfile = nil
                    } label: {
                        Label("Switch Profile", systemImage: "arrow.triangle.swap")
                    }
                }

                // Player
                Section("Player") {
                    Picker("Default Source", selection: $appState.settings.playerSource) {
                        Text("Nontongo").tag(0)
                        Text("Vidsrc").tag(1)
                        Text("Vidlink").tag(2)
                    }
                }

                // About
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Build", value: "1")
                    LabeledContent("TMDB", value: "v3 API")
                    LabeledContent("EPG Sources", value: "ESPN, TSDB, OLDB")
                }

                // Data
                Section("Data") {
                    Text("All data stored locally on device")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("No server or cloud connection needed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .background(Color(hex: "#09090b"))
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
