import SwiftUI
import SwiftData

struct BookManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.createdAt, order: .reverse) private var books: [Book]

    @State private var showingAdd = false
    @State private var selectedBookToEdit: Book?
    @State private var selectedBookToDelete: Book?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 36) {
                    
                    if books.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "books.vertical")
                                .font(.system(size: 48))
                                .foregroundColor(.textSecondary)
                            Text("No books in library.")
                                .font(.headline)
                            Text("Tap the + icon to add new inventory.")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 100)
                    } else {
                        // Dynamically extract categories
                        let genres = Array(Set(books.map { $0.genre.capitalized })).sorted()
                        
                        // Show "Newest Additions" unconditionally
                        LibrarianCarousel(title: "Newest Additions", books: Array(books.prefix(10)), onEdit: { selectedBookToEdit = $0 }, onDelete: { selectedBookToDelete = $0 })
                        
                        // Categorize one by one dynamically
                        ForEach(genres, id: \.self) { genre in
                            let categorizedBooks = books.filter { $0.genre.capitalized == genre }
                            if !categorizedBooks.isEmpty {
                                LibrarianCarousel(title: genre, books: categorizedBooks, onEdit: { selectedBookToEdit = $0 }, onDelete: { selectedBookToDelete = $0 })
                            }
                        }
                    }
                }
                .padding(.vertical, 24)
                .padding(.bottom, 20)
            }
            .background(Color.pageBg.ignoresSafeArea())
            .navigationTitle("Catalog")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAdd = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.purple)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddBookView()
            }
            .sheet(item: $selectedBookToEdit) { book in
                AddBookView(bookToEdit: book)
            }
            .confirmationDialog("Delete Book?", isPresented: .constant(selectedBookToDelete != nil), presenting: selectedBookToDelete) { book in
                Button("Delete \"\(book.title)\"", role: .destructive) {
                    delete(book)
                }
                Button("Cancel", role: .cancel) {
                    selectedBookToDelete = nil
                }
            } message: { book in
                Text("This will permanently remove the book from the database.")
            }
        }
    }

    private func delete(_ book: Book) {
        modelContext.delete(book)
        try? modelContext.save()
        selectedBookToDelete = nil
    }
}

struct LibrarianCarousel: View {
    let title: String
    let books: [Book]
    let onEdit: (Book) -> Void
    let onDelete: (Book) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3.weight(.bold))
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(books) { book in
                        Menu {
                            Button(action: { onEdit(book) }) {
                                Label("Edit Details", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: { onDelete(book) }) {
                                Label("Delete Book", systemImage: "trash")
                            }
                        } label: {
                            BookCoverCard(book: book, width: 130, height: 195)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
