import SwiftUI

struct BookCoverCard: View {
    let book: Book
    let width: CGFloat?
    let height: CGFloat?
    
    init(book: Book, width: CGFloat? = 120, height: CGFloat? = 180) {
        self.book = book
        self.width = width
        self.height = height
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.cardBg)
                    .frame(width: width, height: height)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                if let urlString = book.coverUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: width, height: height)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        case .failure(_):
                            FallbackCover(book: book)
                        @unknown default:
                            FallbackCover(book: book)
                        }
                    }
                } else {
                    FallbackCover(book: book)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                
                Text(book.author)
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: width, alignment: .leading)
        }
    }
}

fileprivate struct FallbackCover: View {
    let book: Book
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 32))
                .foregroundColor(.purple)
            
            Text(book.title)
                .font(.caption)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 8)
        }
    }
}
