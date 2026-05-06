import SwiftUI

struct BookRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.surfaceBg)
                .frame(width: 44, height: 58)
                .overlay(
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(.textPrimary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                Text("\(book.author) • \(book.genre)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            StatusPill(status: book.status)
        }
        .padding(.vertical, 6)
    }
}

