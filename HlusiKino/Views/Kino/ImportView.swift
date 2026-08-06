import SwiftUI
import UniformTypeIdentifiers

// MARK: - IMDb CSV Import View

struct ImportView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var targetListName = "IMDb Import"
    @State private var csvContent = ""
    @State private var isImporting = false
    @State private var progress = ""
    @State private var showFilePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Target list name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Target Watchlist").font(.caption).foregroundStyle(Color(hex: "#a1a1aa))
                    TextField("List name", text: $targetListName)
                        .padding(10)
                        .background(Color(hex: "#27272a"))
                        .cornerRadius(8)
                        .foregroundStyle(Color(hex: "#fafafa"))
                }

                // CSV input
                VStack(alignment: .leading, spacing: 6) {
                    Text("IMDb CSV Export").font(.caption).foregroundStyle(Color(hex: "#a1a1aa))
                    Text("1. Go to your IMDb watchlist\n2. Click \"Export this list\"\n3. Open CSV, copy all content\n4. Paste below")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: "#52525b))
                        .lineSpacing(2)

                    TextEditor(text: $csvContent)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(8)
                        .background(Color(hex: "#18181b"))
                        .cornerRadius(8)
                        .foregroundStyle(Color(hex: "#a1a1aa))
                        .frame(minHeight: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#27272a"), lineWidth: 1)
                        )

                    // File picker button
                    Button {
                        showFilePicker = true
                    } label: {
                        Label("Open CSV File", systemImage: "folder")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "#3b82f6))
                    }
                }

                // Progress
                if !progress.isEmpty {
                    Text(progress)
                        .font(.caption)
                        .foregroundStyle(Color(hex: "#a1a1aa))
                        .padding()
                }

                // Import button
                Button {
                    startImport()
                } label: {
                    if isImporting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Import")
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(csvContent.isEmpty ? Color(hex: "#27272a") : Color(hex: "#3b82f6"))
                .cornerRadius(10)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .disabled(csvContent.isEmpty || isImporting)

                Spacer()
            }
            .padding()
            .background(Color(hex: "#09090b"))
            .navigationTitle("IMDb Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(hex: "#52525b))
                    }
                }
            }
            .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
                switch result {
                case .success(let url):
                    if let content = try? String(contentsOf: url) {
                        csvContent = content
                    }
                case .failure:
                    break
                }
            }
        }
    }

    private func startImport() {
        isImporting = true
        progress = "Parsing CSV..."

        let items = parseCSV(csvContent)
        guard let items = items, !items.isEmpty else {
            progress = "Invalid CSV format"
            isImporting = false
            return
        }

        let listName = targetListName.trimmingCharacters(in: .whitespaces)
        guard !listName.isEmpty else {
            progress = "Enter a list name"
            isImporting = false
            return
        }

        progress = "Found \(items.count) items. Converting IMDb → TMDB..."

        Task {
            var converted: [(id: Int, title: String, poster: String, type: WatchlistEntry.MediaType)] = []
            var succeeded = 0

            for (index, item) in items.enumerated() {
                if let result = try? await TMDbService.shared.findByIMDb(item.imdbID) {
                    if let movie = result.0 {
                        converted.append((movie.id, movie.displayTitle, movie.posterPath ?? "", .movie))
                        succeeded += 1
                    } else if let tv = result.1 {
                        converted.append((tv.id, tv.displayTitle, tv.posterPath ?? "", .tv))
                        succeeded += 1
                    }
                }
                progress = "Converting... \(index + 1)/\(items.count) (\(succeeded) matched)"
                if index < items.count - 1 {
                    try? await Task.sleep(nanoseconds: 300_000_000) // 300ms rate limit
                }
            }

            guard !converted.isEmpty else {
                progress = "No matches found"
                isImporting = false
                return
            }

            // Add to watchlist
            await MainActor.run {
                appState.setActiveWatchlist(listName)
                for item in converted {
                    appState.addToWatchlist(itemID: item.id, title: item.title, poster: item.poster, type: item.type, listName: listName)
                }
                progress = "Done! Added \(converted.count) items to \"\(listName)\""
                isImporting = false
            }
        }
    }

    private func parseCSV(_ csv: String) -> [CSVItem]? {
        let lines = csv
            .replacingOccurrences(of: "\r", with: "")
            .components(separatedBy: "\n")

        guard lines.count >= 2 else { return nil }

        let headers = parseCSVLine(lines[0]).map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        guard let constIdx = headers.firstIndex(of: "const") else { return nil }
        let titleIdx = headers.firstIndex(of: "title")
        let typeIdx = headers.firstIndex(of: "title type")

        var items: [CSVItem] = []
        for i in 1..<lines.count {
            let cols = parseCSVLine(lines[i])
            guard constIdx < cols.count else { continue }
            let imdbID = cols[constIdx].trimmingCharacters(in: .whitespaces)
            guard imdbID.hasPrefix("tt"), imdbID.count >= 9 else { continue }
            items.append(CSVItem(
                imdbID: imdbID,
                title: titleIdx.map { $0 < cols.count ? cols[$0].trimmingCharacters(in: .whitespaces) : "" } ?? "",
                type: typeIdx.map { $0 < cols.count ? cols[$0].trimmingCharacters(in: .whitespaces) : "" } ?? ""
            ))
        }
        return items.isEmpty ? nil : items
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        let chars = Array(line)
        var i = 0

        while i < chars.count {
            let ch = chars[i]
            if ch == "\"" {
                if inQuotes, i + 1 < chars.count, chars[i + 1] == "\"" {
                    current.append("\"")
                    i += 1
                } else {
                    inQuotes.toggle()
                }
            } else if ch == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(ch)
            }
            i += 1
        }
        result.append(current)
        return result
    }
}

private struct CSVItem {
    let imdbID: String
    let title: String
    let type: String
}
