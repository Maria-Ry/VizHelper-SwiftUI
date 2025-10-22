import Foundation

enum APIError: Error { case badURL, requestFailed, decodeFailed }

@MainActor
final class APIClient: ObservableObject {
    @Published var baseURL: URL

    init(base: String = "http://127.0.0.1:8000") {
        guard let url = URL(string: base) else { fatalError("Invalid base URL") }
        self.baseURL = url
    }

    func get<T: Decodable>(_ path: String,
                           queries: [URLQueryItem] = []) async throws -> T {
        guard var comps = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else { throw APIError.badURL }

        if !queries.isEmpty { comps.queryItems = queries }
        guard let url = comps.url else { throw APIError.badURL }

        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else { throw APIError.requestFailed }
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw APIError.decodeFailed }
    }

    // Endpoints
    func fetchMetrics(kind: String = "sine", n: Int = 300, noise: Double = 0.05) async throws -> MetricsResponse {
        try await get("/api/metrics", queries: [
            .init(name: "kind", value: kind),
            .init(name: "n", value: String(n)),
            .init(name: "noise", value: String(noise))
        ])
    }

    func fetchRocPr() async throws -> RocPrResponse {
        try await get("/api/metrics/roc_pr")
    }
}
