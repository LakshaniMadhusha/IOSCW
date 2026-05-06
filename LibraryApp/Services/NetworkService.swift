import Foundation
import Combine

struct NetworkService {
    enum NetworkError: Error {
        case invalidURL
        case badStatus(Int)
        case decodingFailed
    }

    func getJSON<T: Decodable>(_ type: T.Type, url: URL) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.badStatus(-1) }
        guard (200..<300).contains(http.statusCode) else { throw NetworkError.badStatus(http.statusCode) }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }

    func getDataPublisher(url: URL) -> AnyPublisher<Data, URLError> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .eraseToAnyPublisher()
    }
}

