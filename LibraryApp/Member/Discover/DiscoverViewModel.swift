import SwiftUI
import SwiftData

@Observable
class DiscoverViewModel {
    var query = ""
    
    func filteredBooks(from array: [Book]) -> [Book] {
        guard !query.isEmpty else { return array }
        return array.filter {
            $0.title.localizedCaseInsensitiveContains(query)
            || $0.author.localizedCaseInsensitiveContains(query)
            || $0.genre.localizedCaseInsensitiveContains(query)
        }
    }
}
