import SwiftUI

// MARK: - Profile Gate ("Who's watching?")

struct ProfileGateView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAdd = false
    @State private var newName = ""
    @State private var selectedIcon = "🎬"
    @State private var selectedColor = Color(hex: "#3b82f6")

    private let icons = ["🎬", "🍿", "🎥", "📺", "🤖", "⭐", "🔥", "💀", "👻", "🦊", "🦁", "🐼"]
    private let colors: [String] = ["#3b82f6", "#ef4444", "#22c55e", "#f59e0b", "#a855f7", "#ec4899", "#06b6d4"]

    var body: some View {
        ZStack {
            Color(hex: "#09090b").ignoresSafeArea()

            VStack(spacing: 32) {
                Text("HlusiKino")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#fafafa"))

                Text("Who's watching?")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "#a1a1aa"))

                // Existing profiles
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                    ForEach(appState.profileNames, id: \.self) { name in
                        ProfileCard(name: name) {
                            appState.selectProfile(name)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                appState.deleteProfile(name)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }

                    // Add profile button
                    Button { showAdd = true } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "#27272a"))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: "#a1a1aa"))
                            }
                            Text("Add")
                                .font(.caption)
                                .foregroundStyle(Color(hex: "#a1a1aa"))
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .sheet(isPresented: $showAdd) {
            addProfileSheet
        }
    }

    private var addProfileSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Name", text: $newName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(hex: "#27272a"))
                    .cornerRadius(8)
                    .foregroundStyle(Color(hex: "#fafafa"))

                // Icon picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Icon").foregroundStyle(Color(hex: "#a1a1aa")).font(.caption)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Text(icon)
                                    .font(.title2)
                                    .padding(8)
                                    .background(selectedIcon == icon ? Color(hex: "#3b82f6").opacity(0.3) : Color(hex: "#27272a"))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                // Color picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color").foregroundStyle(Color(hex: "#a1a1aa")).font(.caption)
                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { hex in
                            Button {
                                selectedColor = Color(hex: hex)
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: "#fafafa"), lineWidth: selectedColor.toHex() == hex ? 3 : 0)
                                    )
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(hex: "#09090b"))
            .navigationTitle("New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAdd = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        _ = appState.createProfile(name: newName.trimmingCharacters(in: .whitespaces), icon: selectedIcon, bg: selectedColor.toHex() ?? "#3b82f6")
                        newName = ""
                        showAdd = false
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct ProfileCard: View {
    let name: String
    let action: () -> Void
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: appState.profileColor(name)))
                        .frame(width: 80, height: 80)
                    Text(appState.profileIcon(name))
                        .font(.system(size: 32))
                }
                Text(name)
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#a1a1aa"))
                    .lineLimit(1)
            }
        }
    }
}
