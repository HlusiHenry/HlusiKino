import Foundation

// MARK: - TMDB Media Item

struct MediaItem: Codable, Identifiable, Equatable {
    let id: Int
    let title: String?
    let name: String?
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double?
    let releaseDate: String?
    let firstAirDate: String?
    let overview: String?
    let originalLanguage: String?
    let mediaType: String?
    let genreIDs: [Int]?

    // Filled from detail fetch
    var genres: [Genre]?
    var runtime: Int?
    var homepage: String?
    var imdbID: String?
    var seasons: [Season]?
    var credits: Credits?
    var videos: VideoResponse?

    var displayTitle: String { title ?? name ?? "Unknown" }
    var displayYear: String { String((releaseDate ?? firstAirDate ?? "").prefix(4)) }
    var displayRating: String {
        guard let v = voteAverage else { return "—" }
        return String(format: "%.1f", v)
    }
    var inferredType: MediaType {
        if mediaType == "tv" || firstAirDate != nil || name != nil { return .tv }
        return .movie
    }

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview, homepage, runtime, genres, seasons, credits, videos
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case originalLanguage = "original_language"
        case mediaType = "media_type"
        case genreIDs = "genre_ids"
        case imdbID = "imdb_id"
    }

    enum MediaType: String { case movie, tv }
}

// MARK: - TMDB API Response Wrappers

struct TMDBResponse<T: Codable>: Codable {
    let results: [T]
    let page: Int?
    let totalPages: Int?

    enum CodingKeys: String, CodingKey {
        case results, page
        case totalPages = "total_pages"
    }
}

struct Genre: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
}

struct Season: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let seasonNumber: Int
    let episodeCount: Int?
    let posterPath: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
        case posterPath = "poster_path"
    }
}

struct Episode: Codable, Identifiable, Equatable {
    let id: Int
    let name: String?
    let episodeNumber: Int
    let seasonNumber: Int
    let runtime: Int?
    let airDate: String?
    let stillPath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, runtime
        case episodeNumber = "episode_number"
        case seasonNumber = "season_number"
        case airDate = "air_date"
        case stillPath = "still_path"
    }
}

struct Credits: Codable, Equatable {
    let cast: [CastMember]?
}

struct CastMember: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
    let roles: [Role]?

    var displayCharacter: String { character ?? roles?.first?.character ?? "" }

    struct Role: Codable, Equatable {
        let character: String?
    }

    enum CodingKeys: String, CodingKey {
        case id, name, character, roles
        case profilePath = "profile_path"
    }
}

struct VideoResponse: Codable, Equatable {
    let results: [Video]?
}

struct Video: Codable, Identifiable, Equatable {
    let id: String
    let key: String
    let name: String?
    let site: String?
    let type: String?

    var isYouTubeTrailer: Bool { site == "YouTube" && type == "Trailer" }
    var isYouTube: Bool { site == "YouTube" }
}

// MARK: - TMDB Find Response (IMDb → TMDB)

struct TMDBFindResponse: Codable {
    let movieResults: [MediaItem]?
    let tvResults: [MediaItem]?

    enum CodingKeys: String, CodingKey {
        case movieResults = "movie_results"
        case tvResults = "tv_results"
    }
}

// MARK: - Season Detail

struct SeasonDetail: Codable {
    let episodes: [Episode]?
}
