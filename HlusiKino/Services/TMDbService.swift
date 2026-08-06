import Foundation

// MARK: - TMDB API Service

actor TMDbService {
    static let shared = TMDbService()

    private let apiKey = "790bd49a274d4dea7dd0dd4cbb3ccd73"
    private let baseURL = "https://api.themoviedb.org/3"
    private let imageBase = "https://image.tmdb.org/t/p"

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - Image URLs

    func imageURL(_ path: String?, size: String = "w342") -> URL? {
        guard let path = path, !path.isEmpty else { return nil }
        return URL(string: "\(imageBase)/\(size)\(path)")
    }

    // MARK: - Generic Fetch

    private func fetch<T: Codable>(_ path: String) async throws -> T {
        let sep = path.contains("?") ? "&" : "?"
        let urlString = "\(baseURL)\(path)\(sep)api_key=\(apiKey)&language=en"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Discovery

    func trendingMovies() async throws -> [MediaItem] {
        let response: TMDBResponse<MediaItem> = try await fetch("/trending/movie/week")
        return Array(response.results.prefix(12))
    }

    func trendingTV() async throws -> [MediaItem] {
        let response: TMDBResponse<MediaItem> = try await fetch("/trending/tv/week")
        return Array(response.results.prefix(12))
    }

    func popular() async throws -> [MediaItem] {
        let response: TMDBResponse<MediaItem> = try await fetch("/movie/popular")
        return Array(response.results.prefix(12))
    }

    func topRated() async throws -> [MediaItem] {
        let response: TMDBResponse<MediaItem> = try await fetch("/movie/top_rated")
        return Array(response.results.prefix(12))
    }

    // MARK: - Search

    func search(query: String) async throws -> [MediaItem] {
        guard !query.isEmpty else { return [] }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let response: TMDBResponse<MediaItem> = try await fetch("/search/multi?query=\(encoded)")
        return (response.results ?? [])
            .filter { $0.mediaType == "movie" || $0.mediaType == "tv" }
    }

    // MARK: - Detail

    func detail(id: Int, type: MediaItem.MediaType) async throws -> MediaItem {
        let append: String
        if type == .tv {
            append = "credits,videos,aggregate_credits"
        } else {
            append = "credits,videos"
        }
        let path = "/\(type == .tv ? "tv" : "movie")/\(id)?append_to_response=\(append)"
        return try await fetch(path)
    }

    // MARK: - Seasons

    func seasonEpisodes(tvID: Int, season: Int) async throws -> SeasonDetail {
        return try await fetch("/tv/\(tvID)/season/\(season)")
    }

    // MARK: - IMDb → TMDB

    func findByIMDb(_ imdbID: String) async throws -> (MediaItem?, MediaItem?) {
        let response: TMDBFindResponse = try await fetch("/find/\(imdbID)?external_source=imdb_id")
        return (response.movieResults?.first, response.tvResults?.first)
    }

    // MARK: - Recommendations

    func recommendations(id: Int, type: MediaItem.MediaType) async throws -> [MediaItem] {
        let response: TMDBResponse<MediaItem> = try await fetch("/\(type == .tv ? "tv" : "movie")/\(id)/recommendations")
        return Array(response.results.prefix(4))
    }
}
