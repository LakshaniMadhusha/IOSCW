import SwiftUI
import SwiftData

struct BookExplorerView: View {
    let title: String
    let books: [Book]
    let user: AppUser?
    
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(title)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(books) { book in
                        NavigationLink(destination: BookDetailView(book: book, user: user)) {
                            BookCoverCard(book: book, width: nil, height: 240)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.pageBg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Explore")
                    .font(.headline.weight(.bold))
            }
        }
    }
}
