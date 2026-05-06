import SwiftUI
import SwiftData

struct DiscoverView: View {
    let user: AppUser?
    @Query(sort: \Book.createdAt, order: .reverse) private var books: [Book]
    @State private var vm = DiscoverViewModel()
    @StateObject private var speechRecognizer = SpeechRecognizer()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if !vm.query.isEmpty {
                    // Search Results
                    VStack(spacing: 16) {
                        let filtered = vm.filteredBooks(from: books)
                        if filtered.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.textSecondary.opacity(0.5))
                                Text("No books found.")
                                    .font(.headline)
                                    .foregroundColor(.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            ForEach(filtered) { book in
                                BookRow(book: book)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 16)
                } else {
                    // Categorized Content
                    LazyVStack(spacing: 36) {
                        
                        GenreCarousel(
                            title: "Coming Soon", 
                            subtitle: "Most anticipated new releases", 
                            books: Array(books.prefix(8)),
                            isFeatured: true,
                            user: user
                        )
                        
                        GenreCarousel(
                            title: "Fiction", 
                            books: books.filter { $0.genre.localizedCaseInsensitiveContains("fiction") },
                            user: user
                        )

                        GenreCarousel(
                            title: "Novels", 
                            books: books.filter { $0.genre.localizedCaseInsensitiveContains("novel") },
                            user: user
                        )

                        GenreCarousel(
                            title: "Literature", 
                            books: books.filter { $0.genre.localizedCaseInsensitiveContains("literature") },
                            user: user
                        )

                        GenreCarousel(
                            title: "Comics", 
                            books: books.filter { $0.genre.localizedCaseInsensitiveContains("comic") },
                            user: user
                        )

                        GenreCarousel(
                            title: "Explore More", 
                            books: books.filter { 
                                !$0.genre.localizedCaseInsensitiveContains("fiction") && 
                                !$0.genre.localizedCaseInsensitiveContains("novel") && 
                                !$0.genre.localizedCaseInsensitiveContains("literature") && 
                                !$0.genre.localizedCaseInsensitiveContains("comic") 
                            },
                            user: user
                        )
                    }
                    .padding(.vertical, 24)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.pageBg.ignoresSafeArea())
            .navigationTitle("Discover")
            .searchable(text: $vm.query, prompt: "Search books, authors, genres")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if speechRecognizer.isRecording {
                            speechRecognizer.stopTranscribing()
                        } else {
                            speechRecognizer.startTranscribing()
                        }
                    }) {
                        Image(systemName: speechRecognizer.isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(speechRecognizer.isRecording ? .white : .accent, speechRecognizer.isRecording ? .red : .accent.opacity(0.2))
                            .font(.system(size: 28))
                    }
                }
            }
            .onChange(of: speechRecognizer.transcript) { _, newValue in
                vm.query = newValue
            }
        }
    }
}

struct GenreCarousel: View {
    let title: String
    var subtitle: String? = nil
    let books: [Book]
    var isFeatured: Bool = false
    let user: AppUser?
    
    var body: some View {
        if !books.isEmpty {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let subtitle = subtitle {
                            Text(subtitle.uppercased())
                                .font(.caption.weight(.bold))
                                .foregroundColor(.textSecondary)
                        }
                        Text(title)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.textPrimary)
                    }
                    Spacer()
                    
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Text("See All")
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundColor(.accent)
                    }
                }
                .padding(.horizontal, 20)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(books) { book in
                            NavigationLink(destination: BookDetailView(book: book, user: user)) {
                                if isFeatured {
                                    FeaturedBookCard(book: book)
                                } else {
                                    BookCoverCard(book: book, width: 130, height: 195)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

struct FeaturedBookCard: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                if let urlString = book.coverUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.purple.opacity(0.3))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 260, height: 160)
                                .clipped()
                        case .failure(_):
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(LinearGradient(colors: [.purple.opacity(0.8), .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        @unknown default:
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.purple)
                        }
                    }
                    .frame(width: 260, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [.purple.opacity(0.8), .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 260, height: 160)
                }
                
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .center, endPoint: .bottom))
                    .frame(width: 260, height: 160)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.genre.uppercased())
                        .font(.caption2.weight(.heavy))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(book.title)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }
                .padding(16)
            }
        }
        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 6)
    }
}
