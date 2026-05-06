import Foundation

struct BookLookupService {
    enum LookupError: Error, LocalizedError {
        case invalidISBN
        case noResults
        case network(NetworkService.NetworkError)
        case unknown

        var errorDescription: String? {
            switch self {
            case .invalidISBN:
                return "Please scan a valid ISBN or barcode."
            case .noResults:
                return "No book information was found for this ISBN."
            case .network(let error):
                return "Network error: \(error)"
            case .unknown:
                return "Unable to lookup book details right now."
            }
        }
    }

    struct BookMetadata {
        let title: String
        let author: String
        let genre: String
        let coverUrl: String?
        let pdfUrl: String?
    }

    func lookupISBN(_ isbn: String) async throws -> BookMetadata {
        guard let cleanISBN = sanitizeISBN(isbn), !cleanISBN.isEmpty else {
            throw LookupError.invalidISBN
        }

        let query = "isbn:\(cleanISBN)"
        guard let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=\(query)&fields=items(volumeInfo(title,authors,categories,imageLinks/thumbnail,imageLinks/extraLarge,previewLink,infoLink),accessInfo/pdf/acsTokenLink,accessInfo/webReaderLink)") else {
            throw LookupError.invalidISBN
        }

        do {
            let response = try await NetworkService().getJSON(GoogleBooksResponse.self, url: url)
            guard let item = response.items?.first else {
                throw LookupError.noResults
            }

            let info = item.volumeInfo
            let title = info.title ?? ""
            let author = info.authors?.joined(separator: ", ") ?? ""
            let genre = parseGenre(from: info.categories)
            let coverUrl = info.imageLinks?.extraLarge ?? info.imageLinks?.thumbnail
            let pdfUrl = item.accessInfo?.pdf?.acsTokenLink ?? item.accessInfo?.webReaderLink ?? info.previewLink ?? info.infoLink

            return BookMetadata(title: title, author: author, genre: genre, coverUrl: coverUrl, pdfUrl: pdfUrl)
        } catch let error as NetworkService.NetworkError {
            throw LookupError.network(error)
        } catch {
            throw LookupError.unknown
        }
    }

    private func sanitizeISBN(_ isbn: String) -> String? {
        let digits = isbn.filter { $0.isNumber }
        return digits.isEmpty ? nil : digits
    }

    private func parseGenre(from categories: [String]?) -> String {
        guard let categories = categories, !categories.isEmpty else {
            return ""
        }

        let lowercased = categories.map { $0.lowercased() }
        if let match = lowercased.first(where: { $0.contains("fiction") }) {
            return match.capitalized
        }
        if let match = lowercased.first(where: { $0.contains("comic") || $0.contains("graphic") }) {
            return match.capitalized
        }
        return categories.first ?? ""
    }
}

private struct GoogleBooksResponse: Decodable {
    let items: [Volume]?
}

private struct Volume: Decodable {
    let volumeInfo: VolumeInfo
    let accessInfo: AccessInfo?
}

private struct VolumeInfo: Decodable {
    let title: String?
    let authors: [String]?
    let categories: [String]?
    let imageLinks: ImageLinks?
    let previewLink: String?
    let infoLink: String?
}

private struct ImageLinks: Decodable {
    let thumbnail: String?
    let extraLarge: String?
}

private struct AccessInfo: Decodable {
    let pdf: PDFInfo?
    let webReaderLink: String?
}

private struct PDFInfo: Decodable {
    let acsTokenLink: String?
}
